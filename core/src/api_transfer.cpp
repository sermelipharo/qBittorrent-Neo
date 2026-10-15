/*
 * qBittorrent Neo — global transfer state and speed limits.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <algorithm>
#include <climits>

#include "base/bittorrent/session.h"
#include "base/global.h"
#include "corehost.h"
#include "maindata.h"
#include "registry.h"

using namespace Neo;

namespace
{
    int toLimit(const qint64 value)
    {
        return static_cast<int>(std::clamp<qint64>(value, 0, INT_MAX));
    }
}

void Neo::registerTransferApi(Registry &registry)
{
    registry.add(u"serverState"_s, [](const QJsonObject &)
    {
        return serverStateJson();
    });
    registry.add(u"altSpeedLimitsEnabled"_s, [](const QJsonObject &)
    {
        return QJsonValue(BitTorrent::Session::instance()->isAltGlobalSpeedLimitEnabled());
    });
    registry.add(u"setAltSpeedLimitsEnabled"_s, [](const QJsonObject &args)
    {
        BitTorrent::Session::instance()->setAltGlobalSpeedLimitEnabled(argBool(args, u"enabled"_s));
        return QJsonValue();
    });
    // The limits currently in effect (regular or alternative), like the
    // speed-limit dialogs of qBittorrent's status bar.
    registry.add(u"globalDownloadLimit"_s, [](const QJsonObject &)
    {
        return QJsonValue(BitTorrent::Session::instance()->downloadSpeedLimit());
    });
    registry.add(u"setGlobalDownloadLimit"_s, [](const QJsonObject &args)
    {
        BitTorrent::Session::instance()->setDownloadSpeedLimit(toLimit(argInt(args, u"limit"_s)));
        return QJsonValue();
    });
    registry.add(u"globalUploadLimit"_s, [](const QJsonObject &)
    {
        return QJsonValue(BitTorrent::Session::instance()->uploadSpeedLimit());
    });
    registry.add(u"setGlobalUploadLimit"_s, [](const QJsonObject &args)
    {
        BitTorrent::Session::instance()->setUploadSpeedLimit(toLimit(argInt(args, u"limit"_s)));
        return QJsonValue();
    });
    registry.add(u"speedHistory"_s, [](const QJsonObject &args)
    {
        const int seconds = static_cast<int>(std::clamp<qint64>(argInt(args, u"seconds"_s, 300), 1, 24 * 60 * 60));
        return CoreHost::instance()->speedHistory().history(seconds);
    });
}
