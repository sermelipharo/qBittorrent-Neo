/*
 * qBittorrent Neo — conversions of "Add torrent" options.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "params.h"

#include <QJsonArray>

#include "base/global.h"
#include "base/tagset.h"
#include "jsonutil.h"
#include "maindata.h"

namespace Neo
{
    QString contentLayoutName(const BitTorrent::TorrentContentLayout layout)
    {
        switch (layout)
        {
        case BitTorrent::TorrentContentLayout::Subfolder:
            return u"subfolder"_s;
        case BitTorrent::TorrentContentLayout::NoSubfolder:
            return u"noSubfolder"_s;
        default:
            return u"original"_s;
        }
    }

    BitTorrent::TorrentContentLayout parseContentLayout(const QString &name)
    {
        if (name == u"subfolder")
            return BitTorrent::TorrentContentLayout::Subfolder;
        if (name == u"noSubfolder")
            return BitTorrent::TorrentContentLayout::NoSubfolder;
        return BitTorrent::TorrentContentLayout::Original;
    }

    QJsonObject paramsTemplateJson(const BitTorrent::AddTorrentParams &params)
    {
        QJsonArray tags;
        for (const Tag &tag : asConst(params.tags))
            tags.append(tag.toString());

        QJsonObject json {
            {u"category"_s, params.category},
            {u"tags"_s, tags},
            {u"savePath"_s, params.savePath.toString()},
            {u"downloadPath"_s, params.downloadPath.toString()},
            {u"skipChecking"_s, params.skipChecking},
            {u"uploadLimit"_s, params.uploadLimit},
            {u"downloadLimit"_s, params.downloadLimit},
            {u"ratioLimit"_s, params.ratioLimit},
            {u"seedingTimeLimit"_s, params.seedingTimeLimit},
            {u"inactiveSeedingTimeLimit"_s, params.inactiveSeedingTimeLimit}
        };
        if (params.useDownloadPath)
            json[u"useDownloadPath"_s] = *params.useDownloadPath;
        if (params.useAutoTMM)
            json[u"autoTmm"_s] = *params.useAutoTMM;
        if (params.addStopped)
            json[u"stopped"_s] = *params.addStopped;
        if (params.stopCondition)
            json[u"stopCondition"_s] = stopConditionName(*params.stopCondition);
        if (params.addToQueueTop)
            json[u"addToQueueTop"_s] = *params.addToQueueTop;
        if (params.contentLayout)
            json[u"contentLayout"_s] = contentLayoutName(*params.contentLayout);
        return json;
    }

    BitTorrent::AddTorrentParams parseParamsTemplate(const QJsonObject &json)
    {
        BitTorrent::AddTorrentParams params;
        params.category = argString(json, u"category"_s);
        for (const QString &name : asConst(argStringList(json, u"tags"_s)))
        {
            const Tag tag {name};
            if (tag.isValid())
                params.tags.insert(tag);
        }
        params.savePath = Path(argString(json, u"savePath"_s));
        params.downloadPath = Path(argString(json, u"downloadPath"_s));
        params.useDownloadPath = argOptBool(json, u"useDownloadPath"_s);
        params.useAutoTMM = argOptBool(json, u"autoTmm"_s);
        params.addStopped = argOptBool(json, u"stopped"_s);
        if (const auto condition = argOptString(json, u"stopCondition"_s))
            params.stopCondition = parseStopCondition(*condition);
        params.skipChecking = argBool(json, u"skipChecking"_s);
        params.addToQueueTop = argOptBool(json, u"addToQueueTop"_s);
        if (const auto layout = argOptString(json, u"contentLayout"_s))
            params.contentLayout = parseContentLayout(*layout);
        params.uploadLimit = static_cast<int>(argInt(json, u"uploadLimit"_s, -1));
        params.downloadLimit = static_cast<int>(argInt(json, u"downloadLimit"_s, -1));
        params.ratioLimit = argDouble(json, u"ratioLimit"_s, BitTorrent::DEFAULT_RATIO_LIMIT);
        params.seedingTimeLimit = static_cast<int>(argInt(json, u"seedingTimeLimit"_s, BitTorrent::DEFAULT_SEEDING_TIME_LIMIT));
        params.inactiveSeedingTimeLimit = static_cast<int>(argInt(json, u"inactiveSeedingTimeLimit"_s, BitTorrent::DEFAULT_SEEDING_TIME_LIMIT));
        return params;
    }
}
