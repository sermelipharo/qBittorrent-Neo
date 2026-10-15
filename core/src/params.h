/*
 * qBittorrent Neo — conversions of "Add torrent" options shared by watched
 * folders, RSS rules and the add calls.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <QJsonObject>

#include "base/bittorrent/addtorrentparams.h"
#include "base/bittorrent/torrentcontentlayout.h"

namespace Neo
{
    QString contentLayoutName(BitTorrent::TorrentContentLayout layout);
    BitTorrent::TorrentContentLayout parseContentLayout(const QString &name);

    // `TorrentParamsTemplate` record <-> qBittorrent's AddTorrentParams.
    QJsonObject paramsTemplateJson(const BitTorrent::AddTorrentParams &params);
    BitTorrent::AddTorrentParams parseParamsTemplate(const QJsonObject &json);
}
