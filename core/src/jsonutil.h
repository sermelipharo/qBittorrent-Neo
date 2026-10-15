/*
 * qBittorrent Neo — JSON helpers shared by the bridge handlers.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <exception>
#include <optional>

#include <QDateTime>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include <QList>
#include <QString>
#include <QStringList>

namespace BitTorrent
{
    class Torrent;
    class TorrentID;
}

namespace Neo
{
    // Matches QBTN_ERR_* in qbtneo.h.
    enum class ErrorKind : int
    {
        NotFound = 1,
        InvalidArgument = 2,
        Conflict = 3,
        Io = 4,
        Network = 5,
        Engine = 6,
        Unsupported = 7,
        Other = 8,
        Cancelled = 9
    };

    // Thrown by handlers; the dispatcher turns it into an error reply.
    class ApiError final : public std::exception
    {
    public:
        ApiError(ErrorKind kind, QString message)
            : m_kind {kind}
            , m_message {std::move(message)}
            , m_utf8 {m_message.toUtf8()}
        {
        }

        ErrorKind kind() const { return m_kind; }
        const QString &message() const { return m_message; }
        const char *what() const noexcept override { return m_utf8.constData(); }

    private:
        ErrorKind m_kind;
        QString m_message;
        QByteArray m_utf8;
    };

    [[noreturn]] void throwNotFound(const QString &message);
    [[noreturn]] void throwInvalid(const QString &message);
    [[noreturn]] void throwConflict(const QString &message);
    [[noreturn]] void throwIo(const QString &message);
    [[noreturn]] void throwUnsupported(const QString &message);
    [[noreturn]] void throwOther(const QString &message);

    // Argument accessors. Missing keys yield the fallback; wrong types are
    // treated as missing.
    QString argString(const QJsonObject &args, const QString &key, const QString &fallback = {});
    std::optional<QString> argOptString(const QJsonObject &args, const QString &key);
    qint64 argInt(const QJsonObject &args, const QString &key, qint64 fallback = 0);
    std::optional<qint64> argOptInt(const QJsonObject &args, const QString &key);
    double argDouble(const QJsonObject &args, const QString &key, double fallback = 0);
    std::optional<double> argOptDouble(const QJsonObject &args, const QString &key);
    bool argBool(const QJsonObject &args, const QString &key, bool fallback = false);
    std::optional<bool> argOptBool(const QJsonObject &args, const QString &key);
    QStringList argStringList(const QJsonObject &args, const QString &key);
    QList<qint64> argIntList(const QJsonObject &args, const QString &key);
    QJsonObject argObject(const QJsonObject &args, const QString &key);

    QJsonArray toJsonArray(const QStringList &list);

    // Unix seconds, or `fallback` for an invalid date.
    qint64 toSecs(const QDateTime &dateTime, qint64 fallback = -1);

    // Encodes an enum with associated values as Swift's synthesized Codable
    // does: {"caseName": {"label": value, ...}}.
    QJsonObject swiftCase(const QString &name, const QJsonObject &values = {});

    // Torrent lookup by the WebAPI-style hash (TorrentID string).
    BitTorrent::Torrent *findTorrent(const QString &hash);
    BitTorrent::Torrent *requireTorrent(const QString &hash);
    // Unknown hashes are skipped (like qBittorrent's WebAPI).
    QList<BitTorrent::Torrent *> torrentsFor(const QStringList &hashes);
    QList<BitTorrent::TorrentID> idsFor(const QStringList &hashes);
}
