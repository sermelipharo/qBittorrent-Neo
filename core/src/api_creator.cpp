/*
 * qBittorrent Neo — torrent creator (qBittorrent's TorrentCreationManager,
 * the same task queue the WebAPI's torrent creator uses).
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <QHash>
#include <QJsonArray>
#include <QPointer>
#include <QTimer>
#include <QThreadPool>

#include "base/bittorrent/infohash.h"
#include "base/bittorrent/torrentcreationmanager.h"
#include "base/bittorrent/torrentcreationtask.h"
#include "base/bittorrent/torrentcreator.h"
#include "base/bittorrent/torrentdescriptor.h"
#include "base/global.h"
#include "base/utils/io.h"
#include "corehost.h"
#include "eventhub.h"
#include "jsonutil.h"
#include "neoapplication.h"
#include "registry.h"

using namespace Neo;

namespace
{
    QString formatName(const BitTorrent::TorrentFormat format)
    {
        switch (format)
        {
        case BitTorrent::TorrentFormat::V1:
            return u"v1"_s;
        case BitTorrent::TorrentFormat::V2:
            return u"v2"_s;
        default:
            return u"hybrid"_s;
        }
    }

    BitTorrent::TorrentFormat parseFormat(const QString &name)
    {
        if (name == u"v1")
            return BitTorrent::TorrentFormat::V1;
        if (name == u"v2")
            return BitTorrent::TorrentFormat::V2;
        return BitTorrent::TorrentFormat::Hybrid;
    }

    // Owns the creation manager and reports task changes to the app (the
    // tasks have no signals, so running tasks are polled once a second).
    class CreatorTasks final : public QObject
    {
    public:
        explicit CreatorTasks(QObject *parent)
            : QObject(parent)
            , m_manager {new BitTorrent::TorrentCreationManager(CoreHost::instance()->app(), this)}
            , m_timer {new QTimer(this)}
        {
            m_timer->setInterval(1000);
            connect(m_timer, &QTimer::timeout, this, &CreatorTasks::poll);
        }

        static CreatorTasks *instance()
        {
            static QPointer<CreatorTasks> tasks;
            if (!tasks)
                tasks = new CreatorTasks(CoreHost::instance());
            return tasks;
        }

        BitTorrent::TorrentCreationManager *manager() const { return m_manager; }

        std::shared_ptr<BitTorrent::TorrentCreationTask> task(const QString &id) const
        {
            auto task = m_manager->getTask(id);
            if (!task)
                throwNotFound(tr("No torrent creation task with id %1").arg(id));
            return task;
        }

        void watch()
        {
            if (!m_timer->isActive())
                m_timer->start();
        }

        QJsonObject taskJson(const BitTorrent::TorrentCreationTask &task)
        {
            QString status = u"queued"_s;
            if (task.isFailed())
                status = u"failed"_s;
            else if (task.isFinished())
                status = u"finished"_s;
            else if (task.isRunning())
                status = u"running"_s;

            QString torrentFile = task.params().torrentFilePath.toString();
            int pieceSize = task.params().pieceSize;
            QString infoHash;
            if (task.isFinished() && !task.isFailed())
            {
                torrentFile = task.result().torrentFilePath.toString();
                pieceSize = task.result().pieceSize;
                infoHash = m_infoHashes.value(task.id());
                if (infoHash.isEmpty())
                {
                    if (const auto descriptor = BitTorrent::TorrentDescriptor::loadFromFile(task.result().torrentFilePath))
                        infoHash = descriptor.value().infoHash().toTorrentID().toString();
                    m_infoHashes.insert(task.id(), infoHash);
                }
            }

            return {
                {u"id"_s, task.id()},
                {u"sourcePath"_s, task.params().sourcePath.toString()},
                {u"status"_s, status},
                {u"progress"_s, static_cast<double>(task.progress())},
                {u"errorMessage"_s, task.errorMsg()},
                {u"torrentFilePath"_s, torrentFile},
                {u"pieceSize"_s, pieceSize},
                {u"format"_s, formatName(task.params().torrentFormat)},
                {u"timeAdded"_s, toSecs(task.timeAdded(), 0)},
                {u"timeStarted"_s, toSecs(task.timeStarted(), 0)},
                {u"timeFinished"_s, toSecs(task.timeFinished(), 0)},
                {u"infoHash"_s, infoHash}
            };
        }

        void forget(const QString &id)
        {
            m_states.remove(id);
            m_infoHashes.remove(id);
        }

    private:
        void poll()
        {
            bool pending = false;
            for (const auto &task : asConst(m_manager->tasks()))
            {
                const auto state = std::make_pair(static_cast<int>(task->state()) * 1000 + task->isFailed(), task->progress());
                if (m_states.value(task->id()) != state)
                {
                    m_states.insert(task->id(), state);
                    CoreHost::instance()->events()->post(u"creatorTaskUpdated"_s, {{u"id"_s, task->id()}});
                }
                pending |= !task->isFinished();
            }
            if (!pending)
                m_timer->stop();
        }

        BitTorrent::TorrentCreationManager *m_manager = nullptr;
        QTimer *m_timer = nullptr;
        QHash<QString, std::pair<int, int>> m_states;
        QHash<QString, QString> m_infoHashes;
    };

    // libtorrent's automatic piece size (create_torrent with piece_size 0).
    qint64 autoPieceSize(const qint64 totalSize)
    {
        static const qint64 SIZE_TABLE[] = {
            2'684'355, 10'737'418, 42'949'673, 171'798'692, 687'194'767,
            2'748'779'069, 10'995'116'278, 43'980'465'111, 175'921'860'444, 703'687'441'777
        };
        int i = 0;
        for (const qint64 limit : SIZE_TABLE)
        {
            if (limit >= totalSize)
                break;
            ++i;
        }
        return qint64 {16 * 1024} << i;
    }
}

void Neo::registerCreatorApi(Registry &registry)
{
    registry.add(u"creatorAddTask"_s, [](const QJsonObject &args)
    {
        const QJsonObject json = argObject(args, u"params"_s);
        BitTorrent::TorrentCreatorParams params;
        params.isPrivate = argBool(json, u"private"_s);
        params.torrentFormat = parseFormat(argString(json, u"format"_s));
        params.pieceSize = static_cast<int>(argInt(json, u"pieceSize"_s));
        params.sourcePath = Path(argString(json, u"sourcePath"_s));
        params.torrentFilePath = Path(argString(json, u"torrentFilePath"_s));
        params.comment = argString(json, u"comment"_s);
        params.source = argString(json, u"source"_s);
        params.trackers = argStringList(json, u"trackers"_s);
        params.urlSeeds = argStringList(json, u"urlSeeds"_s);
        if (params.sourcePath.isEmpty())
            throwInvalid(QCoreApplication::translate("TorrentCreatorController", "Source path is required"));

        auto *tasks = CreatorTasks::instance();
        const auto task = tasks->manager()->createTask(params, argBool(json, u"startSeeding"_s, true));
        if (!task)
            throwConflict(QCoreApplication::translate("TorrentCreatorController", "Too many active tasks"));
        tasks->watch();
        return QJsonValue(task->id());
    });

    registry.add(u"creatorTasks"_s, [](const QJsonObject &)
    {
        QJsonArray result;
        auto *tasks = CreatorTasks::instance();
        for (const auto &task : asConst(tasks->manager()->tasks()))
            result.append(tasks->taskJson(*task));
        return result;
    });

    registry.add(u"creatorTask"_s, [](const QJsonObject &args)
    {
        auto *tasks = CreatorTasks::instance();
        return tasks->taskJson(*tasks->task(argString(args, u"id"_s)));
    });

    registry.add(u"creatorTorrentFile"_s, [](const QJsonObject &args)
    {
        const auto task = CreatorTasks::instance()->task(argString(args, u"id"_s));
        if (!task->isFinished() || task->isFailed())
            throwConflict(QCoreApplication::translate("TorrentCreatorController", "Torrent creation is still unfinished."));
        const auto data = Utils::IO::readFile(task->result().torrentFilePath, -1);
        if (!data)
            throwIo(data.error().message);
        return QJsonValue(QString::fromLatin1(data.value().toBase64()));
    });

    registry.add(u"creatorDeleteTask"_s, [](const QJsonObject &args)
    {
        const QString id = argString(args, u"id"_s);
        auto *tasks = CreatorTasks::instance();
        if (!tasks->manager()->deleteTask(id))
            throwNotFound(QCoreApplication::translate("TorrentCreatorController", "No such task"));
        tasks->forget(id);
        return QJsonValue();
    });

    registry.add(u"creatorAutoPieceSize"_s, [](const QJsonObject &args)
    {
        return QJsonValue(autoPieceSize(argInt(args, u"totalSize"_s)));
    });

    // Walks the source on a worker thread ("Calculate number of pieces").
    registry.addAsync(u"creatorCalculatePieces"_s, [](const QJsonObject &args, const Reply &reply)
    {
        const Path source {argString(args, u"sourcePath"_s)};
        const int pieceSize = static_cast<int>(argInt(args, u"pieceSize"_s));
        const BitTorrent::TorrentFormat format = parseFormat(argString(args, u"format"_s));
        // Completing a reply is thread-safe (it only calls the C callback).
        QThreadPool::globalInstance()->start([source, pieceSize, format, reply]
        {
            reply.ok(BitTorrent::TorrentCreator::calculateTotalPieces(source, pieceSize, format));
        });
    });
}
