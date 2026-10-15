/*
 * qBittorrent Neo — adding torrents on behalf of the app.
 *
 * Duplicate handling follows qBittorrent's AddTorrentManager:
 * Copyright (C) 2023-2024 Vladimir Golovnev <glassez@yandex.ru>
 * Modifications Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "addmanager.h"

#include <QUrl>

#include "base/bittorrent/session.h"
#include "base/bittorrent/torrent.h"
#include "base/global.h"
#include "base/logger.h"
#include "base/torrentfileguard.h"

namespace
{
    const qsizetype MAX_FETCHED_METADATA = 16;

    bool isHttpUrl(const QString &source)
    {
        return source.startsWith(u"http://", Qt::CaseInsensitive)
            || source.startsWith(u"https://", Qt::CaseInsensitive);
    }
}

namespace Neo
{
    NeoAddTorrentManager::NeoAddTorrentManager(IApplication *app, BitTorrent::Session *btSession, QObject *parent)
        : AddTorrentManager(app, btSession, parent)
    {
        connect(this, &AddTorrentManager::torrentAdded, this, &NeoAddTorrentManager::onTorrentAdded);
        connect(this, &AddTorrentManager::addTorrentFailed, this, &NeoAddTorrentManager::onAddTorrentFailed);
    }

    void NeoAddTorrentManager::add(const QString &source, const BitTorrent::AddTorrentParams &params, const Reply &reply)
    {
        if (source.trimmed().isEmpty())
            throwInvalid(tr("No torrent source given"));

        if (isHttpUrl(source))
        {
            // Downloaded by AddTorrentManager; the reply follows its signals.
            m_pendingUrls.insert(source, reply);
            if (!addTorrent(source, params))
            {
                m_pendingUrls.remove(source, reply);
                throwOther(tr("Failed to add torrent. Source: \"%1\"").arg(source));
            }
            return;
        }

        if (const auto parseResult = BitTorrent::TorrentDescriptor::parse(source))
        {
            reply.ok(addDescriptor(source, parseResult.value(), params, {}));
            return;
        }
        else if (source.startsWith(u"magnet:", Qt::CaseInsensitive))
        {
            handleAddTorrentFailed(source, parseResult.error());
            throwInvalid(parseResult.error());
        }

        const Path path {source.startsWith(u"file://", Qt::CaseInsensitive)
                ? QUrl::fromEncoded(source.toUtf8()).toLocalFile() : source};
        auto guard = std::make_shared<TorrentFileGuard>(path);
        const auto loadResult = BitTorrent::TorrentDescriptor::loadFromFile(path);
        if (!loadResult)
        {
            handleAddTorrentFailed(source, loadResult.error());
            throwInvalid(loadResult.error());
        }
        reply.ok(addDescriptor(source, loadResult.value(), params, guard));
    }

    void NeoAddTorrentManager::addData(const QByteArray &data, const BitTorrent::AddTorrentParams &params, const Reply &reply)
    {
        const auto loadResult = BitTorrent::TorrentDescriptor::load(data);
        if (!loadResult)
        {
            handleAddTorrentFailed(tr("Torrent data"), loadResult.error());
            throwInvalid(loadResult.error());
        }
        reply.ok(addDescriptor(loadResult.value().name(), loadResult.value(), params, {}));
    }

    QString NeoAddTorrentManager::addDescriptor(const QString &source, BitTorrent::TorrentDescriptor descriptor
            , const BitTorrent::AddTorrentParams &params, std::shared_ptr<TorrentFileGuard> guard)
    {
        const BitTorrent::InfoHash infoHash = descriptor.infoHash();
        const BitTorrent::TorrentID id = infoHash.toTorrentID();

        if (!descriptor.info())
        {
            if (const auto cached = fetchedMetadata(id); cached && cached->info())
                descriptor.setTorrentInfo(*cached->info());
        }

        if (BitTorrent::Torrent *existing = btSession()->findTorrent(infoHash))
        {
            // Same as AddTorrentManager::handleDuplicateTorrent(), but the
            // result is reported to the caller.
            const bool hasMetadata = descriptor.info().has_value();
            if (hasMetadata)
                existing->setMetadata(*descriptor.info());

            const bool isPrivate = existing->isPrivate() || (hasMetadata && descriptor.info()->isPrivate());
            QString message;
            bool merged = false;
            if (!btSession()->isMergeTrackersEnabled())
            {
                message = tr("Merging of trackers is disabled");
            }
            else if (isPrivate)
            {
                message = tr("Trackers cannot be merged because it is a private torrent");
            }
            else
            {
                existing->addTrackers(descriptor.trackers());
                existing->addUrlSeeds(descriptor.urlSeeds());
                message = tr("Trackers are merged from new source");
                merged = true;
            }

            LogMsg(tr("Detected an attempt to add a duplicate torrent. Source: %1. Existing torrent: \"%2\". Torrent infohash: %3. Result: %4")
                    .arg(source, existing->name(), existing->infoHash().toString(), message));
            emit duplicateTorrent(existing->id().toString(), existing->name(), merged);
            throwConflict(tr("This torrent is already in the transfer list. %1").arg(message));
        }

        if (guard)
            setTorrentFileGuard(source, guard);
        if (!addTorrentToSession(source, descriptor, params))
        {
            if (guard)
                releaseTorrentFileGuard(source);
            throwOther(tr("Failed to add torrent. Source: \"%1\"").arg(source));
        }
        return id.toString();
    }

    void NeoAddTorrentManager::onTorrentAdded(const QString &source, BitTorrent::Torrent *torrent)
    {
        const QList<Reply> replies = m_pendingUrls.values(source);
        m_pendingUrls.remove(source);
        for (const Reply &reply : replies)
            reply.ok(torrent->id().toString());
    }

    void NeoAddTorrentManager::onAddTorrentFailed(const QString &source, const BitTorrent::AddTorrentError &reason)
    {
        const QList<Reply> replies = m_pendingUrls.values(source);
        m_pendingUrls.remove(source);
        const ErrorKind kind = (reason.kind == BitTorrent::AddTorrentError::DuplicateTorrent)
                ? ErrorKind::Conflict : ErrorKind::Network;
        for (const Reply &reply : replies)
            reply.fail(kind, reason.message);
    }

    void NeoAddTorrentManager::rememberMetadata(const BitTorrent::TorrentDescriptor &descriptor)
    {
        const BitTorrent::TorrentID id = descriptor.infoHash().toTorrentID();
        m_fetchedMetadata.removeIf([&id](const BitTorrent::TorrentDescriptor &item) { return item.infoHash().toTorrentID() == id; });
        m_fetchedMetadata.append(descriptor);
        while (m_fetchedMetadata.size() > MAX_FETCHED_METADATA)
            m_fetchedMetadata.removeFirst();
    }

    std::optional<BitTorrent::TorrentDescriptor> NeoAddTorrentManager::fetchedMetadata(const BitTorrent::TorrentID &id) const
    {
        for (const BitTorrent::TorrentDescriptor &descriptor : m_fetchedMetadata)
        {
            const BitTorrent::InfoHash hash = descriptor.infoHash();
            if ((hash.toTorrentID() == id) || (hash.isHybrid() && (BitTorrent::TorrentID::fromSHA1Hash(hash.v1()) == id)))
                return descriptor;
        }
        return std::nullopt;
    }
}
