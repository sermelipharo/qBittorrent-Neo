/*
 * qBittorrent Neo — request dispatch on the core thread.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <atomic>
#include <functional>
#include <memory>
#include <mutex>

#include <QHash>
#include <QJsonObject>
#include <QJsonValue>
#include <QString>

#include "qbtneo.h"
#include "jsonutil.h"

namespace Neo
{
    // One pending request. Completing it calls the C reply callback once;
    // later completions are ignored. Copies share the same request.
    class Reply
    {
    public:
        Reply() = default;
        Reply(quint64 id, qbtn_reply_fn fn, void *context);

        quint64 id() const;
        bool isDone() const;

        void ok(const QJsonValue &value = QJsonValue::Null) const;
        void okRaw(const QByteArray &json) const;
        void fail(ErrorKind kind, const QString &message) const;
        void fail(const ApiError &error) const;

        // Called (on the core thread) if the request is cancelled before it
        // completes; the reply is then completed with QBTN_CANCELLED.
        void setCancelHandler(std::function<void ()> handler) const;
        void cancel() const;

        bool operator==(const Reply &other) const { return m_state == other.m_state; }

    private:
        struct State
        {
            quint64 id = 0;
            qbtn_reply_fn fn = nullptr;
            void *context = nullptr;
            std::atomic_bool done = false;
            std::mutex mutex;
            std::function<void ()> cancelHandler;

            // Guarantees the "called exactly once" contract of qbtn_core_call
            // even if a queued request is dropped while the core stops.
            ~State()
            {
                if (!done.load() && fn)
                    fn(context, QBTN_CANCELLED, "cancelled", 9);
            }
        };

        void complete(int32_t status, const QByteArray &data) const;

        std::shared_ptr<State> m_state;
    };

    // A handler either returns a value (synchronous) or completes `reply`
    // later (asynchronous). Handlers run on the core thread and may throw
    // ApiError.
    using SyncHandler = std::function<QJsonValue (const QJsonObject &args)>;
    using AsyncHandler = std::function<void (const QJsonObject &args, const Reply &reply)>;

    class Registry
    {
    public:
        void add(const QString &method, SyncHandler handler);
        void addAsync(const QString &method, AsyncHandler handler);

        void dispatch(const QString &method, const QJsonObject &args, const Reply &reply) const;

    private:
        QHash<QString, AsyncHandler> m_handlers;
    };

    // Implemented by api_*.cpp.
    void registerAppApi(Registry &registry);
    void registerCreatorApi(Registry &registry);
    void registerLogApi(Registry &registry);
    void registerPreferencesApi(Registry &registry);
    void registerRssApi(Registry &registry);
    void registerSearchApi(Registry &registry);
    void registerTorrentsApi(Registry &registry);
    void registerTransferApi(Registry &registry);
}
