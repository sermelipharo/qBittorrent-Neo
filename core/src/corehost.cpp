/*
 * qBittorrent Neo — owner of the bridge state on the core thread.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "corehost.h"

#include <algorithm>

#include <QDateTime>

#include "base/bittorrent/session.h"
#include "base/bittorrent/sessionstatus.h"
#include "base/global.h"
#include "addmanager.h"
#include "eventhub.h"
#include "maindata.h"
#include "neoapplication.h"

namespace
{
    Neo::CoreHost *g_instance = nullptr;

    quint32 clampRate(const qint64 value)
    {
        return static_cast<quint32>(std::clamp<qint64>(value, 0, std::numeric_limits<quint32>::max()));
    }
}

namespace Neo
{
    void SpeedHistory::record(const qint64 timestampMs, const std::array<quint32, VALUE_COUNT> &values)
    {
        const qint64 oldestFineMs = timestampMs - (FINE_SPAN_SECS * 1000);
        while (!m_fine.isEmpty() && ((m_fine.size() >= FINE_CAPACITY) || (m_fine.first().timestampMs < oldestFineMs)))
            m_fine.removeFirst();
        m_fine.append({timestampMs, values});

        const qint64 bucket = timestampMs / (COARSE_STEP_SECS * 1000);
        if (bucket != m_coarseBucket)
        {
            flushCoarse();
            m_coarseBucket = bucket;
        }
        for (int i = 0; i < VALUE_COUNT; ++i)
            m_coarseSum[i] += values[i];
        ++m_coarseCount;
        m_coarseLastMs = timestampMs;
    }

    void SpeedHistory::flushCoarse()
    {
        if (m_coarseCount == 0)
            return;
        Sample average {m_coarseLastMs, {}};
        for (int i = 0; i < VALUE_COUNT; ++i)
            average.values[i] = static_cast<quint32>(m_coarseSum[i] / m_coarseCount);
        if (m_coarse.size() >= COARSE_CAPACITY)
            m_coarse.removeFirst();
        m_coarse.append(average);
        m_coarseSum = {};
        m_coarseCount = 0;
    }

    QJsonArray SpeedHistory::history(const int seconds) const
    {
        const bool useFine = (seconds <= FINE_SPAN_SECS) || m_coarse.isEmpty();
        const QList<Sample> &source = useFine ? m_fine : m_coarse;
        const qint64 resolution = useFine ? 1 : COARSE_STEP_SECS;
        // Bucket width in seconds: ~600 points at most.
        qint64 bucket = std::max<qint64>(resolution, (seconds + 599) / 600);
        bucket = ((bucket + resolution - 1) / resolution) * resolution;

        QJsonArray result;
        if (source.isEmpty())
            return result;

        const qint64 newestMs = source.last().timestampMs;
        const qint64 oldestMs = newestMs - (static_cast<qint64>(seconds) * 1000);

        std::array<quint64, VALUE_COUNT> sums {};
        int count = 0;
        qint64 currentBucket = -1;
        qint64 lastTs = 0;
        const auto flush = [&]
        {
            if (count == 0)
                return;
            const auto avg = [&](const int i) { return static_cast<qint64>(sums[i] / count); };
            result.append(QJsonObject {
                {u"timestampMs"_s, lastTs},
                {u"upload"_s, avg(0)},
                {u"download"_s, avg(1)},
                {u"payloadUpload"_s, avg(2)},
                {u"payloadDownload"_s, avg(3)},
                {u"overheadUpload"_s, avg(4)},
                {u"overheadDownload"_s, avg(5)},
                {u"dhtUpload"_s, avg(6)},
                {u"dhtDownload"_s, avg(7)},
                {u"trackerUpload"_s, avg(8)},
                {u"trackerDownload"_s, avg(9)}
            });
            sums = {};
            count = 0;
        };

        for (const Sample &sample : source)
        {
            if (sample.timestampMs <= oldestMs)
                continue;
            const qint64 bucketIndex = (sample.timestampMs / 1000) / bucket;
            if (bucketIndex != currentBucket)
            {
                flush();
                currentBucket = bucketIndex;
            }
            for (int i = 0; i < VALUE_COUNT; ++i)
                sums[i] += sample.values[i];
            ++count;
            lastTs = sample.timestampMs;
        }
        flush();
        return result;
    }

    CoreHost::CoreHost(NeoApplication *app, EventHub *events)
        : QObject(nullptr)
        , m_app {app}
        , m_events {events}
        , m_mainData {new MainDataTracker(this)}
    {
        g_instance = this;

        m_events->attachLogger();
        connect(m_app, &NeoApplication::componentsReady, this, &CoreHost::onComponentsReady);
        m_app->startComponents();

        registerAppApi(m_registry);
        registerCreatorApi(m_registry);
        registerLogApi(m_registry);
        registerPreferencesApi(m_registry);
        registerRssApi(m_registry);
        registerSearchApi(m_registry);
        registerTorrentsApi(m_registry);
        registerTransferApi(m_registry);

        m_events->attachSession();
        m_mainData->attachSession();

        // Sampled when the session publishes new statistics (no timer of its own).
        connect(BitTorrent::Session::instance(), &BitTorrent::Session::statsUpdated, this, &CoreHost::sampleSpeed);
    }

    CoreHost::~CoreHost()
    {
        cancelAll();
        if (g_instance == this)
            g_instance = nullptr;
    }

    CoreHost *CoreHost::instance()
    {
        return g_instance;
    }

    NeoApplication *CoreHost::app() const
    {
        return m_app;
    }

    EventHub *CoreHost::events() const
    {
        return m_events;
    }

    MainDataTracker *CoreHost::mainData() const
    {
        return m_mainData;
    }

    NeoAddTorrentManager *CoreHost::addManager() const
    {
        return static_cast<NeoAddTorrentManager *>(m_app->addTorrentManager());
    }

    bool CoreHost::isReady() const
    {
        return m_app->isComponentsReady();
    }

    void CoreHost::whenReady(std::function<void ()> fn)
    {
        if (isReady())
            fn();
        else
            m_readyQueue.append(std::move(fn));
    }

    void CoreHost::onComponentsReady()
    {
        m_events->attachComponents(addManager());
        const QList<std::function<void ()>> queue = std::exchange(m_readyQueue, {});
        for (const std::function<void ()> &fn : queue)
            fn();
    }

    void CoreHost::dispatch(const QString &method, const QJsonObject &args, const Reply &reply)
    {
        // Forget completed requests.
        for (auto it = m_pending.begin(); it != m_pending.end();)
            it = it.value().isDone() ? m_pending.erase(it) : std::next(it);

        m_registry.dispatch(method, args, reply);
        if (!reply.isDone())
            m_pending.insert(reply.id(), reply);
    }

    void CoreHost::cancel(const quint64 requestId)
    {
        const Reply reply = m_pending.take(requestId);
        reply.cancel();
    }

    void CoreHost::cancelAll()
    {
        const QHash<quint64, Reply> pending = std::exchange(m_pending, {});
        for (const Reply &reply : pending)
            reply.cancel();
    }

    const SpeedHistory &CoreHost::speedHistory() const
    {
        return m_speedHistory;
    }

    qint64 CoreHost::logClearedId() const
    {
        return m_logClearedId;
    }

    void CoreHost::setLogClearedId(const qint64 id)
    {
        m_logClearedId = id;
    }

    void CoreHost::sampleSpeed()
    {
        const auto *session = BitTorrent::Session::instance();
        if (!session)
            return;

        const BitTorrent::SessionStatus &status = session->status();
        m_speedHistory.record(QDateTime::currentMSecsSinceEpoch(), {
            clampRate(status.uploadRate),
            clampRate(status.downloadRate),
            clampRate(status.payloadUploadRate),
            clampRate(status.payloadDownloadRate),
            clampRate(status.ipOverheadUploadRate),
            clampRate(status.ipOverheadDownloadRate),
            clampRate(status.dhtUploadRate),
            clampRate(status.dhtDownloadRate),
            clampRate(status.trackerUploadRate),
            clampRate(status.trackerDownloadRate)
        });
    }
}
