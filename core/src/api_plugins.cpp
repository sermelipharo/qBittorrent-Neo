/*
 * qBittorrent Neo — Lua plugins (qBittorrent 5.3's PluginsEngine).
 *
 * The engine exists only while the "Enable plugins" switch is on
 * (NeoApplication::setPluginsEnabled). Install and uninstall are queued by
 * the engine and report through its signals; the handlers here wait for the
 * signal of their own request and reply with upstream's messages, like
 * qBittorrent's PluginsDialog shows them.
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <algorithm>

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QSet>

#include "base/global.h"
#include "base/path.h"
#include "base/plugins/pluginsengine.h"
#include "corehost.h"
#include "neoapplication.h"
#include "registry.h"

using namespace Neo;

namespace
{
    // Upstream reads plugin files up to this size (Plugin::load).
    const qint64 MAX_PLUGIN_FILE_SIZE = 1024 * 1024;

    // Requests waiting for an engine signal (core thread only). A second
    // request for the same file or ID is refused here: upstream would fail
    // it with a signal that the first request would take for its own.
    QSet<Path> g_pendingInstalls;
    QSet<QString> g_pendingUninstalls;

    QString engineTr(const char *text)
    {
        return QCoreApplication::translate("PluginsEngine", text);
    }

    PluginsEngine *requireEngine()
    {
        auto *engine = PluginsEngine::instance();
        if (!engine)
            throwConflict(QCoreApplication::translate("NeoApplication", "Plugins are turned off."));
        return engine;
    }

    PluginInfo requirePlugin(const PluginsEngine *engine, const QString &id)
    {
        const std::optional<PluginInfo> info = engine->pluginInfo(id);
        if (!info)
            throwNotFound(engineTr("Plugin '%1' is not installed.").arg(id));
        return *info;
    }

    Path pluginFile(const QString &id)
    {
        return NeoApplication::pluginsFolder() / Path(id + u".lua");
    }

    // PluginInfo provides ID, name, version, invocable and enabled; the file
    // details are read here. Upstream's engine has no metadata beyond NAME
    // and VERSION, no list of handlers and no activity counters, so those
    // fields of the app's record stay empty.
    QJsonObject pluginJson(const PluginInfo &info)
    {
        const Path file = pluginFile(info.id);
        const QFileInfo fileInfo {file.data()};
        QString sha256;
        if (fileInfo.isFile() && (fileInfo.size() <= MAX_PLUGIN_FILE_SIZE))
        {
            QFile f {file.data()};
            QCryptographicHash hash {QCryptographicHash::Sha256};
            if (f.open(QIODevice::ReadOnly) && hash.addData(&f))
                sha256 = QString::fromLatin1(hash.result().toHex());
        }
        return {
            {u"id"_s, info.id},
            {u"name"_s, info.name},
            {u"version"_s, info.version.toString()},
            {u"invocable"_s, info.invocable},
            {u"enabled"_s, info.enabled},
            {u"filePath"_s, file.toString()},
            {u"fileSize"_s, fileInfo.isFile() ? fileInfo.size() : 0},
            {u"sha256"_s, sha256}
        };
    }

    QJsonObject statusJson()
    {
        const NeoApplication *app = CoreHost::instance()->app();
        const auto *engine = PluginsEngine::instance();
        QList<PluginInfo> plugins;
        if (engine)
            plugins = engine->allPlugins().values();
        std::ranges::sort(plugins, {}, &PluginInfo::id);

        QJsonArray list;
        for (const PluginInfo &info : asConst(plugins))
            list.append(pluginJson(info));
        return {
            {u"running"_s, (engine != nullptr)},
            {u"folder"_s, NeoApplication::pluginsFolder().toString()},
            {u"plugins"_s, list},
            {u"problems"_s, QJsonArray::fromStringList(app->pluginsProblems())}
        };
    }

    // Installed files are made owner-only: QFile::copy keeps the source's
    // permissions, and a group/world-writable plugin file keeps the engine
    // from starting next time.
    void restrictPermissions(const Path &sourcePath)
    {
        const Path target = NeoApplication::pluginsFolder() / Path(sourcePath.filename());
        QFile::setPermissions(target.data(), (QFile::ReadOwner | QFile::WriteOwner));
    }

    void installPlugin(const QJsonObject &args, const Reply &reply)
    {
        auto *engine = requireEngine();

        const QString pathString = argString(args, u"path"_s);
        const Path path {pathString};
        // Local files only: an absolute file system path.
        if (pathString.isEmpty() || pathString.contains(u"://"_s) || !path.isAbsolute())
            throwInvalid(engineTr("'%1' is invalid plugin path. An absolute path is expected.").arg(pathString));
        if (!path.hasExtension(u".lua"))
            throwInvalid(QCoreApplication::translate("NeoApplication", "'%1' is not a plugin file name (expected <name>.lua).").arg(path.filename()));
        const QFileInfo fileInfo {path.data()};
        if (!fileInfo.isFile())
            throwNotFound(QCoreApplication::translate("NeoApplication", "'%1' is not a file.").arg(path.toString()));
        // Upstream removes the installed file before copying the new one, so
        // a file of the plugins folder itself would be deleted.
        if (path.parentPath() == NeoApplication::pluginsFolder())
            throwInvalid(QCoreApplication::translate("NeoApplication", "'%1' is already in the plugins folder.").arg(path.toString()));
        if (g_pendingInstalls.contains(path))
            throwConflict(engineTr("'%1' is already scheduled to install.").arg(path.toString()));

        // Completes the request from the engine's signals for this file; if
        // the engine is stopped first, the request fails.
        auto *waiter = new QObject(engine);
        g_pendingInstalls.insert(path);
        const auto finish = [waiter, path]
        {
            g_pendingInstalls.remove(path);
            waiter->deleteLater();
        };
        QObject::connect(waiter, &QObject::destroyed, CoreHost::instance(), [reply, path]
        {
            if (reply.isDone())
                return;
            g_pendingInstalls.remove(path);
            reply.fail(ErrorKind::Cancelled, QCoreApplication::translate("NeoApplication", "Plugins are turned off."));
        });
        QObject::connect(engine, &PluginsEngine::pluginInstalled, waiter
                , [reply, path, finish](const Path &pluginPath, const PluginInfo &info)
        {
            if (pluginPath != path)
                return;
            restrictPermissions(path);
            reply.ok(QJsonObject {{u"plugin"_s, pluginJson(info)}, {u"updated"_s, false}});
            finish();
        });
        QObject::connect(engine, &PluginsEngine::pluginUpdated, waiter
                , [reply, path, finish](const Path &pluginPath, const PluginInfo &oldInfo, const PluginInfo &newInfo)
        {
            if (pluginPath != path)
                return;
            restrictPermissions(path);
            reply.ok(QJsonObject {
                {u"plugin"_s, pluginJson(newInfo)},
                {u"updated"_s, true},
                {u"previousVersion"_s, oldInfo.version.toString()}
            });
            finish();
        });
        QObject::connect(engine, &PluginsEngine::pluginInstallationFailed, waiter
                , [reply, path, finish](const Path &pluginPath, const QString &reason)
        {
            if (pluginPath != path)
                return;
            reply.fail(ErrorKind::Other, reason);
            finish();
        });
        // A failed update is a Conflict, so the app shows qBittorrent's
        // "Couldn't update plugin" message.
        QObject::connect(engine, &PluginsEngine::pluginUpdateFailed, waiter
                , [reply, path, finish](const Path &pluginPath, const PluginInfo &, const PluginInfo &, const QString &reason)
        {
            if (pluginPath != path)
                return;
            reply.fail(ErrorKind::Conflict, reason);
            finish();
        });

        engine->installPlugin(path);
    }

    void uninstallPlugin(const QJsonObject &args, const Reply &reply)
    {
        auto *engine = requireEngine();
        const QString id = argString(args, u"id"_s);
        requirePlugin(engine, id);
        if (g_pendingUninstalls.contains(id))
            throwConflict(engineTr("Plugin '%1' is already scheduled to uninstall.").arg(id));

        auto *waiter = new QObject(engine);
        g_pendingUninstalls.insert(id);
        const auto finish = [waiter, id]
        {
            g_pendingUninstalls.remove(id);
            waiter->deleteLater();
        };
        QObject::connect(waiter, &QObject::destroyed, CoreHost::instance(), [reply, id]
        {
            if (reply.isDone())
                return;
            g_pendingUninstalls.remove(id);
            reply.fail(ErrorKind::Cancelled, QCoreApplication::translate("NeoApplication", "Plugins are turned off."));
        });
        QObject::connect(engine, &PluginsEngine::pluginUninstalled, waiter, [reply, id, finish](const QString &pluginID)
        {
            if (pluginID != id)
                return;
            reply.ok();
            finish();
        });
        QObject::connect(engine, &PluginsEngine::pluginUninstallationFailed, waiter
                , [reply, id, finish](const QString &pluginID, const QString &reason)
        {
            if (pluginID != id)
                return;
            reply.fail(ErrorKind::Io, reason);
            finish();
        });

        engine->uninstallPlugin(id);
    }
}

void Neo::registerPluginsApi(Registry &registry)
{
    registry.add(u"pluginsStatus"_s, [](const QJsonObject &)
    {
        return statusJson();
    });

    registry.addAsync(u"installPlugin"_s, installPlugin);
    registry.addAsync(u"uninstallPlugin"_s, uninstallPlugin);

    registry.add(u"setPluginEnabled"_s, [](const QJsonObject &args)
    {
        auto *engine = requireEngine();
        const QString id = argString(args, u"id"_s);
        requirePlugin(engine, id); // upstream asserts that the plugin exists
        engine->setPluginEnabled(id, argBool(args, u"enabled"_s));
        return QJsonValue();
    });

    // Runs the plugin's `invoke` synchronously on the core thread, as the
    // Plugins menu does in qBittorrent (limited to 1 s by upstream's hook).
    // Errors raised by the script are logged by the engine.
    registry.add(u"invokePlugin"_s, [](const QJsonObject &args)
    {
        auto *engine = requireEngine();
        const QString id = argString(args, u"id"_s);
        const PluginInfo info = requirePlugin(engine, id);
        if (!info.enabled)
            throwConflict(QCoreApplication::translate("NeoApplication", "Plugin '%1' is disabled.").arg(id));
        if (!info.invocable)
            throwConflict(QCoreApplication::translate("NeoApplication", "Plugin '%1' has no 'invoke' function.").arg(id));
        engine->invokePlugin(id);
        return QJsonValue();
    });
}
