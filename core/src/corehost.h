/*
 * qBittorrent Neo — owner of the bridge state on the core thread.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <array>
#include <functional>

#include <QHash>
#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QObject>

#include "registry.h"

namespace Neo
{
    class EventHub;
    class MainDataTracker;
    class NeoAddTorrentManager;
    class NeoApplication;

    // Session-wide speed samples for the "Speed" tab, taken whenever the
    // session publishes new statistics (every refresh interval, 1.5 s by
    // default, like qBittorrent's speed graph): every sample of the last 30
    // minutes and 30 s averages for the last 24 hours (~230 KB).
    class SpeedHistory
    {
    public:
        static constexpr int VALUE_COUNT = 10;
        struct Sample
        {
            qint64 timestampMs = 0;
            std::array<quint32, VALUE_COUNT> values {};
        };

        void record(qint64 timestampMs, const std::array<quint32, VALUE_COUNT> &values);
        // Averages over buckets so that at most ~600 samples are returned.
        QJsonArray history(int seconds) const;

    private:
        static constexpr qint64 FINE_SPAN_SECS = 30 * 60;
        // Bounds memory for very short refresh intervals (30 min at >= 250 ms).
        static constexpr qsizetype FINE_CAPACITY = 4 * FINE_SPAN_SECS;
        static constexpr qint64 COARSE_STEP_SECS = 30;
        static constexpr qsizetype COARSE_CAPACITY = 24 * 60 * 60 / COARSE_STEP_SECS;

        void flushCoarse();

        QList<Sample> m_fine;
        QList<Sample> m_coarse;
        std::array<quint64, VALUE_COUNT> m_coarseSum {};
        int m_coarseCount = 0;
        qint64 m_coarseBucket = -1;
        qint64 m_coarseLastMs = 0;
    };

    class CoreHost final : public QObject
    {
        Q_OBJECT
        Q_DISABLE_COPY_MOVE(CoreHost)

    public:
        CoreHost(NeoApplication *app, EventHub *events);
        ~CoreHost() override;

        static CoreHost *instance();

        NeoApplication *app() const;
        EventHub *events() const;
        MainDataTracker *mainData() const;
        // Null until the session has restored its torrents.
        NeoAddTorrentManager *addManager() const;
        bool isReady() const;

        // Runs `fn` now if the components are ready, otherwise once they are.
        void whenReady(std::function<void ()> fn);

        // Core thread only.
        void dispatch(const QString &method, const QJsonObject &args, const Reply &reply);
        void cancel(quint64 requestId);
        void cancelAll();

        const SpeedHistory &speedHistory() const;
        qint64 logClearedId() const;
        void setLogClearedId(qint64 id);

    private:
        void onComponentsReady();
        void sampleSpeed();

        NeoApplication *m_app = nullptr;
        EventHub *m_events = nullptr;
        MainDataTracker *m_mainData = nullptr;
        Registry m_registry;
        QHash<quint64, Reply> m_pending;
        QList<std::function<void ()>> m_readyQueue;
        SpeedHistory m_speedHistory;
        qint64 m_logClearedId = -1;
    };
}
