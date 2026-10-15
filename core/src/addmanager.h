/*
 * qBittorrent Neo — adding torrents on behalf of the app.
 *
 * Extends qBittorrent's AddTorrentManager (download of .torrent URLs,
 * auto-deletion of added .torrent files, duplicate handling) with the
 * request/reply flow of the bridge: the reply carries the torrent hash or
 * an error, and metadata fetched for the "Add new torrent" dialog is reused
 * when the magnet link is finally added.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <memory>

#include <QHash>
#include <QList>
#include <QMultiHash>

#include "base/addtorrentmanager.h"
#include "base/bittorrent/addtorrentparams.h"
#include "base/bittorrent/infohash.h"
#include "base/bittorrent/torrentdescriptor.h"
#include "base/bittorrent/torrentinfo.h"
#include "registry.h"

class TorrentFileGuard;

namespace Neo
{
    class NeoAddTorrentManager final : public AddTorrentManager
    {
        Q_OBJECT
        Q_DISABLE_COPY_MOVE(NeoAddTorrentManager)

    public:
        NeoAddTorrentManager(IApplication *app, BitTorrent::Session *btSession, QObject *parent = nullptr);

        // `source` is a magnet URI, bare info hash, http(s)/file URL or path.
        void add(const QString &source, const BitTorrent::AddTorrentParams &params, const Reply &reply);
        void addData(const QByteArray &data, const BitTorrent::AddTorrentParams &params, const Reply &reply);

        // Descriptors with metadata fetched for the add dialog (bounded cache).
        void rememberMetadata(const BitTorrent::TorrentDescriptor &descriptor);
        std::optional<BitTorrent::TorrentDescriptor> fetchedMetadata(const BitTorrent::TorrentID &id) const;

    signals:
        void duplicateTorrent(const QString &hash, const QString &name, bool mergedTrackers);

    private:
        QString addDescriptor(const QString &source, BitTorrent::TorrentDescriptor descriptor
                , const BitTorrent::AddTorrentParams &params, std::shared_ptr<TorrentFileGuard> guard);
        void onTorrentAdded(const QString &source, BitTorrent::Torrent *torrent);
        void onAddTorrentFailed(const QString &source, const BitTorrent::AddTorrentError &reason);

        QMultiHash<QString, Reply> m_pendingUrls;
        QList<BitTorrent::TorrentDescriptor> m_fetchedMetadata;
    };
}
