/*
 * qBittorrent Neo — execution log and peer log.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <algorithm>

#include <QJsonArray>

#include "base/global.h"
#include "base/logger.h"
#include "corehost.h"
#include "eventhub.h"
#include "registry.h"

using namespace Neo;

namespace
{
    Log::MsgTypes parseLevels(const QStringList &names)
    {
        if (names.isEmpty())
            return Log::MsgTypes(Log::ALL);

        Log::MsgTypes types;
        for (const QString &name : names)
        {
            if (name == u"normal")
                types |= Log::NORMAL;
            else if (name == u"info")
                types |= Log::INFO;
            else if (name == u"warning")
                types |= Log::WARNING;
            else if (name == u"critical")
                types |= Log::CRITICAL;
        }
        return types;
    }
}

void Neo::registerLogApi(Registry &registry)
{
    registry.add(u"mainLog"_s, [](const QJsonObject &args)
    {
        const qint64 after = std::max(argInt(args, u"lastKnownId"_s, -1), CoreHost::instance()->logClearedId());
        const Log::MsgTypes types = parseLevels(argStringList(args, u"levels"_s));
        QJsonArray result;
        for (const Log::Msg &msg : asConst(Logger::instance()->getMessages(static_cast<int>(after))))
        {
            if (types.testFlag(msg.type))
                result.append(logMessageJson(msg));
        }
        return result;
    });

    registry.add(u"peerLog"_s, [](const QJsonObject &args)
    {
        QJsonArray result;
        for (const Log::Peer &peer : asConst(Logger::instance()->getPeers(static_cast<int>(argInt(args, u"lastKnownId"_s, -1)))))
        {
            result.append(QJsonObject {
                {u"id"_s, peer.id},
                {u"ip"_s, peer.ip},
                {u"timestamp"_s, peer.timestamp * 1000},
                {u"blocked"_s, peer.blocked},
                {u"reason"_s, peer.reason}
            });
        }
        return result;
    });

    // qBittorrent's logger has no "clear"; hide what was logged so far.
    registry.add(u"clearLog"_s, [](const QJsonObject &)
    {
        const QList<Log::Msg> messages = Logger::instance()->getMessages();
        if (!messages.isEmpty())
            CoreHost::instance()->setLogClearedId(messages.last().id);
        return QJsonValue();
    });
}
