/*
 * qBittorrent Neo — forwards core signals to the app as JSON events.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <QJsonObject>
#include <QObject>

#include "base/logger.h"
#include "qbtneo.h"

class QTimer;

namespace Neo
{
    class NeoAddTorrentManager;

    QString logLevelName(Log::MsgType type);
    QJsonObject logMessageJson(const Log::Msg &msg);

    // Events use the shape of the app's `CoreEvent` enum as encoded by
    // Swift's synthesized Codable: {"caseName": {"label": value}}.
    class EventHub final : public QObject
    {
        Q_OBJECT
        Q_DISABLE_COPY_MOVE(EventHub)

    public:
        EventHub(qbtn_event_fn fn, void *context, QObject *parent = nullptr);

        // Thread-safe.
        void post(const QString &name, const QJsonObject &values = {}) const;

        void attachLogger();
        void attachSession();
        void attachComponents(NeoAddTorrentManager *addManager);

        // Coalesces bursts of RSS changes into one "rssUpdated" event.
        void scheduleRssUpdate();

    private:
        qbtn_event_fn m_fn = nullptr;
        void *m_context = nullptr;
        QTimer *m_rssTimer = nullptr;
    };
}
