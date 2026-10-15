/*
 * qBittorrent Neo — JSON helpers shared by the bridge handlers.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "jsonutil.h"

#include "base/bittorrent/infohash.h"
#include "base/bittorrent/session.h"
#include "base/bittorrent/torrent.h"
#include "base/global.h"

namespace Neo
{
    void throwNotFound(const QString &message) { throw ApiError(ErrorKind::NotFound, message); }
    void throwInvalid(const QString &message) { throw ApiError(ErrorKind::InvalidArgument, message); }
    void throwConflict(const QString &message) { throw ApiError(ErrorKind::Conflict, message); }
    void throwIo(const QString &message) { throw ApiError(ErrorKind::Io, message); }
    void throwUnsupported(const QString &message) { throw ApiError(ErrorKind::Unsupported, message); }
    void throwOther(const QString &message) { throw ApiError(ErrorKind::Other, message); }

    QString argString(const QJsonObject &args, const QString &key, const QString &fallback)
    {
        const QJsonValue value = args.value(key);
        return value.isString() ? value.toString() : fallback;
    }

    std::optional<QString> argOptString(const QJsonObject &args, const QString &key)
    {
        const QJsonValue value = args.value(key);
        if (!value.isString())
            return std::nullopt;
        return value.toString();
    }

    qint64 argInt(const QJsonObject &args, const QString &key, const qint64 fallback)
    {
        return argOptInt(args, key).value_or(fallback);
    }

    std::optional<qint64> argOptInt(const QJsonObject &args, const QString &key)
    {
        const QJsonValue value = args.value(key);
        if (!value.isDouble())
            return std::nullopt;
        return value.toInteger(static_cast<qint64>(value.toDouble()));
    }

    double argDouble(const QJsonObject &args, const QString &key, const double fallback)
    {
        return argOptDouble(args, key).value_or(fallback);
    }

    std::optional<double> argOptDouble(const QJsonObject &args, const QString &key)
    {
        const QJsonValue value = args.value(key);
        if (!value.isDouble())
            return std::nullopt;
        return value.toDouble();
    }

    bool argBool(const QJsonObject &args, const QString &key, const bool fallback)
    {
        return argOptBool(args, key).value_or(fallback);
    }

    std::optional<bool> argOptBool(const QJsonObject &args, const QString &key)
    {
        const QJsonValue value = args.value(key);
        if (!value.isBool())
            return std::nullopt;
        return value.toBool();
    }

    QStringList argStringList(const QJsonObject &args, const QString &key)
    {
        QStringList result;
        for (const QJsonValue &item : asConst(args.value(key).toArray()))
        {
            if (item.isString())
                result.append(item.toString());
        }
        return result;
    }

    QList<qint64> argIntList(const QJsonObject &args, const QString &key)
    {
        QList<qint64> result;
        for (const QJsonValue &item : asConst(args.value(key).toArray()))
        {
            if (item.isDouble())
                result.append(item.toInteger(static_cast<qint64>(item.toDouble())));
        }
        return result;
    }

    QJsonObject argObject(const QJsonObject &args, const QString &key)
    {
        return args.value(key).toObject();
    }

    QJsonArray toJsonArray(const QStringList &list)
    {
        return QJsonArray::fromStringList(list);
    }

    qint64 toSecs(const QDateTime &dateTime, const qint64 fallback)
    {
        return dateTime.isValid() ? dateTime.toSecsSinceEpoch() : fallback;
    }

    QJsonObject swiftCase(const QString &name, const QJsonObject &values)
    {
        return QJsonObject {{name, values}};
    }

    BitTorrent::Torrent *findTorrent(const QString &hash)
    {
        const auto id = BitTorrent::TorrentID::fromString(hash);
        if (!id.isValid())
            return nullptr;
        return BitTorrent::Session::instance()->getTorrent(id);
    }

    BitTorrent::Torrent *requireTorrent(const QString &hash)
    {
        BitTorrent::Torrent *torrent = findTorrent(hash);
        if (!torrent)
            throwNotFound(u"Torrent not found: %1"_s.arg(hash));
        return torrent;
    }

    QList<BitTorrent::Torrent *> torrentsFor(const QStringList &hashes)
    {
        QList<BitTorrent::Torrent *> result;
        if ((hashes.size() == 1) && (hashes[0] == u"all"))
            return BitTorrent::Session::instance()->torrents();

        result.reserve(hashes.size());
        for (const QString &hash : hashes)
        {
            if (BitTorrent::Torrent *torrent = findTorrent(hash))
                result.append(torrent);
        }
        return result;
    }

    QList<BitTorrent::TorrentID> idsFor(const QStringList &hashes)
    {
        QList<BitTorrent::TorrentID> result;
        for (const BitTorrent::Torrent *torrent : asConst(torrentsFor(hashes)))
            result.append(torrent->id());
        return result;
    }
}
