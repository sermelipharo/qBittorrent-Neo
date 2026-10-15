/*
 * qBittorrent Neo — torrent list, properties tabs and torrent actions.
 *
 * Semantics follow qBittorrent's GUI and WebAPI controllers
 * (src/webui/api/torrentscontroller.cpp, synccontroller.cpp).
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <algorithm>
#include <climits>

#include <QBitArray>
#include <QFileInfo>
#include <QFuture>
#include <QJsonArray>
#include <QJsonDocument>
#include <QNetworkCookie>
#include <QPointer>
#include <QRegularExpression>
#include <QUrl>

#include "base/bittorrent/addtorrentparams.h"
#include "base/bittorrent/categoryoptions.h"
#include "base/bittorrent/downloadpriority.h"
#include "base/bittorrent/infohash.h"
#include "base/bittorrent/peeraddress.h"
#include "base/bittorrent/peerinfo.h"
#include "base/bittorrent/session.h"
#include "base/bittorrent/torrent.h"
#include "base/bittorrent/torrentcontentlayout.h"
#include "base/bittorrent/torrentdescriptor.h"
#include "base/bittorrent/torrentinfo.h"
#include "base/bittorrent/trackerentry.h"
#include "base/bittorrent/trackerentrystatus.h"
#include "base/exceptions.h"
#include "base/global.h"
#include "base/logger.h"
#include "base/net/downloadmanager.h"
#include "base/net/geoipmanager.h"
#include "base/net/reverseresolution.h"
#include "base/preferences.h"
#include "base/tagset.h"
#include "base/utils/fs.h"
#include "addmanager.h"
#include "corehost.h"
#include "jsonutil.h"
#include "maindata.h"
#include "registry.h"

using namespace Neo;

namespace
{
    // Runs a continuation with errors turned into replies.
    template <typename Fn>
    void guarded(const Reply &reply, Fn &&fn)
    {
        try
        {
            fn();
        }
        catch (const ApiError &error)
        {
            reply.fail(error);
        }
        catch (const std::exception &error)
        {
            reply.fail(ErrorKind::Other, QString::fromUtf8(error.what()));
        }
    }

    QString priorityName(const BitTorrent::DownloadPriority priority)
    {
        switch (priority)
        {
        case BitTorrent::DownloadPriority::Ignored:
            return u"ignored"_s;
        case BitTorrent::DownloadPriority::High:
            return u"high"_s;
        case BitTorrent::DownloadPriority::Maximum:
            return u"maximum"_s;
        default:
            return u"normal"_s;
        }
    }

    BitTorrent::DownloadPriority parsePriority(const QString &name)
    {
        if (name == u"ignored")
            return BitTorrent::DownloadPriority::Ignored;
        if (name == u"high")
            return BitTorrent::DownloadPriority::High;
        if (name == u"maximum")
            return BitTorrent::DownloadPriority::Maximum;
        return BitTorrent::DownloadPriority::Normal;
    }

    BitTorrent::TorrentContentLayout parseContentLayout(const QString &name)
    {
        if (name == u"subfolder")
            return BitTorrent::TorrentContentLayout::Subfolder;
        if (name == u"noSubfolder")
            return BitTorrent::TorrentContentLayout::NoSubfolder;
        return BitTorrent::TorrentContentLayout::Original;
    }

    QString trackerStatusName(const BitTorrent::TrackerEndpointState state)
    {
        switch (state)
        {
        case BitTorrent::TrackerEndpointState::Working:
            return u"working"_s;
        case BitTorrent::TrackerEndpointState::NotWorking:
            return u"notWorking"_s;
        case BitTorrent::TrackerEndpointState::TrackerError:
            return u"trackerError"_s;
        case BitTorrent::TrackerEndpointState::Unreachable:
            return u"unreachable"_s;
        default:
            return u"notContacted"_s;
        }
    }

    // Extra trackers / web seeds of the "Add torrent" options, applied once
    // the session has added the torrent.
    struct PendingExtras
    {
        QList<BitTorrent::TrackerEntry> trackers;
        QList<QUrl> urlSeeds;
    };

    QHash<BitTorrent::TorrentID, PendingExtras> &pendingExtras()
    {
        static QHash<BitTorrent::TorrentID, PendingExtras> extras;
        return extras;
    }

    BitTorrent::AddTorrentParams parseAddParams(const QJsonObject &json, PendingExtras *extras, QString *cookie)
    {
        BitTorrent::AddTorrentParams params;
        params.name = argString(json, u"name"_s);
        params.category = argString(json, u"category"_s);
        for (const QString &tag : asConst(argStringList(json, u"tags"_s)))
        {
            const Tag t {tag};
            if (t.isValid())
                params.tags.insert(t);
        }
        if (const auto savePath = argOptString(json, u"savePath"_s))
            params.savePath = Path(*savePath);
        params.useDownloadPath = argOptBool(json, u"useDownloadPath"_s);
        if (const auto downloadPath = argOptString(json, u"downloadPath"_s))
            params.downloadPath = Path(*downloadPath);
        params.useAutoTMM = argOptBool(json, u"autoTmm"_s);
        params.addStopped = argOptBool(json, u"stopped"_s);
        if (const auto stopCondition = argOptString(json, u"stopCondition"_s))
            params.stopCondition = parseStopCondition(*stopCondition);
        params.skipChecking = argBool(json, u"skipChecking"_s);
        params.addToQueueTop = argOptBool(json, u"addToQueueTop"_s);
        if (const auto layout = argOptString(json, u"contentLayout"_s))
            params.contentLayout = parseContentLayout(*layout);
        params.sequential = argBool(json, u"sequential"_s);
        params.firstLastPiecePriority = argBool(json, u"firstLastPiecePriority"_s);
        params.addForced = argBool(json, u"forced"_s);
        const qint64 dlLimit = argInt(json, u"downloadLimit"_s, -1);
        const qint64 upLimit = argInt(json, u"uploadLimit"_s, -1);
        params.downloadLimit = (dlLimit > 0) ? static_cast<int>(dlLimit) : -1;
        params.uploadLimit = (upLimit > 0) ? static_cast<int>(upLimit) : -1;
        params.ratioLimit = argDouble(json, u"ratioLimit"_s, BitTorrent::DEFAULT_RATIO_LIMIT);
        params.seedingTimeLimit = static_cast<int>(argInt(json, u"seedingTimeLimit"_s, BitTorrent::DEFAULT_SEEDING_TIME_LIMIT));
        params.inactiveSeedingTimeLimit = static_cast<int>(argInt(json, u"inactiveSeedingTimeLimit"_s, BitTorrent::DEFAULT_SEEDING_TIME_LIMIT));
        if (const auto action = argOptString(json, u"shareLimitAction"_s))
            params.shareLimitAction = parseShareLimitAction(*action);

        for (const QString &priority : asConst(argStringList(json, u"filePriorities"_s)))
            params.filePriorities.append(parsePriority(priority));
        for (const QString &path : asConst(argStringList(json, u"filePaths"_s)))
            params.filePaths.append(Path(path));

        if (extras)
        {
            int tier = 0;
            for (const QString &url : asConst(argStringList(json, u"trackers"_s)))
            {
                if (url.trimmed().isEmpty())
                {
                    ++tier;
                    continue;
                }
                extras->trackers.append({url.trimmed(), tier});
            }
            for (const QString &url : asConst(argStringList(json, u"urlSeeds"_s)))
            {
                const QUrl seed {url.trimmed()};
                if (seed.isValid())
                    extras->urlSeeds.append(seed);
            }
        }
        if (cookie)
            *cookie = argString(json, u"cookie"_s);
        return params;
    }

    void applyCookie(const QString &url, const QString &cookie)
    {
        if (cookie.isEmpty())
            return;
        QList<QNetworkCookie> cookies;
        for (const QString &part : asConst(cookie.split(u';', Qt::SkipEmptyParts)))
        {
            const qsizetype sep = part.indexOf(u'=');
            if (sep <= 0)
                continue;
            cookies.append(QNetworkCookie(part.left(sep).trimmed().toUtf8(), part.mid(sep + 1).trimmed().toUtf8()));
        }
        if (!cookies.isEmpty())
            Net::DownloadManager::instance()->setCookiesFromUrl(cookies, QUrl::fromEncoded(url.toUtf8()));
    }

    QJsonObject metadataJson(const BitTorrent::TorrentDescriptor &descriptor, const bool isDuplicate)
    {
        const BitTorrent::InfoHash infoHash = descriptor.infoHash();
        QJsonArray files;
        qint64 totalSize = 0;
        qint64 pieceSize = 0;
        qint64 piecesNum = 0;
        bool isPrivate = false;
        const std::optional<BitTorrent::TorrentInfo> &info = descriptor.info();
        if (info && info->isValid())
        {
            for (int i = 0; i < info->filesCount(); ++i)
            {
                files.append(QJsonObject {
                    {u"index"_s, i},
                    {u"path"_s, info->filePath(i).data()},
                    {u"size"_s, info->fileSize(i)}
                });
            }
            totalSize = info->totalSize();
            pieceSize = info->pieceLength();
            piecesNum = info->piecesCount();
            isPrivate = info->isPrivate();
        }
        Q_UNUSED(isPrivate);

        QJsonArray trackers;
        for (const BitTorrent::TrackerEntry &tracker : asConst(descriptor.trackers()))
            trackers.append(QJsonObject {{u"url"_s, tracker.url}, {u"tier"_s, tracker.tier}});
        QJsonArray urlSeeds;
        for (const QUrl &url : asConst(descriptor.urlSeeds()))
            urlSeeds.append(url.toString());

        return {
            {u"hash"_s, infoHash.toTorrentID().toString()},
            {u"infohashV1"_s, infoHash.v1().toString()},
            {u"infohashV2"_s, infoHash.v2().toString()},
            {u"name"_s, descriptor.name()},
            {u"hasMetadata"_s, info.has_value() && info->isValid()},
            {u"totalSize"_s, totalSize},
            {u"pieceSize"_s, pieceSize},
            {u"piecesNum"_s, piecesNum},
            {u"comment"_s, descriptor.comment()},
            {u"createdBy"_s, descriptor.creator()},
            {u"creationDate"_s, toSecs(descriptor.creationDate())},
            {u"files"_s, files},
            {u"trackers"_s, trackers},
            {u"urlSeeds"_s, urlSeeds},
            {u"isDuplicate"_s, isDuplicate}
        };
    }

    // Retrieves metadata for the "Add new torrent" dialog: parses files and
    // links, downloads .torrent URLs and asks the swarm for magnet metadata.
    class MetadataFetcher final : public QObject
    {
    public:
        explicit MetadataFetcher(QObject *parent)
            : QObject(parent)
        {
            connect(BitTorrent::Session::instance(), &BitTorrent::Session::metadataDownloaded
                    , this, &MetadataFetcher::onMetadataDownloaded);
        }

        static MetadataFetcher *instance()
        {
            static QPointer<MetadataFetcher> fetcher;
            if (!fetcher)
                fetcher = new MetadataFetcher(CoreHost::instance());
            return fetcher;
        }

        void fetch(const QJsonObject &source, const Reply &reply)
        {
            if (source.contains(u"bytes"))
            {
                const QByteArray data = QByteArray::fromBase64(source.value(u"bytes").toObject().value(u"data").toString().toLatin1());
                const auto result = BitTorrent::TorrentDescriptor::load(data);
                if (!result)
                    throwInvalid(result.error());
                return resolve(result.value(), reply);
            }
            if (source.contains(u"file"))
            {
                const Path path {source.value(u"file").toObject().value(u"path").toString()};
                const auto result = BitTorrent::TorrentDescriptor::loadFromFile(path);
                if (!result)
                    throwInvalid(result.error());
                return resolve(result.value(), reply);
            }

            const QString url = source.value(u"url").toObject().value(u"url").toString().trimmed();
            if (url.isEmpty())
                throwInvalid(tr("Must specify URI or hash"));

            if (const auto result = BitTorrent::TorrentDescriptor::parse(url))
                return resolve(result.value(), reply);

            if (url.startsWith(u"http://", Qt::CaseInsensitive) || url.startsWith(u"https://", Qt::CaseInsensitive))
            {
                const auto *pref = Preferences::instance();
                Net::DownloadManager::instance()->download(Net::DownloadRequest(url).limit(pref->getTorrentFileSizeLimit())
                        , pref->useProxyForGeneralPurposes(), this, [this, reply](const Net::DownloadResult &result)
                {
                    if (reply.isDone())
                        return;
                    guarded(reply, [&]
                    {
                        switch (result.status)
                        {
                        case Net::DownloadStatus::Success:
                            if (const auto load = BitTorrent::TorrentDescriptor::load(result.data))
                                return resolve(load.value(), reply);
                            else
                                throwInvalid(load.error());
                        case Net::DownloadStatus::RedirectedToMagnet:
                            if (const auto parse = BitTorrent::TorrentDescriptor::parse(result.magnetURI))
                                return resolve(parse.value(), reply);
                            else
                                throwInvalid(parse.error());
                        default:
                            throw ApiError(ErrorKind::Network, result.errorString);
                        }
                    });
                });
                return;
            }

            // A local path given as "url".
            const Path path {url.startsWith(u"file://", Qt::CaseInsensitive) ? QUrl(url).toLocalFile() : url};
            const auto result = BitTorrent::TorrentDescriptor::loadFromFile(path);
            if (!result)
                throwInvalid(result.error());
            resolve(result.value(), reply);
        }

    private:
        void resolve(BitTorrent::TorrentDescriptor descriptor, const Reply &reply)
        {
            auto *session = BitTorrent::Session::instance();
            auto *addManager = CoreHost::instance()->addManager();
            const BitTorrent::InfoHash infoHash = descriptor.infoHash();
            const BitTorrent::TorrentID id = infoHash.toTorrentID();

            if (const BitTorrent::Torrent *torrent = session->findTorrent(infoHash))
            {
                if (!descriptor.info() && torrent->hasMetadata())
                    descriptor.setTorrentInfo(torrent->info());
                reply.ok(metadataJson(descriptor, true));
                return;
            }

            if (descriptor.info())
            {
                if (addManager)
                    addManager->rememberMetadata(descriptor);
                reply.ok(metadataJson(descriptor, false));
                return;
            }

            if (addManager)
            {
                if (const auto cached = addManager->fetchedMetadata(id); cached && cached->info())
                {
                    descriptor.setTorrentInfo(*cached->info());
                    reply.ok(metadataJson(descriptor, false));
                    return;
                }
            }

            // Magnet link: ask the swarm.
            m_waiting.insert(id, {descriptor, reply});
            reply.setCancelHandler([this, id, reply]
            {
                m_waiting.remove(id, Waiter {{}, reply});
                if (!m_waiting.contains(id))
                    BitTorrent::Session::instance()->cancelDownloadMetadata(id);
            });
            if (!session->isKnownTorrent(infoHash))
            {
                if (!session->downloadMetadata(descriptor))
                {
                    m_waiting.remove(id);
                    throwInvalid(tr("Unable to download metadata for '%1'").arg(id.toString()));
                }
            }
        }

        void onMetadataDownloaded(const BitTorrent::TorrentInfo &info)
        {
            if (!info.isValid())
                return;
            const BitTorrent::InfoHash infoHash = info.infoHash();
            QList<BitTorrent::TorrentID> ids {infoHash.toTorrentID()};
            if (infoHash.isHybrid())
                ids.append(BitTorrent::TorrentID::fromSHA1Hash(infoHash.v1()));

            for (const BitTorrent::TorrentID &id : ids)
            {
                const QList<Waiter> waiters = m_waiting.values(id);
                m_waiting.remove(id);
                for (Waiter waiter : waiters)
                {
                    waiter.descriptor.setTorrentInfo(info);
                    if (auto *addManager = CoreHost::instance()->addManager())
                        addManager->rememberMetadata(waiter.descriptor);
                    waiter.reply.ok(metadataJson(waiter.descriptor, false));
                }
            }
        }

        struct Waiter
        {
            BitTorrent::TorrentDescriptor descriptor;
            Reply reply;

            bool operator==(const Waiter &other) const { return reply == other.reply; }
        };

        QMultiHash<BitTorrent::TorrentID, Waiter> m_waiting;
    };

    QJsonArray trackersJson(const BitTorrent::Torrent *torrent, const QList<BitTorrent::PeerInfo> &peers)
    {
        const auto now = std::chrono::system_clock::now();
        const auto timepointNow = BitTorrent::AnnounceTimePoint::clock::now();
        const auto toSecondsSinceEpoch = [&now, &timepointNow](const BitTorrent::AnnounceTimePoint &time) -> qint64
        {
            const auto timeEpoch = (now + (time - timepointNow)).time_since_epoch();
            return std::chrono::duration_cast<std::chrono::seconds>(timeEpoch).count();
        };

        // DHT / PeX / LSD rows, as in qBittorrent's tracker list.
        int seedsDHT = 0, seedsPeX = 0, seedsLSD = 0, leechesDHT = 0, leechesPeX = 0, leechesLSD = 0;
        for (const BitTorrent::PeerInfo &peer : peers)
        {
            if (peer.isConnecting())
                continue;
            if (peer.isSeed())
            {
                seedsDHT += peer.fromDHT();
                seedsPeX += peer.fromPeX();
                seedsLSD += peer.fromLSD();
            }
            else
            {
                leechesDHT += peer.fromDHT();
                leechesPeX += peer.fromPeX();
                leechesLSD += peer.fromLSD();
            }
        }

        const auto *session = BitTorrent::Session::instance();
        const bool isPrivate = torrent->isPrivate();
        const QString privateMsg = QCoreApplication::translate("TrackerListWidget", "This torrent is private");
        const auto sticky = [&](const QString &url, const bool enabled, const int seeds, const int leeches)
        {
            return QJsonObject {
                {u"url"_s, url},
                {u"tier"_s, -1},
                {u"status"_s, (enabled && !isPrivate) ? u"working"_s : u"disabled"_s},
                {u"updating"_s, false},
                {u"message"_s, isPrivate ? privateMsg : QString()},
                {u"numPeers"_s, 0},
                {u"numSeeds"_s, seeds},
                {u"numLeeches"_s, leeches},
                {u"numDownloaded"_s, 0},
                {u"nextAnnounce"_s, 0},
                {u"minAnnounce"_s, 0},
                {u"endpoints"_s, QJsonArray {}}
            };
        };

        QJsonArray result {
            sticky(u"** [DHT] **"_s, session->isDHTEnabled() && !torrent->isDHTDisabled(), seedsDHT, leechesDHT),
            sticky(u"** [PeX] **"_s, session->isPeXEnabled() && !torrent->isPEXDisabled(), seedsPeX, leechesPeX),
            sticky(u"** [LSD] **"_s, session->isLSDEnabled() && !torrent->isLSDDisabled(), seedsLSD, leechesLSD)
        };

        for (const BitTorrent::TrackerEntryStatus &tracker : asConst(torrent->trackers()))
        {
            QJsonArray endpoints;
            for (const BitTorrent::TrackerEndpointStatus &endpoint : tracker.endpoints)
            {
                endpoints.append(QJsonObject {
                    {u"name"_s, endpoint.name},
                    {u"updating"_s, endpoint.isUpdating},
                    {u"status"_s, trackerStatusName(endpoint.state)},
                    {u"message"_s, endpoint.message},
                    {u"btVersion"_s, endpoint.btVersion},
                    {u"numPeers"_s, endpoint.numPeers},
                    {u"numSeeds"_s, endpoint.numSeeds},
                    {u"numLeeches"_s, endpoint.numLeeches},
                    {u"numDownloaded"_s, endpoint.numDownloaded},
                    {u"nextAnnounce"_s, toSecondsSinceEpoch(endpoint.nextAnnounceTime)},
                    {u"minAnnounce"_s, toSecondsSinceEpoch(endpoint.minAnnounceTime)}
                });
            }

            result.append(QJsonObject {
                {u"url"_s, tracker.url},
                {u"tier"_s, tracker.tier},
                {u"status"_s, tracker.isUpdating ? u"updating"_s : trackerStatusName(tracker.state)},
                {u"updating"_s, tracker.isUpdating},
                {u"message"_s, tracker.message},
                {u"numPeers"_s, tracker.numPeers},
                {u"numSeeds"_s, tracker.numSeeds},
                {u"numLeeches"_s, tracker.numLeeches},
                {u"numDownloaded"_s, tracker.numDownloaded},
                {u"nextAnnounce"_s, toSecondsSinceEpoch(tracker.nextAnnounceTime)},
                {u"minAnnounce"_s, toSecondsSinceEpoch(tracker.minAnnounceTime)},
                {u"endpoints"_s, endpoints}
            });
        }
        return result;
    }

    QJsonObject propertiesJson(const BitTorrent::Torrent *torrent)
    {
        const BitTorrent::InfoHash infoHash = torrent->infoHash();
        const qlonglong totalDownload = torrent->totalDownload();
        const qlonglong totalUpload = torrent->totalUpload();
        const qlonglong dlDuration = torrent->activeTime() - torrent->finishedTime();
        const qlonglong ulDuration = torrent->activeTime();
        const int downloadLimit = torrent->downloadLimit();
        const int uploadLimit = torrent->uploadLimit();
        const qreal ratio = torrent->realRatio();
        const qreal popularity = torrent->popularity();

        return {
            {u"hash"_s, torrent->id().toString()},
            {u"infohashV1"_s, infoHash.v1().toString()},
            {u"infohashV2"_s, infoHash.v2().toString()},
            {u"name"_s, torrent->name()},
            {u"timeElapsed"_s, torrent->activeTime()},
            {u"seedingTime"_s, torrent->finishedTime()},
            {u"eta"_s, torrent->eta()},
            {u"connections"_s, torrent->connectionsCount()},
            {u"connectionsLimit"_s, torrent->connectionsLimit()},
            {u"totalDownloaded"_s, totalDownload},
            {u"totalDownloadedSession"_s, torrent->totalPayloadDownload()},
            {u"totalUploaded"_s, totalUpload},
            {u"totalUploadedSession"_s, torrent->totalPayloadUpload()},
            {u"dlSpeed"_s, torrent->downloadPayloadRate()},
            {u"dlSpeedAvg"_s, ((dlDuration > 0) ? (totalDownload / dlDuration) : -1)},
            {u"upSpeed"_s, torrent->uploadPayloadRate()},
            {u"upSpeedAvg"_s, ((ulDuration > 0) ? (totalUpload / ulDuration) : -1)},
            {u"dlLimit"_s, ((downloadLimit > 0) ? downloadLimit : -1)},
            {u"upLimit"_s, ((uploadLimit > 0) ? uploadLimit : -1)},
            {u"totalWasted"_s, torrent->wastedSize()},
            {u"seeds"_s, torrent->seedsCount()},
            {u"seedsTotal"_s, torrent->totalSeedsCount()},
            {u"peers"_s, torrent->leechsCount()},
            {u"peersTotal"_s, torrent->totalLeechersCount()},
            {u"shareRatio"_s, ((ratio >= BitTorrent::Torrent::MAX_RATIO) ? -1 : ratio)},
            {u"popularity"_s, ((popularity >= BitTorrent::Torrent::MAX_RATIO) ? -1 : popularity)},
            {u"reannounce"_s, torrent->nextAnnounce()},
            {u"totalSize"_s, torrent->totalSize()},
            {u"piecesNum"_s, torrent->piecesCount()},
            {u"pieceSize"_s, torrent->pieceLength()},
            {u"piecesHave"_s, torrent->piecesHave()},
            {u"createdBy"_s, torrent->creator()},
            {u"lastSeen"_s, toSecs(torrent->lastSeenComplete())},
            {u"additionDate"_s, toSecs(torrent->addedTime())},
            {u"completionDate"_s, toSecs(torrent->completedTime())},
            {u"creationDate"_s, toSecs(torrent->creationDate())},
            {u"savePath"_s, torrent->savePath().toString()},
            {u"downloadPath"_s, torrent->downloadPath().toString()},
            {u"comment"_s, torrent->comment()},
            {u"hasMetadata"_s, torrent->hasMetadata()},
            {u"progress"_s, torrent->progress()},
            {u"availability"_s, torrent->distributedCopies()}
        };
    }

    QJsonObject peerJson(const BitTorrent::Torrent *torrent, const BitTorrent::PeerInfo &peer
            , const bool resolveHostNames, const bool resolveCountries)
    {
        QJsonObject result {
            {u"client"_s, peer.client()},
            {u"peerIdClient"_s, peer.peerIdClient()},
            {u"connectionType"_s, peer.connectionType()},
            {u"dlSpeed"_s, peer.payloadDownSpeed()},
            {u"upSpeed"_s, peer.payloadUpSpeed()},
            {u"downloaded"_s, peer.totalDownload()},
            {u"uploaded"_s, peer.totalUpload()},
            {u"progress"_s, peer.progress()},
            {u"relevance"_s, peer.relevance()},
            {u"flags"_s, peer.flags()},
            {u"flagsDescription"_s, peer.flagsDescription()}
        };

        if (torrent->hasMetadata())
        {
            QStringList files;
            for (const Path &filePath : asConst(torrent->info().filesForPiece(peer.downloadingPieceIndex())))
                files.append(filePath.toString());
            result[u"files"_s] = files.join(u'\n');
        }

        if (peer.useI2PSocket())
        {
            result[u"ip"_s] = peer.I2PAddress();
            result[u"port"_s] = 0;
            return result;
        }

        const BitTorrent::PeerAddress address = peer.address();
        result[u"ip"_s] = address.ip.toString();
        result[u"port"_s] = address.port;
        if (resolveHostNames)
        {
            const QString host = Net::ReverseResolution::instance()->resolve(address.ip);
            if (host != address.ip.toString())
                result[u"hostName"_s] = host;
        }
        if (resolveCountries)
        {
            result[u"countryCode"_s] = peer.country().toLower();
            result[u"country"_s] = Net::GeoIPManager::CountryName(peer.country());
        }
        return result;
    }

    void forTorrents(const QJsonObject &args, const std::function<void (BitTorrent::Torrent *)> &fn)
    {
        for (BitTorrent::Torrent *torrent : asConst(torrentsFor(argStringList(args, u"hashes"_s))))
            fn(torrent);
    }

    void makeWritableDir(const Path &path)
    {
        if (path.isEmpty())
            throwInvalid(QCoreApplication::translate("TorrentsController", "Save path cannot be empty"));
        if (!Utils::Fs::mkpath(path))
            throwConflict(QCoreApplication::translate("TorrentsController", "Cannot make save path"));
        if (!Utils::Fs::isWritable(path))
            throwIo(QCoreApplication::translate("TorrentsController", "Cannot write to directory"));
    }

    QUrl validateWebSeed(const QString &urlStr)
    {
        const QUrl url {QUrl::fromPercentEncoding(urlStr.toLatin1()), QUrl::StrictMode};
        if (!url.isValid())
            throwInvalid(QCoreApplication::translate("TorrentsController", "\"%1\" is not a valid URL").arg(urlStr));
        const QString scheme = url.scheme();
        if ((scheme != u"http") && (scheme != u"https") && (scheme != u"ftp"))
            throwInvalid(QCoreApplication::translate("TorrentsController", "URL scheme must be one of [%1]").arg(u"http, https, ftp"_s));
        return url;
    }

    QList<BitTorrent::TrackerEntry> trackerTierEntries(const QJsonObject &args)
    {
        QList<BitTorrent::TrackerEntry> entries;
        for (const QJsonValue &value : asConst(args.value(u"trackers"_s).toArray()))
        {
            const QJsonObject item = value.toObject();
            const QString url = item.value(u"url").toString().trimmed();
            if (!url.isEmpty())
                entries.append({url, item.value(u"tier").toInt()});
        }
        return entries;
    }
}

void Neo::registerTorrentsApi(Registry &registry)
{
    // ---- Transfer list ---------------------------------------------------
    registry.add(u"syncMainData"_s, [](const QJsonObject &)
    {
        return CoreHost::instance()->mainData()->sync();
    });
    registry.add(u"resetMainData"_s, [](const QJsonObject &)
    {
        CoreHost::instance()->mainData()->reset();
        return QJsonValue();
    });

    // ---- Properties tabs -------------------------------------------------
    registry.add(u"properties"_s, [](const QJsonObject &args)
    {
        return propertiesJson(requireTorrent(argString(args, u"hash"_s)));
    });

    registry.addAsync(u"trackers"_s, [](const QJsonObject &args, const Reply &reply)
    {
        const BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        const BitTorrent::TorrentID id = torrent->id();
        torrent->fetchPeerInfo().then(CoreHost::instance(), [id, reply](const QList<BitTorrent::PeerInfo> &peers)
        {
            guarded(reply, [&] { reply.ok(trackersJson(requireTorrent(id.toString()), peers)); });
        });
    });

    registry.add(u"webSeeds"_s, [](const QJsonObject &args)
    {
        QJsonArray result;
        for (const QUrl &url : asConst(requireTorrent(argString(args, u"hash"_s))->urlSeeds()))
            result.append(QJsonObject {{u"url"_s, url.toString()}});
        return result;
    });

    registry.addAsync(u"files"_s, [](const QJsonObject &args, const Reply &reply)
    {
        const BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        if (!torrent->hasMetadata())
            return reply.ok(QJsonArray());

        QList<int> indexes;
        const int filesCount = torrent->filesCount();
        for (const qint64 index : asConst(argIntList(args, u"indexes"_s)))
        {
            if ((index < 0) || (index >= filesCount))
                throwConflict(QCoreApplication::translate("TorrentsController", "Index %1 is out of bounds.").arg(index));
            indexes.append(static_cast<int>(index));
        }
        if (indexes.isEmpty())
        {
            indexes.reserve(filesCount);
            for (int i = 0; i < filesCount; ++i)
                indexes.append(i);
        }

        const BitTorrent::TorrentID id = torrent->id();
        torrent->fetchAvailableFileFractions().then(CoreHost::instance(), [id, indexes, reply](const QList<qreal> &availability)
        {
            guarded(reply, [&]
            {
                const BitTorrent::Torrent *torrent = requireTorrent(id.toString());
                if (!torrent->hasMetadata())
                    return reply.ok(QJsonArray());

                const QList<BitTorrent::DownloadPriority> priorities = torrent->filePriorities();
                const QList<qreal> progress = torrent->filesProgress();
                const BitTorrent::TorrentInfo info = torrent->info();
                QJsonArray result;
                for (const int index : indexes)
                {
                    const BitTorrent::TorrentInfo::PieceRange range = info.filePieces(index);
                    result.append(QJsonObject {
                        {u"index"_s, index},
                        {u"name"_s, torrent->filePath(index).data()},
                        {u"size"_s, torrent->fileSize(index)},
                        {u"progress"_s, progress.value(index)},
                        {u"priority"_s, priorityName(priorities.value(index))},
                        {u"isSeed"_s, (index == 0) && torrent->isFinished()},
                        {u"pieceRange"_s, QJsonArray {range.first(), range.last()}},
                        {u"availability"_s, availability.value(index, -1)}
                    });
                }
                reply.ok(result);
            });
        });
    });

    registry.addAsync(u"pieceStates"_s, [](const QJsonObject &args, const Reply &reply)
    {
        const BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        const QBitArray have = torrent->pieces();
        torrent->fetchDownloadingPieces().then(CoreHost::instance(), [have, reply](const QBitArray &downloading)
        {
            QByteArray states(have.size(), '\0');
            for (qsizetype i = 0; i < have.size(); ++i)
            {
                if (have.testBit(i))
                    states[i] = 2;
                else if ((i < downloading.size()) && downloading.testBit(i))
                    states[i] = 1;
            }
            reply.ok(QString::fromLatin1(states.toBase64()));
        });
    });

    registry.addAsync(u"pieceAvailability"_s, [](const QJsonObject &args, const Reply &reply)
    {
        const BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        torrent->fetchPieceAvailability().then(CoreHost::instance(), [reply](const QList<int> &availability)
        {
            QJsonArray result;
            for (const int count : availability)
                result.append(std::max(count, 0));
            reply.ok(result);
        });
    });

    registry.addAsync(u"peers"_s, [](const QJsonObject &args, const Reply &reply)
    {
        const BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        const BitTorrent::TorrentID id = torrent->id();
        torrent->fetchPeerInfo().then(CoreHost::instance(), [id, reply](const QList<BitTorrent::PeerInfo> &peers)
        {
            guarded(reply, [&]
            {
                const BitTorrent::Torrent *torrent = requireTorrent(id.toString());
                const auto *pref = Preferences::instance();
                const bool resolveHostNames = pref->resolvePeerHostNames();
                const bool resolveCountries = pref->resolvePeerCountries();
                QJsonArray result;
                for (const BitTorrent::PeerInfo &peer : peers)
                {
                    if (peer.address().ip.isNull() && !peer.useI2PSocket())
                        continue;
                    result.append(peerJson(torrent, peer, resolveHostNames, resolveCountries));
                }
                reply.ok(result);
            });
        });
    });

    registry.add(u"exportTorrent"_s, [](const QJsonObject &args)
    {
        const auto result = requireTorrent(argString(args, u"hash"_s))->exportToBuffer();
        if (!result)
            throwConflict(QCoreApplication::translate("TorrentsController", "Unable to export torrent file. Error: %1").arg(result.error()));
        return QJsonValue(QString::fromLatin1(result.value().toBase64()));
    });

    // ---- Adding ----------------------------------------------------------
    registry.addAsync(u"addTorrent"_s, [](const QJsonObject &args, const Reply &reply)
    {
        CoreHost::instance()->whenReady([args, reply]
        {
            guarded(reply, [&]
            {
                PendingExtras extras;
                QString cookie;
                const BitTorrent::AddTorrentParams params = parseAddParams(argObject(args, u"params"_s), &extras, &cookie);
                const QJsonObject source = argObject(args, u"source"_s);
                auto *addManager = CoreHost::instance()->addManager();

                // Apply extra trackers / web seeds once the torrent exists.
                const auto rememberExtras = [extras](const QString &hash)
                {
                    if (extras.trackers.isEmpty() && extras.urlSeeds.isEmpty())
                        return;
                    const auto id = BitTorrent::TorrentID::fromString(hash);
                    if (BitTorrent::Torrent *torrent = BitTorrent::Session::instance()->getTorrent(id))
                    {
                        torrent->addTrackers(extras.trackers);
                        torrent->addUrlSeeds(extras.urlSeeds);
                    }
                    else
                    {
                        pendingExtras().insert(id, extras);
                    }
                };

                // Intercept the reply to learn the hash.
                struct Relay
                {
                    Reply reply;
                    std::function<void (const QString &)> onHash;
                };
                auto *relay = new Relay {reply, rememberExtras};
                const Reply inner {reply.id(), [](void *context, const int32_t status, const char *data, const size_t length)
                {
                    auto *relay = static_cast<Relay *>(context);
                    const QByteArray payload {data, static_cast<qsizetype>(length)};
                    if (status == QBTN_OK)
                    {
                        const QByteArray json = QByteArray("[") + payload + QByteArray("]");
                        const QString hash = QJsonDocument::fromJson(json).array().first().toString();
                        relay->onHash(hash);
                        relay->reply.okRaw(payload);
                    }
                    else
                    {
                        relay->reply.fail(static_cast<ErrorKind>(status), QString::fromUtf8(payload));
                    }
                    delete relay;
                }, relay};

                if (source.contains(u"bytes"))
                {
                    const QByteArray data = QByteArray::fromBase64(source.value(u"bytes").toObject().value(u"data").toString().toLatin1());
                    addManager->addData(data, params, inner);
                }
                else if (source.contains(u"file"))
                {
                    addManager->add(source.value(u"file").toObject().value(u"path").toString(), params, inner);
                }
                else
                {
                    const QString url = source.value(u"url").toObject().value(u"url").toString().trimmed();
                    applyCookie(url, cookie);
                    addManager->add(url, params, inner);
                }
            });
        });
    });

    registry.addAsync(u"fetchMetadata"_s, [](const QJsonObject &args, const Reply &reply)
    {
        CoreHost::instance()->whenReady([args, reply]
        {
            guarded(reply, [&] { MetadataFetcher::instance()->fetch(argObject(args, u"source"_s), reply); });
        });
    });

    registry.add(u"saveFetchedMetadata"_s, [](const QJsonObject &args)
    {
        const auto id = BitTorrent::TorrentID::fromString(argString(args, u"hash"_s));
        auto *addManager = CoreHost::instance()->addManager();
        const auto descriptor = addManager ? addManager->fetchedMetadata(id) : std::nullopt;
        if (!descriptor || !descriptor->info())
            throwConflict(QCoreApplication::translate("TorrentsController", "Metadata is not yet available"));
        const auto result = descriptor->saveToBuffer();
        if (!result)
            throwIo(result.error());
        return QJsonValue(QString::fromLatin1(result.value().toBase64()));
    });

    // ---- Torrent actions -------------------------------------------------
    registry.add(u"startTorrents"_s, [](const QJsonObject &args)
    {
        forTorrents(args, [](BitTorrent::Torrent *t) { t->start(); });
        return QJsonValue();
    });
    registry.add(u"stopTorrents"_s, [](const QJsonObject &args)
    {
        forTorrents(args, [](BitTorrent::Torrent *t) { t->stop(); });
        return QJsonValue();
    });
    registry.add(u"setForceStart"_s, [](const QJsonObject &args)
    {
        const bool value = argBool(args, u"value"_s);
        forTorrents(args, [value](BitTorrent::Torrent *t)
        {
            t->start(value ? BitTorrent::TorrentOperatingMode::Forced : BitTorrent::TorrentOperatingMode::AutoManaged);
        });
        return QJsonValue();
    });
    registry.add(u"removeTorrents"_s, [](const QJsonObject &args)
    {
        const auto option = argBool(args, u"deleteFiles"_s)
            ? BitTorrent::TorrentRemoveOption::RemoveContent : BitTorrent::TorrentRemoveOption::KeepContent;
        for (const BitTorrent::TorrentID &id : asConst(idsFor(argStringList(args, u"hashes"_s))))
            BitTorrent::Session::instance()->removeTorrent(id, option);
        return QJsonValue();
    });
    registry.add(u"recheckTorrents"_s, [](const QJsonObject &args)
    {
        forTorrents(args, [](BitTorrent::Torrent *t) { t->forceRecheck(); });
        return QJsonValue();
    });
    registry.add(u"reannounceTorrents"_s, [](const QJsonObject &args)
    {
        forTorrents(args, [](BitTorrent::Torrent *t)
        {
            t->forceReannounce();
            t->forceDHTAnnounce();
        });
        return QJsonValue();
    });
    registry.add(u"setLocation"_s, [](const QJsonObject &args)
    {
        const Path location {argString(args, u"location"_s).trimmed()};
        makeWritableDir(location);
        forTorrents(args, [&location](BitTorrent::Torrent *t)
        {
            LogMsg(QCoreApplication::translate("TransferListWidget", "Set location: moving \"%1\", from \"%2\" to \"%3\"")
                .arg(t->name(), t->savePath().toString(), location.toString()));
            t->setAutoTMMEnabled(false);
            t->setSavePath(location);
        });
        return QJsonValue();
    });
    registry.add(u"setSavePath"_s, [](const QJsonObject &args)
    {
        const Path path {argString(args, u"path"_s)};
        makeWritableDir(path);
        forTorrents(args, [&path](BitTorrent::Torrent *t)
        {
            if (!t->isAutoTMMEnabled())
                t->setSavePath(path);
        });
        return QJsonValue();
    });
    registry.add(u"setDownloadPath"_s, [](const QJsonObject &args)
    {
        const Path path {argString(args, u"path"_s)};
        if (!path.isEmpty())
            makeWritableDir(path);
        forTorrents(args, [&path](BitTorrent::Torrent *t)
        {
            if (!t->isAutoTMMEnabled())
                t->setDownloadPath(path);
        });
        return QJsonValue();
    });
    registry.add(u"renameTorrent"_s, [](const QJsonObject &args)
    {
        QString name = argString(args, u"name"_s).trimmed();
        if (name.isEmpty())
            throwConflict(QCoreApplication::translate("TorrentsController", "Incorrect torrent name"));
        name.replace(QRegularExpression(u"\r?\n|\r"_s), u" "_s);
        requireTorrent(argString(args, u"hash"_s))->setName(name);
        return QJsonValue();
    });

    const auto renameHandler = [](const bool folder)
    {
        return [folder](const QJsonObject &args) -> QJsonValue
        {
            const QString newPathStr = argString(args, u"newPath"_s);
            if (!Utils::Fs::isValidName(QFileInfo(newPathStr).fileName()))
            {
                throwConflict(folder
                    ? QCoreApplication::translate("TorrentsController", "Folder name has invalid characters")
                    : QCoreApplication::translate("TorrentsController", "File name has invalid characters"));
            }
            BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
            const Path oldPath {argString(args, u"oldPath"_s)};
            const Path newPath {newPathStr};
            try
            {
                if (folder)
                    torrent->renameFolder(oldPath, newPath);
                else
                    torrent->renameFile(oldPath, newPath);
            }
            catch (const RuntimeError &error)
            {
                throwConflict(error.message());
            }
            return {};
        };
    };
    registry.add(u"renameFile"_s, renameHandler(false));
    registry.add(u"renameFolder"_s, renameHandler(true));

    registry.add(u"setFilePriority"_s, [](const QJsonObject &args)
    {
        BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        if (!torrent->hasMetadata())
            throwConflict(QCoreApplication::translate("TorrentsController", "Torrent's metadata has not yet downloaded"));
        const BitTorrent::DownloadPriority priority = parsePriority(argString(args, u"priority"_s));
        const int filesCount = torrent->filesCount();
        QList<BitTorrent::DownloadPriority> priorities = torrent->filePriorities();
        bool changed = false;
        for (const qint64 index : asConst(argIntList(args, u"indexes"_s)))
        {
            if ((index < 0) || (index >= filesCount))
                throwConflict(QCoreApplication::translate("TorrentsController", "File ID is not valid"));
            if (priorities[index] != priority)
            {
                priorities[index] = priority;
                changed = true;
            }
        }
        if (changed)
            torrent->prioritizeFiles(priorities);
        return QJsonValue();
    });

    registry.add(u"setAutoManagement"_s, [](const QJsonObject &args)
    {
        const bool enabled = argBool(args, u"enabled"_s);
        forTorrents(args, [enabled](BitTorrent::Torrent *t) { t->setAutoTMMEnabled(enabled); });
        return QJsonValue();
    });
    registry.add(u"setDownloadLimit"_s, [](const QJsonObject &args)
    {
        const qint64 limit = argInt(args, u"limit"_s);
        forTorrents(args, [limit](BitTorrent::Torrent *t) { t->setDownloadLimit(static_cast<int>(std::clamp<qint64>(limit, -1, INT_MAX))); });
        return QJsonValue();
    });
    registry.add(u"setUploadLimit"_s, [](const QJsonObject &args)
    {
        const qint64 limit = argInt(args, u"limit"_s);
        forTorrents(args, [limit](BitTorrent::Torrent *t) { t->setUploadLimit(static_cast<int>(std::clamp<qint64>(limit, -1, INT_MAX))); });
        return QJsonValue();
    });
    registry.add(u"setShareLimits"_s, [](const QJsonObject &args)
    {
        const qreal ratio = argDouble(args, u"ratioLimit"_s, BitTorrent::DEFAULT_RATIO_LIMIT);
        const int seeding = static_cast<int>(argInt(args, u"seedingTimeLimit"_s, BitTorrent::DEFAULT_SEEDING_TIME_LIMIT));
        const int inactive = static_cast<int>(argInt(args, u"inactiveSeedingTimeLimit"_s, BitTorrent::DEFAULT_SEEDING_TIME_LIMIT));
        const BitTorrent::ShareLimitAction action = parseShareLimitAction(argString(args, u"action"_s));
        forTorrents(args, [=](BitTorrent::Torrent *t)
        {
            t->setRatioLimit(ratio);
            t->setSeedingTimeLimit(seeding);
            t->setInactiveSeedingTimeLimit(inactive);
            t->setShareLimitAction(action);
        });
        return QJsonValue();
    });
    registry.add(u"setSuperSeeding"_s, [](const QJsonObject &args)
    {
        const bool value = argBool(args, u"value"_s);
        forTorrents(args, [value](BitTorrent::Torrent *t) { t->setSuperSeeding(value); });
        return QJsonValue();
    });
    registry.add(u"setSequentialDownload"_s, [](const QJsonObject &args)
    {
        const bool value = argBool(args, u"value"_s);
        forTorrents(args, [value](BitTorrent::Torrent *t) { t->setSequentialDownload(value); });
        return QJsonValue();
    });
    registry.add(u"setFirstLastPiecePriority"_s, [](const QJsonObject &args)
    {
        const bool value = argBool(args, u"value"_s);
        forTorrents(args, [value](BitTorrent::Torrent *t) { t->setFirstLastPiecePriority(value); });
        return QJsonValue();
    });
    registry.add(u"discoveryOptions"_s, [](const QJsonObject &args)
    {
        QJsonArray result;
        forTorrents(args, [&result](BitTorrent::Torrent *t)
        {
            result.append(QJsonObject {
                {u"hash"_s, t->id().toString()},
                {u"disableDht"_s, t->isDHTDisabled()},
                {u"disablePex"_s, t->isPEXDisabled()},
                {u"disableLsd"_s, t->isLSDDisabled()}
            });
        });
        return result;
    });
    registry.add(u"setDhtDisabled"_s, [](const QJsonObject &args)
    {
        const bool value = argBool(args, u"value"_s);
        forTorrents(args, [value](BitTorrent::Torrent *t) { t->setDHTDisabled(value); });
        return QJsonValue();
    });
    registry.add(u"setPexDisabled"_s, [](const QJsonObject &args)
    {
        const bool value = argBool(args, u"value"_s);
        forTorrents(args, [value](BitTorrent::Torrent *t) { t->setPEXDisabled(value); });
        return QJsonValue();
    });
    registry.add(u"setLsdDisabled"_s, [](const QJsonObject &args)
    {
        const bool value = argBool(args, u"value"_s);
        forTorrents(args, [value](BitTorrent::Torrent *t) { t->setLSDDisabled(value); });
        return QJsonValue();
    });

    const auto queueHandler = [](void (BitTorrent::Session::*fn)(const QList<BitTorrent::TorrentID> &))
    {
        return [fn](const QJsonObject &args) -> QJsonValue
        {
            auto *session = BitTorrent::Session::instance();
            if (!session->isQueueingSystemEnabled())
                throwConflict(QCoreApplication::translate("TorrentsController", "Torrent queueing must be enabled"));
            (session->*fn)(idsFor(argStringList(args, u"hashes"_s)));
            return {};
        };
    };
    registry.add(u"queueIncrease"_s, queueHandler(&BitTorrent::Session::increaseTorrentsQueuePos));
    registry.add(u"queueDecrease"_s, queueHandler(&BitTorrent::Session::decreaseTorrentsQueuePos));
    registry.add(u"queueTop"_s, queueHandler(&BitTorrent::Session::topTorrentsQueuePos));
    registry.add(u"queueBottom"_s, queueHandler(&BitTorrent::Session::bottomTorrentsQueuePos));

    // ---- Trackers, peers, web seeds --------------------------------------
    registry.add(u"addTrackers"_s, [](const QJsonObject &args)
    {
        requireTorrent(argString(args, u"hash"_s))->addTrackers(trackerTierEntries(args));
        return QJsonValue();
    });
    registry.add(u"editTracker"_s, [](const QJsonObject &args)
    {
        BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        const QUrl origUrl {argString(args, u"origUrl"_s)};
        const QUrl newUrl {argString(args, u"newUrl"_s)};
        if (!newUrl.isValid())
            throwInvalid(QCoreApplication::translate("TorrentsController", "New tracker URL is invalid"));
        if (newUrl == origUrl)
            return QJsonValue();

        QList<BitTorrent::TrackerEntry> entries;
        bool match = false;
        for (const BitTorrent::TrackerEntryStatus &tracker : asConst(torrent->trackers()))
        {
            const QUrl trackerUrl {tracker.url};
            if (trackerUrl == newUrl)
                throwConflict(QCoreApplication::translate("TorrentsController", "New tracker URL already exists"));
            BitTorrent::TrackerEntry entry {tracker.url, tracker.tier};
            if (trackerUrl == origUrl)
            {
                match = true;
                entry.url = newUrl.toString();
            }
            entries.append(entry);
        }
        if (!match)
            throwConflict(QCoreApplication::translate("TorrentsController", "Tracker not found"));
        torrent->replaceTrackers(entries);
        torrent->forceReannounce();
        return QJsonValue();
    });
    registry.add(u"removeTrackers"_s, [](const QJsonObject &args)
    {
        requireTorrent(argString(args, u"hash"_s))->removeTrackers(argStringList(args, u"urls"_s));
        return QJsonValue();
    });
    registry.add(u"replaceTrackers"_s, [](const QJsonObject &args)
    {
        BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        torrent->replaceTrackers(trackerTierEntries(args));
        torrent->forceReannounce();
        return QJsonValue();
    });
    registry.add(u"addPeers"_s, [](const QJsonObject &args)
    {
        QList<BitTorrent::PeerAddress> peers;
        for (const QString &peer : asConst(argStringList(args, u"peers"_s)))
        {
            const BitTorrent::PeerAddress address = BitTorrent::PeerAddress::parse(peer.trimmed());
            if (!address.ip.isNull())
                peers.append(address);
        }
        if (peers.isEmpty())
            throwInvalid(QCoreApplication::translate("TorrentsController", "No valid peers were specified"));
        forTorrents(args, [&peers](BitTorrent::Torrent *t)
        {
            for (const BitTorrent::PeerAddress &peer : asConst(peers))
                t->connectPeer(peer);
        });
        return QJsonValue();
    });
    registry.add(u"banPeers"_s, [](const QJsonObject &args)
    {
        for (const QString &peer : asConst(argStringList(args, u"peers"_s)))
        {
            const BitTorrent::PeerAddress address = BitTorrent::PeerAddress::parse(peer.trimmed());
            if (!address.ip.isNull())
                BitTorrent::Session::instance()->banIP(address.ip.toString());
        }
        return QJsonValue();
    });
    registry.add(u"addWebSeeds"_s, [](const QJsonObject &args)
    {
        BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        QList<QUrl> urls;
        for (const QString &url : asConst(argStringList(args, u"urls"_s)))
            urls.append(validateWebSeed(url));
        torrent->addUrlSeeds(urls);
        return QJsonValue();
    });
    registry.add(u"editWebSeed"_s, [](const QJsonObject &args)
    {
        BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        const QUrl origUrl = validateWebSeed(argString(args, u"origUrl"_s));
        const QUrl newUrl = validateWebSeed(argString(args, u"newUrl"_s));
        if (newUrl != origUrl)
        {
            if (!torrent->urlSeeds().contains(origUrl))
                throwConflict(QCoreApplication::translate("TorrentsController", "\"%1\" is not an existing URL").arg(origUrl.toString()));
            torrent->removeUrlSeeds({origUrl});
            torrent->addUrlSeeds({newUrl});
        }
        return QJsonValue();
    });
    registry.add(u"removeWebSeeds"_s, [](const QJsonObject &args)
    {
        BitTorrent::Torrent *torrent = requireTorrent(argString(args, u"hash"_s));
        QList<QUrl> urls;
        for (const QString &url : asConst(argStringList(args, u"urls"_s)))
            urls.append(validateWebSeed(url));
        torrent->removeUrlSeeds(urls);
        return QJsonValue();
    });

    // ---- Categories and tags ---------------------------------------------
    registry.add(u"categories"_s, [](const QJsonObject &)
    {
        const auto *session = BitTorrent::Session::instance();
        QJsonArray result;
        for (const QString &name : asConst(session->categories()))
            result.append(categoryJson(name, session->categoryOptions(name)));
        return result;
    });
    registry.add(u"createCategory"_s, [](const QJsonObject &args)
    {
        const QJsonObject category = argObject(args, u"category"_s);
        const QString name = argString(category, u"name"_s);
        if (name.isEmpty())
            throwInvalid(QCoreApplication::translate("TorrentsController", "Category cannot be empty"));
        if (!BitTorrent::Session::isValidCategoryName(name))
            throwConflict(QCoreApplication::translate("TorrentsController", "Incorrect category name"));
        if (!BitTorrent::Session::instance()->addCategory(name, parseCategoryOptions(category)))
            throwConflict(QCoreApplication::translate("TorrentsController", "Unable to create category"));
        return QJsonValue();
    });
    registry.add(u"editCategory"_s, [](const QJsonObject &args)
    {
        const QJsonObject category = argObject(args, u"category"_s);
        const QString name = argString(category, u"name"_s);
        if (!BitTorrent::Session::instance()->setCategoryOptions(name, parseCategoryOptions(category)))
            throwNotFound(QCoreApplication::translate("TorrentsController", "Category does not exist"));
        return QJsonValue();
    });
    registry.add(u"removeCategories"_s, [](const QJsonObject &args)
    {
        for (const QString &name : asConst(argStringList(args, u"names"_s)))
            BitTorrent::Session::instance()->removeCategory(name);
        return QJsonValue();
    });
    registry.add(u"setCategory"_s, [](const QJsonObject &args)
    {
        const QString category = argString(args, u"category"_s);
        forTorrents(args, [&category](BitTorrent::Torrent *t)
        {
            if (!t->setCategory(category))
                throwConflict(QCoreApplication::translate("TorrentsController", "Incorrect category name"));
        });
        return QJsonValue();
    });
    registry.add(u"tags"_s, [](const QJsonObject &)
    {
        QJsonArray result;
        for (const Tag &tag : asConst(BitTorrent::Session::instance()->tags()))
            result.append(tag.toString());
        return result;
    });
    registry.add(u"createTags"_s, [](const QJsonObject &args)
    {
        for (const QString &name : asConst(argStringList(args, u"tags"_s)))
        {
            const Tag tag {name.trimmed()};
            if (!tag.isValid())
                throwInvalid(QCoreApplication::translate("TorrentsController", "Tag name: '%1' is invalid").arg(name));
            BitTorrent::Session::instance()->addTag(tag);
        }
        return QJsonValue();
    });
    registry.add(u"deleteTags"_s, [](const QJsonObject &args)
    {
        for (const QString &name : asConst(argStringList(args, u"tags"_s)))
            BitTorrent::Session::instance()->removeTag(Tag(name.trimmed()));
        return QJsonValue();
    });
    registry.add(u"addTags"_s, [](const QJsonObject &args)
    {
        const QStringList tags = argStringList(args, u"tags"_s);
        forTorrents(args, [&tags](BitTorrent::Torrent *t)
        {
            for (const QString &name : tags)
            {
                const Tag tag {name.trimmed()};
                if (tag.isValid())
                    t->addTag(tag);
            }
        });
        return QJsonValue();
    });
    registry.add(u"removeTags"_s, [](const QJsonObject &args)
    {
        const QStringList tags = argStringList(args, u"tags"_s);
        forTorrents(args, [&tags](BitTorrent::Torrent *t)
        {
            if (tags.isEmpty())
            {
                t->removeAllTags();
                return;
            }
            for (const QString &name : tags)
                t->removeTag(Tag(name.trimmed()));
        });
        return QJsonValue();
    });

    // Extra trackers of torrents that were not in the session yet when added.
    QObject::connect(BitTorrent::Session::instance(), &BitTorrent::Session::torrentAdded, CoreHost::instance()
            , [](BitTorrent::Torrent *torrent)
    {
        if (pendingExtras().isEmpty())
            return;
        const PendingExtras extras = pendingExtras().take(torrent->id());
        if (!extras.trackers.isEmpty())
            torrent->addTrackers(extras.trackers);
        if (!extras.urlSeeds.isEmpty())
            torrent->addUrlSeeds(extras.urlSeeds);
    });
}
