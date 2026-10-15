/*
 * qBittorrent Neo — C interface: core thread, request queueing, shutdown.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "qbtneo.h"

#include <atomic>
#include <csignal>
#include <cstdlib>
#include <cstring>
#include <future>
#include <mutex>

#include <pthread.h>

#include <QJsonDocument>
#include <QJsonObject>
#include <QMetaObject>

#include "base/global.h"
#include "corehost.h"
#include "eventhub.h"
#include "neoapplication.h"
#include "registry.h"

struct qbtn_core
{
    pthread_t thread {};
    std::mutex mutex;
    Neo::NeoApplication *app = nullptr;  // set while the event loop runs
    Neo::CoreHost *host = nullptr;
    std::atomic<quint64> nextRequestId {1};

    Neo::StartupConfig config;
    qbtn_event_fn eventFn = nullptr;
    void *eventContext = nullptr;
    std::promise<QString> started;  // empty string: started
};

namespace
{
    // QCoreApplication keeps references to these for its whole lifetime.
    int g_argc = 1;
    char g_arg0[] = "qBittorrent Neo";
    char *g_argv[] = {g_arg0, nullptr};

    char *copyString(const QByteArray &data)
    {
        auto *result = static_cast<char *>(std::malloc(static_cast<size_t>(data.size()) + 1));
        if (result)
        {
            std::memcpy(result, data.constData(), static_cast<size_t>(data.size()));
            result[data.size()] = '\0';
        }
        return result;
    }

    void *coreThreadMain(void *arg)
    {
        auto *core = static_cast<qbtn_core *>(arg);
        bool startedReported = false;
        try
        {
            Neo::NeoApplication app(g_argc, g_argv, core->config);
            Neo::EventHub events(core->eventFn, core->eventContext);
            Neo::CoreHost host(&app, &events);
            {
                const std::lock_guard lock {core->mutex};
                core->app = &app;
                core->host = &host;
            }
            core->started.set_value({});
            startedReported = true;

            app.exec();

            {
                const std::lock_guard lock {core->mutex};
                core->app = nullptr;
                core->host = nullptr;
            }
            host.cancelAll();
            app.cleanup();
        }
        catch (const std::exception &error)
        {
            if (!startedReported)
                core->started.set_value(QString::fromUtf8(error.what()));
        }
        catch (...)
        {
            if (!startedReported)
                core->started.set_value(u"Unknown error while starting the core"_s);
        }

        const std::lock_guard lock {core->mutex};
        core->app = nullptr;
        core->host = nullptr;
        return nullptr;
    }
}

extern "C"
{
__attribute__((visibility("default")))
qbtn_core *qbtn_core_start(const char *configJson, const size_t configLength
        , const qbtn_event_fn onEvent, void *eventContext, char **error)
{
    std::signal(SIGPIPE, SIG_IGN);

    // Like qBittorrent's main(): let the search engine find a Homebrew Python.
    const QByteArray path = "/opt/homebrew/bin:/usr/local/bin:" + qgetenv("PATH");
    qputenv("PATH", path);

    const QJsonObject config = QJsonDocument::fromJson(QByteArray(configJson, static_cast<qsizetype>(configLength))).object();

    auto *core = new qbtn_core;
    core->config.profileDir = Path(config.value(u"profileDir").toString());
    core->config.webUIPortOverride = config.value(u"webuiPortOverride").toInt();
    core->config.frontEnd = config.value(u"frontEnd").toString();
    core->eventFn = onEvent;
    core->eventContext = eventContext;

    std::future<QString> started = core->started.get_future();

    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, 8 * 1024 * 1024);
    const int rc = pthread_create(&core->thread, &attr, coreThreadMain, core);
    pthread_attr_destroy(&attr);
    if (rc != 0)
    {
        if (error)
            *error = copyString("Failed to create the core thread");
        delete core;
        return nullptr;
    }

    const QString startError = started.get();
    if (!startError.isEmpty())
    {
        pthread_join(core->thread, nullptr);
        if (error)
            *error = copyString(startError.toUtf8());
        delete core;
        return nullptr;
    }

    return core;
}

__attribute__((visibility("default")))
uint64_t qbtn_core_call(qbtn_core *core, const char *method, const char *argsJson, const size_t argsLength
        , const qbtn_reply_fn reply, void *context)
{
    const quint64 id = core->nextRequestId.fetch_add(1);
    const Neo::Reply pending {id, reply, context};

    QJsonParseError parseError;
    const QByteArray argsData = (argsLength > 0) ? QByteArray(argsJson, static_cast<qsizetype>(argsLength)) : QByteArrayLiteral("{}");
    const QJsonDocument doc = QJsonDocument::fromJson(argsData, &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject())
    {
        pending.fail(Neo::ErrorKind::InvalidArgument, u"Malformed request arguments"_s);
        return id;
    }

    const QString methodName = QString::fromUtf8(method);
    const std::lock_guard lock {core->mutex};
    if (!core->host)
    {
        pending.fail(Neo::ErrorKind::Cancelled, u"The core is not running"_s);
        return id;
    }

    // If the event is dropped (core stopping), the reply completes with
    // QBTN_CANCELLED when the last copy of `pending` is destroyed.
    Neo::CoreHost *host = core->host;
    QMetaObject::invokeMethod(host, [host, methodName, args = doc.object(), pending]
    {
        host->dispatch(methodName, args, pending);
    }, Qt::QueuedConnection);
    return id;
}

__attribute__((visibility("default")))
void qbtn_core_cancel(qbtn_core *core, const uint64_t requestId)
{
    const std::lock_guard lock {core->mutex};
    if (Neo::CoreHost *host = core->host)
        QMetaObject::invokeMethod(host, [host, requestId] { host->cancel(requestId); }, Qt::QueuedConnection);
}

__attribute__((visibility("default")))
void qbtn_core_shutdown(qbtn_core *core)
{
    if (!core)
        return;
    {
        const std::lock_guard lock {core->mutex};
        if (core->app)
            QMetaObject::invokeMethod(core->app, &QCoreApplication::quit, Qt::QueuedConnection);
    }
    pthread_join(core->thread, nullptr);
    delete core;
}

__attribute__((visibility("default")))
void qbtn_free(void *pointer)
{
    std::free(pointer);
}
}
