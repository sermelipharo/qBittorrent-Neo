/*
 * qBittorrent Neo — transfer-list data for the app (record-level diffs).
 *
 * Field semantics follow qBittorrent's WebAPI serializer
 * (src/webui/api/serialize/serialize_torrent.cpp) and SyncController.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "maindata.h"

#include <QDateTime>
#include <QJsonArray>

#include "base/bittorrent/cachestatus.h"
#include "base/bittorrent/categoryoptions.h"
#include "base/bittorrent/infohash.h"
#include "base/bittorrent/session.h"
#include "base/bittorrent/sessionstatus.h"
#include "base/bittorrent/trackerentrystatus.h"
#include "base/global.h"
#include "base/tagset.h"
#include "jsonutil.h"

namespace Neo
{
    QString shareLimitActionName(const BitTorrent::ShareLimitAction action)
    {
        switch (action)
        {
        case BitTorrent::ShareLimitAction::Stop:
            return u"stop"_s;
        case BitTorrent::ShareLimitAction::Remove:
            return u"remove"_s;
        case BitTorrent::ShareLimitAction::RemoveWithContent:
            return u"removeWithContent"_s;
        case BitTorrent::ShareLimitAction::EnableSuperSeeding:
            return u"enableSuperSeeding"_s;
        default:
            return u"default"_s;
        }
    }

    BitTorrent::ShareLimitAction parseShareLimitAction(const QString &name)
    {
        if (name == u"stop")
            return BitTorrent::ShareLimitAction::Stop;
        if (name == u"remove")
            return BitTorrent::ShareLimitAction::Remove;
        if (name == u"removeWithContent")
            return BitTorrent::ShareLimitAction::RemoveWithContent;
        if (name == u"enableSuperSeeding")
            return BitTorrent::ShareLimitAction::EnableSuperSeeding;
        return BitTorrent::ShareLimitAction::Default;
    }

    QString torrentStateName(const BitTorrent::TorrentState state)
    {
        using BitTorrent::TorrentState;
        switch (state)
        {
        case TorrentState::ForcedDownloading: return u"forcedDownloading"_s;
        case TorrentState::Downloading: return u"downloading"_s;
        case TorrentState::ForcedDownloadingMetadata: return u"forcedDownloadingMetadata"_s;
        case TorrentState::DownloadingMetadata: return u"downloadingMetadata"_s;
        case TorrentState::StalledDownloading: return u"stalledDownloading"_s;
        case TorrentState::ForcedUploading: return u"forcedUploading"_s;
        case TorrentState::Uploading: return u"uploading"_s;
        case TorrentState::StalledUploading: return u"stalledUploading"_s;
        case TorrentState::CheckingResumeData: return u"checkingResumeData"_s;
        case TorrentState::QueuedDownloading: return u"queuedDownloading"_s;
        case TorrentState::QueuedUploading: return u"queuedUploading"_s;
        case TorrentState::CheckingUploading: return u"checkingUploading"_s;
        case TorrentState::CheckingDownloading: return u"checkingDownloading"_s;
        case TorrentState::StoppedDownloading: return u"stoppedDownloading"_s;
        case TorrentState::StoppedUploading: return u"stoppedUploading"_s;
        case TorrentState::Moving: return u"moving"_s;
        case TorrentState::MissingFiles: return u"missingFiles"_s;
        case TorrentState::Error: return u"error"_s;
        default: return u"unknown"_s;
        }
    }

    QString stopConditionName(const BitTorrent::Torrent::StopCondition condition)
    {
        switch (condition)
        {
        case BitTorrent::Torrent::StopCondition::MetadataReceived:
            return u"metadataReceived"_s;
        case BitTorrent::Torrent::StopCondition::FilesChecked:
            return u"filesChecked"_s;
        default:
            return u"none"_s;
        }
    }

    BitTorrent::Torrent::StopCondition parseStopCondition(const QString &name)
    {
        if (name == u"metadataReceived")
            return BitTorrent::Torrent::StopCondition::MetadataReceived;
        if (name == u"filesChecked")
            return BitTorrent::Torrent::StopCondition::FilesChecked;
        return BitTorrent::Torrent::StopCondition::None;
    }

    QJsonObject torrentInfoJson(const BitTorrent::Torrent &torrent)
    {
        const auto adjustQueuePosition = [](const int position) -> int
        {
            return (position < 0) ? 0 : (position + 1);
        };
        const auto adjustRatio = [](const qreal ratio) -> qreal
        {
            return (ratio >= BitTorrent::Torrent::MAX_RATIO) ? -1 : ratio;
        };
        const qlonglong timeSinceActivity = torrent.timeSinceActivity();
        const qint64 lastActivity = (timeSinceActivity < 0)
            ? toSecs(torrent.addedTime())
            : (QDateTime::currentSecsSinceEpoch() - timeSinceActivity);

        QJsonArray tags;
        for (const Tag &tag : asConst(torrent.tags()))
            tags.append(tag.toString());

        const BitTorrent::InfoHash infoHash = torrent.infoHash();
        const BitTorrent::TorrentAnnounceStatus announceStatus = torrent.announceStatus();

        return {
            {u"hash"_s, torrent.id().toString()},
            {u"infohashV1"_s, infoHash.v1().toString()},
            {u"infohashV2"_s, infoHash.v2().toString()},
            {u"name"_s, torrent.name()},
            {u"hasMetadata"_s, torrent.hasMetadata()},
            {u"private"_s, torrent.hasMetadata() && torrent.isPrivate()},
            {u"createdBy"_s, torrent.creator()},
            {u"creationDate"_s, toSecs(torrent.creationDate())},
            {u"totalSize"_s, torrent.totalSize()},
            {u"piecesNum"_s, torrent.piecesCount()},
            {u"pieceSize"_s, torrent.pieceLength()},
            {u"magnetUri"_s, torrent.createMagnetURI()},
            {u"size"_s, torrent.wantedSize()},
            {u"progress"_s, torrent.progress()},
            {u"totalWasted"_s, torrent.wastedSize()},
            {u"piecesHave"_s, torrent.piecesHave()},
            {u"dlSpeed"_s, torrent.downloadPayloadRate()},
            {u"upSpeed"_s, torrent.uploadPayloadRate()},
            {u"queuePosition"_s, adjustQueuePosition(torrent.queuePosition())},
            {u"numSeeds"_s, torrent.seedsCount()},
            {u"numComplete"_s, torrent.totalSeedsCount()},
            {u"numLeechs"_s, torrent.leechsCount()},
            {u"numIncomplete"_s, torrent.totalLeechersCount()},
            {u"state"_s, torrentStateName(torrent.state())},
            {u"eta"_s, torrent.eta()},
            {u"seqDl"_s, torrent.isSequentialDownload()},
            {u"fLPiecePrio"_s, torrent.hasFirstLastPiecePriority()},
            {u"category"_s, torrent.category()},
            {u"tags"_s, tags},
            {u"superSeeding"_s, torrent.superSeeding()},
            {u"forceStart"_s, torrent.isForced()},
            {u"savePath"_s, torrent.savePath().toString()},
            {u"downloadPath"_s, torrent.downloadPath().toString()},
            {u"contentPath"_s, torrent.contentPath().toString()},
            {u"rootPath"_s, torrent.rootPath().toString()},
            {u"addedOn"_s, toSecs(torrent.addedTime())},
            {u"completionOn"_s, toSecs(torrent.completedTime())},
            {u"tracker"_s, torrent.currentTracker()},
            {u"trackersCount"_s, torrent.trackers().size()},
            {u"dlLimit"_s, torrent.downloadLimit()},
            {u"upLimit"_s, torrent.uploadLimit()},
            {u"downloaded"_s, torrent.totalDownload()},
            {u"uploaded"_s, torrent.totalUpload()},
            {u"downloadedSession"_s, torrent.totalPayloadDownload()},
            {u"uploadedSession"_s, torrent.totalPayloadUpload()},
            {u"amountLeft"_s, torrent.remainingSize()},
            {u"completed"_s, torrent.completedSize()},
            {u"connectionsCount"_s, torrent.connectionsCount()},
            {u"connectionsLimit"_s, torrent.connectionsLimit()},
            {u"maxRatio"_s, torrent.effectiveRatioLimit()},
            {u"maxSeedingTime"_s, torrent.effectiveSeedingTimeLimit()},
            {u"maxInactiveSeedingTime"_s, torrent.effectiveInactiveSeedingTimeLimit()},
            {u"ratio"_s, adjustRatio(torrent.realRatio())},
            {u"ratioLimit"_s, torrent.ratioLimit()},
            {u"popularity"_s, torrent.popularity()},
            {u"seedingTimeLimit"_s, torrent.seedingTimeLimit()},
            {u"inactiveSeedingTimeLimit"_s, torrent.inactiveSeedingTimeLimit()},
            {u"shareLimitAction"_s, shareLimitActionName(torrent.shareLimitAction())},
            {u"lastSeenComplete"_s, toSecs(torrent.lastSeenComplete())},
            {u"lastActivity"_s, lastActivity},
            {u"autoTmm"_s, torrent.isAutoTMMEnabled()},
            {u"timeActive"_s, torrent.activeTime()},
            {u"seedingTime"_s, torrent.finishedTime()},
            {u"availability"_s, torrent.distributedCopies()},
            {u"reannounce"_s, torrent.nextAnnounce()},
            {u"comment"_s, torrent.comment()},
            {u"hasTrackerWarning"_s, announceStatus.testFlag(BitTorrent::TorrentAnnounceStatusFlag::HasWarning)},
            {u"hasTrackerError"_s, announceStatus.testFlag(BitTorrent::TorrentAnnounceStatusFlag::HasTrackerError)},
            {u"hasOtherAnnounceError"_s, announceStatus.testFlag(BitTorrent::TorrentAnnounceStatusFlag::HasOtherError)},
            {u"errorMessage"_s, torrent.error()}
        };
    }

    QJsonObject categoryJson(const QString &name, const BitTorrent::CategoryOptions &options)
    {
        QJsonObject downloadPath;
        if (!options.downloadPath)
            downloadPath = swiftCase(u"default"_s);
        else if (!options.downloadPath->enabled)
            downloadPath = swiftCase(u"disabled"_s);
        else
            downloadPath = swiftCase(u"path"_s, {{u"path"_s, options.downloadPath->path.toString()}});

        return {
            {u"name"_s, name},
            {u"savePath"_s, options.savePath.toString()},
            {u"downloadPath"_s, downloadPath},
            {u"ratioLimit"_s, options.ratioLimit},
            {u"seedingTimeLimit"_s, options.seedingTimeLimit},
            {u"inactiveSeedingTimeLimit"_s, options.inactiveSeedingTimeLimit},
            {u"shareLimitAction"_s, shareLimitActionName(options.shareLimitAction)}
        };
    }

    BitTorrent::CategoryOptions parseCategoryOptions(const QJsonObject &json)
    {
        BitTorrent::CategoryOptions options;
        options.savePath = Path(argString(json, u"savePath"_s));
        const QJsonObject downloadPath = json.value(u"downloadPath"_s).toObject();
        if (downloadPath.contains(u"disabled"))
            options.downloadPath = BitTorrent::DownloadPathOption {false, {}};
        else if (downloadPath.contains(u"path"))
            options.downloadPath = BitTorrent::DownloadPathOption {true, Path(downloadPath.value(u"path").toObject().value(u"path").toString())};
        options.ratioLimit = argDouble(json, u"ratioLimit"_s, BitTorrent::DEFAULT_RATIO_LIMIT);
        options.seedingTimeLimit = static_cast<int>(argInt(json, u"seedingTimeLimit"_s, BitTorrent::DEFAULT_SEEDING_TIME_LIMIT));
        options.inactiveSeedingTimeLimit = static_cast<int>(argInt(json, u"inactiveSeedingTimeLimit"_s, BitTorrent::DEFAULT_SEEDING_TIME_LIMIT));
        options.shareLimitAction = parseShareLimitAction(argString(json, u"shareLimitAction"_s));
        return options;
    }

    QJsonObject serverStateJson()
    {
        const auto *session = BitTorrent::Session::instance();
        const BitTorrent::SessionStatus &status = session->status();
        const BitTorrent::CacheStatus &cache = session->cacheStatus();

        const qint64 atd = status.allTimeDownload;
        const qint64 atu = status.allTimeUpload;
        const double globalRatio = ((atd > 0) && (atu > 0)) ? (static_cast<double>(atu) / atd) : -1.0;
        const double writeOverload = ((status.diskWriteQueue > 0) && (status.peersCount > 0))
            ? (100.0 * status.diskWriteQueue / status.peersCount) : 0.0;
        const double readOverload = ((status.diskReadQueue > 0) && (status.peersCount > 0))
            ? (100.0 * status.diskReadQueue / status.peersCount) : 0.0;

        const QString connectionStatus = session->isListening()
            ? (status.hasIncomingConnections ? u"connected"_s : u"firewalled"_s)
            : u"disconnected"_s;

        return {
            {u"dlSpeed"_s, status.payloadDownloadRate},
            {u"dlSessionData"_s, status.totalPayloadDownload},
            {u"upSpeed"_s, status.payloadUploadRate},
            {u"upSessionData"_s, status.totalPayloadUpload},
            {u"dlRateLimit"_s, session->downloadSpeedLimit()},
            {u"upRateLimit"_s, session->uploadSpeedLimit()},
            {u"dhtNodes"_s, status.dhtNodes},
            {u"connectionStatus"_s, connectionStatus},
            {u"queueing"_s, session->isQueueingSystemEnabled()},
            {u"useAltSpeedLimits"_s, session->isAltGlobalSpeedLimitEnabled()},
            {u"useSubcategories"_s, true},
            {u"refreshInterval"_s, session->refreshInterval()},
            {u"freeSpaceOnDisk"_s, session->freeDiskSpace()},
            {u"lastExternalAddressV4"_s, session->lastExternalIPv4Address()},
            {u"lastExternalAddressV6"_s, session->lastExternalIPv6Address()},
            {u"alltimeDownload"_s, atd},
            {u"alltimeUpload"_s, atu},
            {u"totalWastedSession"_s, status.totalWasted},
            {u"globalRatio"_s, globalRatio},
            {u"totalPeerConnections"_s, status.peersCount},
            {u"readCacheHits"_s, (cache.readRatio > 0) ? (100 * cache.readRatio) : 0.0},
            {u"totalBuffersSize"_s, cache.totalUsedBuffers * 16 * 1024},
            {u"writeCacheOverload"_s, writeOverload},
            {u"readCacheOverload"_s, readOverload},
            {u"queuedIoJobs"_s, cache.jobQueueLength},
            {u"averageTimeQueue"_s, cache.averageJobTime},
            {u"totalQueuedSize"_s, cache.queuedBytes}
        };
    }

    MainDataTracker::MainDataTracker(QObject *parent)
        : QObject(parent)
    {
    }

    void MainDataTracker::attachSession()
    {
        auto *session = BitTorrent::Session::instance();
        const auto markTrackers = [this] { m_trackersDirty = true; };
        connect(session, &BitTorrent::Session::trackersAdded, this, markTrackers);
        connect(session, &BitTorrent::Session::trackersRemoved, this, markTrackers);
        connect(session, &BitTorrent::Session::trackersReset, this, markTrackers);
        connect(session, &BitTorrent::Session::torrentAdded, this, markTrackers);
        connect(session, &BitTorrent::Session::torrentsLoaded, this, markTrackers);
        connect(session, &BitTorrent::Session::torrentAboutToBeRemoved, this, markTrackers);
        connect(session, &BitTorrent::Session::torrentMetadataReceived, this, markTrackers);
    }

    QHash<QString, QStringList> MainDataTracker::trackerMap()
    {
        if (!m_trackersDirty)
            return m_trackerCache;

        QHash<QString, QStringList> map;
        for (const BitTorrent::Torrent *torrent : asConst(BitTorrent::Session::instance()->torrents()))
        {
            const QString hash = torrent->id().toString();
            for (const BitTorrent::TrackerEntryStatus &tracker : asConst(torrent->trackers()))
                map[tracker.url].append(hash);
        }
        m_trackerCache = map;
        m_trackersDirty = false;
        return map;
    }

    void MainDataTracker::reset()
    {
        m_sent = false;
        m_torrents.clear();
        m_categories.clear();
        m_tags.clear();
        m_trackers.clear();
    }

    QJsonObject MainDataTracker::sync()
    {
        const auto *session = BitTorrent::Session::instance();
        ++m_rid;
        const bool full = !m_sent;
        m_sent = true;

        // Torrents
        QJsonArray torrents;
        QJsonArray torrentsRemoved;
        QSet<QString> seen;
        const QList<BitTorrent::Torrent *> sessionTorrents = session->torrents();
        seen.reserve(sessionTorrents.size());
        for (const BitTorrent::Torrent *torrent : sessionTorrents)
        {
            QJsonObject info = torrentInfoJson(*torrent);
            const QString hash = info.value(u"hash").toString();
            seen.insert(hash);
            auto it = m_torrents.find(hash);
            if (full || (it == m_torrents.end()) || (it.value() != info))
            {
                torrents.append(info);
                m_torrents.insert(hash, std::move(info));
            }
        }
        for (auto it = m_torrents.begin(); it != m_torrents.end();)
        {
            if (!seen.contains(it.key()))
            {
                torrentsRemoved.append(it.key());
                it = m_torrents.erase(it);
            }
            else
            {
                ++it;
            }
        }

        // Categories
        QJsonArray categories;
        QJsonArray categoriesRemoved;
        QSet<QString> seenCategories;
        for (const QString &name : asConst(session->categories()))
        {
            const QJsonObject category = categoryJson(name, session->categoryOptions(name));
            seenCategories.insert(name);
            auto it = m_categories.find(name);
            if (full || (it == m_categories.end()) || (it.value() != category))
            {
                categories.append(category);
                m_categories.insert(name, category);
            }
        }
        for (auto it = m_categories.begin(); it != m_categories.end();)
        {
            if (!seenCategories.contains(it.key()))
            {
                categoriesRemoved.append(it.key());
                it = m_categories.erase(it);
            }
            else
            {
                ++it;
            }
        }

        // Tags
        QJsonArray tags;
        QJsonArray tagsRemoved;
        QSet<QString> currentTags;
        for (const Tag &tag : asConst(session->tags()))
            currentTags.insert(tag.toString());
        for (const QString &tag : asConst(currentTags))
        {
            if (full || !m_tags.contains(tag))
                tags.append(tag);
        }
        for (const QString &tag : asConst(m_tags))
        {
            if (!currentTags.contains(tag))
                tagsRemoved.append(tag);
        }
        m_tags = currentTags;

        // Trackers (URL -> torrent hashes)
        QJsonArray trackers;
        QJsonArray trackersRemoved;
        const QHash<QString, QStringList> trackerMapNow = trackerMap();
        for (auto it = trackerMapNow.cbegin(); it != trackerMapNow.cend(); ++it)
        {
            const auto old = m_trackers.constFind(it.key());
            if (full || (old == m_trackers.cend()) || (old.value() != it.value()))
                trackers.append(QJsonObject {{u"url"_s, it.key()}, {u"hashes"_s, toJsonArray(it.value())}});
        }
        for (auto it = m_trackers.cbegin(); it != m_trackers.cend(); ++it)
        {
            if (!trackerMapNow.contains(it.key()))
                trackersRemoved.append(it.key());
        }
        m_trackers = trackerMapNow;

        return {
            {u"rid"_s, m_rid},
            {u"fullUpdate"_s, full},
            {u"torrents"_s, torrents},
            {u"torrentsRemoved"_s, torrentsRemoved},
            {u"categories"_s, categories},
            {u"categoriesRemoved"_s, categoriesRemoved},
            {u"tags"_s, tags},
            {u"tagsRemoved"_s, tagsRemoved},
            {u"trackers"_s, trackers},
            {u"trackersRemoved"_s, trackersRemoved},
            {u"serverState"_s, serverStateJson()}
        };
    }
}
