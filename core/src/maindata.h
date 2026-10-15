/*
 * qBittorrent Neo — transfer-list data for the app (record-level diffs).
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <QHash>
#include <QJsonObject>
#include <QObject>
#include <QSet>
#include <QString>
#include <QStringList>

#include "base/bittorrent/sharelimits.h"
#include "base/bittorrent/torrent.h"

namespace BitTorrent
{
    struct CategoryOptions;
}

namespace Neo
{
    QString shareLimitActionName(BitTorrent::ShareLimitAction action);
    BitTorrent::ShareLimitAction parseShareLimitAction(const QString &name);
    QString torrentStateName(BitTorrent::TorrentState state);
    QString stopConditionName(BitTorrent::Torrent::StopCondition condition);
    BitTorrent::Torrent::StopCondition parseStopCondition(const QString &name);

    QJsonObject torrentInfoJson(const BitTorrent::Torrent &torrent);
    QJsonObject categoryJson(const QString &name, const BitTorrent::CategoryOptions &options);
    BitTorrent::CategoryOptions parseCategoryOptions(const QJsonObject &json);
    QJsonObject serverStateJson();

    // Remembers what was last sent and returns the differences
    // (`MainDataUpdate`).
    class MainDataTracker final : public QObject
    {
        Q_OBJECT
        Q_DISABLE_COPY_MOVE(MainDataTracker)

    public:
        explicit MainDataTracker(QObject *parent = nullptr);

        void attachSession();
        QJsonObject sync();
        void reset();

    private:
        QHash<QString, QStringList> trackerMap();

        qint64 m_rid = 0;
        bool m_sent = false;
        QHash<QString, QJsonObject> m_torrents;
        QHash<QString, QJsonObject> m_categories;
        QSet<QString> m_tags;
        QHash<QString, QStringList> m_trackers;
        QHash<QString, QStringList> m_trackerCache;
        bool m_trackersDirty = true;
    };
}
