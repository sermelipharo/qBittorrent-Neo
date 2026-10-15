/*
 * qBittorrent Neo — request dispatch on the core thread.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "registry.h"

#include <QJsonArray>
#include <QJsonDocument>

#include "base/global.h"

namespace Neo
{
    Reply::Reply(const quint64 id, const qbtn_reply_fn fn, void *context)
        : m_state {std::make_shared<State>()}
    {
        m_state->id = id;
        m_state->fn = fn;
        m_state->context = context;
    }

    quint64 Reply::id() const
    {
        return m_state ? m_state->id : 0;
    }

    bool Reply::isDone() const
    {
        return !m_state || m_state->done.load();
    }

    void Reply::ok(const QJsonValue &value) const
    {
        QByteArray json;
        switch (value.type())
        {
        case QJsonValue::Object:
            json = QJsonDocument(value.toObject()).toJson(QJsonDocument::Compact);
            break;
        case QJsonValue::Array:
            json = QJsonDocument(value.toArray()).toJson(QJsonDocument::Compact);
            break;
        default:
            // Scalars: wrap in an array and strip the brackets.
            json = QJsonDocument(QJsonArray {value}).toJson(QJsonDocument::Compact);
            json = json.mid(1, json.size() - 2);
            break;
        }
        complete(QBTN_OK, json);
    }

    void Reply::okRaw(const QByteArray &json) const
    {
        complete(QBTN_OK, json);
    }

    void Reply::fail(const ErrorKind kind, const QString &message) const
    {
        complete(static_cast<int32_t>(kind), message.toUtf8());
    }

    void Reply::fail(const ApiError &error) const
    {
        fail(error.kind(), error.message());
    }

    void Reply::setCancelHandler(std::function<void ()> handler) const
    {
        if (!m_state)
            return;
        const std::lock_guard lock {m_state->mutex};
        m_state->cancelHandler = std::move(handler);
    }

    void Reply::cancel() const
    {
        if (!m_state || m_state->done.load())
            return;

        std::function<void ()> handler;
        {
            const std::lock_guard lock {m_state->mutex};
            handler = std::move(m_state->cancelHandler);
        }
        if (handler)
            handler();
        complete(QBTN_CANCELLED, QByteArrayLiteral("cancelled"));
    }

    void Reply::complete(const int32_t status, const QByteArray &data) const
    {
        if (!m_state || m_state->done.exchange(true))
            return;

        {
            const std::lock_guard lock {m_state->mutex};
            m_state->cancelHandler = nullptr;
        }
        if (m_state->fn)
            m_state->fn(m_state->context, status, data.constData(), static_cast<size_t>(data.size()));
    }

    void Registry::add(const QString &method, SyncHandler handler)
    {
        m_handlers.insert(method, [handler = std::move(handler)](const QJsonObject &args, const Reply &reply)
        {
            reply.ok(handler(args));
        });
    }

    void Registry::addAsync(const QString &method, AsyncHandler handler)
    {
        m_handlers.insert(method, std::move(handler));
    }

    void Registry::dispatch(const QString &method, const QJsonObject &args, const Reply &reply) const
    {
        const auto it = m_handlers.constFind(method);
        if (it == m_handlers.cend())
        {
            reply.fail(ErrorKind::Unsupported, u"Unknown core method: %1"_s.arg(method));
            return;
        }

        try
        {
            it.value()(args, reply);
        }
        catch (const ApiError &error)
        {
            reply.fail(error);
        }
        catch (const std::exception &error)
        {
            reply.fail(ErrorKind::Other, QString::fromUtf8(error.what()));
        }
    }
}
