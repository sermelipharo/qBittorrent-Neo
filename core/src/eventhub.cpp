/*
 * qBittorrent Neo — forwards core signals to the app as JSON events.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "eventhub.h"

#include <QJsonDocument>
#include <QTimer>

#include "base/bittorrent/addtorrenterror.h"
#include "base/bittorrent/infohash.h"
#include "base/bittorrent/session.h"
#include "base/bittorrent/torrent.h"
#include "base/global.h"
#include "base/logger.h"
#include "base/preferences.h"
#include "base/rss/rss_feed.h"
#include "base/rss/rss_folder.h"
#include "base/rss/rss_session.h"
#include "addmanager.h"
#include "jsonutil.h"

namespace
{
    QJsonObject torrentValues(const BitTorrent::Torrent *torrent)
    {
        return {{u"hash"_s, torrent->id().toString()}, {u"name"_s, torrent->name()}};
    }
}

namespace Neo
{
    QString logLevelName(const Log::MsgType type)
    {
        switch (type)
        {
        case Log::INFO:
            return u"info"_s;
        case Log::WARNING:
            return u"warning"_s;
        case Log::CRITICAL:
            return u"critical"_s;
        default:
            return u"normal"_s;
        }
    }

    QJsonObject logMessageJson(const Log::Msg &msg)
    {
        return {
            {u"id"_s, msg.id},
            {u"timestamp"_s, msg.timestamp * 1000},
            {u"level"_s, logLevelName(msg.type)},
            {u"message"_s, msg.message}
        };
    }

    EventHub::EventHub(const qbtn_event_fn fn, void *context, QObject *parent)
        : QObject(parent)
        , m_fn {fn}
        , m_context {context}
        , m_rssTimer {new QTimer(this)}
    {
        m_rssTimer->setSingleShot(true);
        m_rssTimer->setInterval(300);
        connect(m_rssTimer, &QTimer::timeout, this, [this] { post(u"rssUpdated"_s); });
    }

    void EventHub::post(const QString &name, const QJsonObject &values) const
    {
        if (!m_fn)
            return;
        const QByteArray json = QJsonDocument(swiftCase(name, values)).toJson(QJsonDocument::Compact);
        m_fn(m_context, json.constData(), static_cast<size_t>(json.size()));
    }

    void EventHub::scheduleRssUpdate()
    {
        if (!m_rssTimer->isActive())
            m_rssTimer->start();
    }

    void EventHub::attachLogger()
    {
        // Messages are logged from any thread; forward them directly.
        connect(Logger::instance(), &Logger::newLogMessage, this, [this](const Log::Msg &msg)
        {
            post(u"log"_s, {{u"message"_s, logMessageJson(msg)}});
        }, Qt::DirectConnection);
    }

    void EventHub::attachSession()
    {
        auto *session = BitTorrent::Session::instance();
        connect(session, &BitTorrent::Session::torrentAdded, this, [this](const BitTorrent::Torrent *torrent)
        {
            post(u"torrentAdded"_s, torrentValues(torrent));
        });
        connect(session, &BitTorrent::Session::torrentFinished, this, [this](const BitTorrent::Torrent *torrent)
        {
            post(u"torrentFinished"_s, torrentValues(torrent));
        });
        connect(session, &BitTorrent::Session::torrentMetadataReceived, this, [this](const BitTorrent::Torrent *torrent)
        {
            post(u"torrentMetadataReceived"_s, torrentValues(torrent));
        });
        connect(session, &BitTorrent::Session::torrentAboutToBeRemoved, this, [this](const BitTorrent::Torrent *torrent)
        {
            post(u"torrentRemoved"_s, torrentValues(torrent));
        });
        connect(session, &BitTorrent::Session::fullDiskError, this, [this](const BitTorrent::Torrent *torrent, const QString &msg)
        {
            QJsonObject values = torrentValues(torrent);
            values[u"message"_s] = msg;
            post(u"fullDiskError"_s, values);
        });
        connect(session, &BitTorrent::Session::allTorrentsFinished, this, [this]
        {
            post(u"allTorrentsFinished"_s);
        }, Qt::QueuedConnection);

        connect(Preferences::instance(), &Preferences::changed, this, [this]
        {
            post(u"preferencesChanged"_s);
        });
    }

    void EventHub::attachComponents(NeoAddTorrentManager *addManager)
    {
        connect(addManager, &AddTorrentManager::addTorrentFailed, this
                , [this](const QString &source, const BitTorrent::AddTorrentError &reason)
        {
            post(u"addTorrentFailed"_s, {{u"source"_s, source}, {u"reason"_s, reason.message}});
        });
        connect(addManager, &NeoAddTorrentManager::duplicateTorrent, this
                , [this](const QString &hash, const QString &name, const bool merged)
        {
            post(u"duplicateTorrent"_s, {{u"hash"_s, hash}, {u"name"_s, name}, {u"mergedTrackers"_s, merged}});
        });

        auto *rss = RSS::Session::instance();
        const auto schedule = [this] { scheduleRssUpdate(); };
        connect(rss, &RSS::Session::itemAdded, this, schedule);
        connect(rss, &RSS::Session::itemPathChanged, this, schedule);
        connect(rss, &RSS::Session::itemAboutToBeRemoved, this, schedule);
        connect(rss, &RSS::Session::feedIconLoaded, this, schedule);
        connect(rss, &RSS::Session::feedStateChanged, this, schedule);
        connect(rss, &RSS::Session::feedURLChanged, this, schedule);
        connect(rss->rootFolder(), &RSS::Item::unreadCountChanged, this, schedule);
        connect(rss->rootFolder(), &RSS::Item::newArticle, this, schedule);
        connect(rss->rootFolder(), &RSS::Item::articleRead, this, schedule);
        connect(rss->rootFolder(), &RSS::Item::articleAboutToBeRemoved, this, schedule);
    }
}
