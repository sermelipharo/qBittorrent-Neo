/*
 * qBittorrent Neo — search engine (nova3 Python plugins) and search jobs.
 *
 * Semantics follow qBittorrent's search widgets and SearchController
 * (src/webui/api/searchcontroller.cpp).
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <memory>

#include <QJsonArray>
#include <QPointer>
#include <QTimer>

#include "base/global.h"
#include "base/search/searchdownloadhandler.h"
#include "base/search/searchhandler.h"
#include "base/search/searchpluginmanager.h"
#include "base/utils/foreignapps.h"
#include "addmanager.h"
#include "corehost.h"
#include "eventhub.h"
#include "jsonutil.h"
#include "registry.h"

using namespace Neo;

namespace
{
    const int MAX_CONCURRENT_SEARCHES = 5;

    // The plugin manager is created on first use (as in qBittorrent, where
    // the Search tab creates it); its changes are announced as events.
    SearchPluginManager *pluginManager()
    {
        static QPointer<SearchPluginManager> connected;
        auto *manager = SearchPluginManager::instance();
        if (connected == manager)
            return manager;
        connected = manager;
        const auto announce = [](const QString &message)
        {
            CoreHost::instance()->events()->post(u"searchPluginsUpdated"_s, {{u"message"_s, message}});
        };
        QObject::connect(manager, &SearchPluginManager::pluginInstalled, CoreHost::instance(), [announce](const QString &name)
        {
            announce(QCoreApplication::translate("PluginSelectDialog", "\"%1\" was successfully installed.").arg(name));
        });
        QObject::connect(manager, &SearchPluginManager::pluginInstallationFailed, CoreHost::instance(), [announce](const QString &name, const QString &reason)
        {
            announce(QCoreApplication::translate("PluginSelectDialog", "Couldn't install \"%1\" search engine plugin. %2").arg(name, reason));
        });
        QObject::connect(manager, &SearchPluginManager::pluginUpdated, CoreHost::instance(), [announce](const QString &name)
        {
            announce(QCoreApplication::translate("PluginSelectDialog", "\"%1\" was successfully updated.").arg(name));
        });
        QObject::connect(manager, &SearchPluginManager::pluginUpdateFailed, CoreHost::instance(), [announce](const QString &name, const QString &reason)
        {
            announce(QCoreApplication::translate("PluginSelectDialog", "Couldn't update \"%1\" search engine plugin. %2").arg(name, reason));
        });
        QObject::connect(manager, &SearchPluginManager::pluginUninstalled, CoreHost::instance(), [announce](const QString &name)
        {
            announce(QCoreApplication::translate("PluginSelectDialog", "\"%1\" was uninstalled.").arg(name));
        });
        return manager;
    }

    struct SearchJob
    {
        std::shared_ptr<SearchHandler> handler;
        QString pattern;
        QString outcome = u"ongoing"_s;
        QString error;
    };

    // Search jobs of this session, by id (deleted with the core host).
    class SearchJobs final : public QObject
    {
    public:
        using QObject::QObject;

        static SearchJobs *instance()
        {
            static QPointer<SearchJobs> jobs;
            if (!jobs)
                jobs = new SearchJobs(CoreHost::instance());
            return jobs;
        }

        qint64 start(const QString &pattern, const QString &category, const QStringList &plugins)
        {
            int active = 0;
            for (const SearchJob &job : asConst(m_jobs))
                active += job.handler->isActive();
            if (active >= MAX_CONCURRENT_SEARCHES)
                throwConflict(tr("Unable to create more than %1 concurrent searches.").arg(MAX_CONCURRENT_SEARCHES));

            const qint64 id = ++m_lastId;
            SearchJob job;
            job.pattern = pattern;
            job.handler.reset(pluginManager()->startSearch(pattern, category, plugins));
            SearchHandler *handler = job.handler.get();
            m_jobs.insert(id, job);

            const auto notify = [id] { CoreHost::instance()->events()->post(u"searchUpdated"_s, {{u"id"_s, id}}); };
            connect(handler, &SearchHandler::newSearchResults, this, notify);
            connect(handler, &SearchHandler::searchFinished, this, [this, id, notify](const bool cancelled)
            {
                if (auto it = m_jobs.find(id); it != m_jobs.end())
                    it->outcome = cancelled ? u"aborted"_s : (it->handler->results().isEmpty() ? u"noResults"_s : u"finished"_s);
                notify();
            });
            connect(handler, &SearchHandler::searchFailed, this, [this, id, notify](const QString &message)
            {
                if (auto it = m_jobs.find(id); it != m_jobs.end())
                {
                    it->outcome = u"error"_s;
                    it->error = message;
                }
                notify();
            });
            return id;
        }

        SearchJob &job(const qint64 id)
        {
            const auto it = m_jobs.find(id);
            if (it == m_jobs.end())
                throwNotFound(tr("No search job with id %1").arg(id));
            return it.value();
        }

        QList<qint64> ids() const { return m_jobs.keys(); }

        void remove(const qint64 id)
        {
            job(id).handler->cancelSearch();
            m_jobs.remove(id);
        }

    private:
        qint64 m_lastId = 0;
        QHash<qint64, SearchJob> m_jobs;
    };

    QJsonObject jobInfo(const qint64 id, const SearchJob &job)
    {
        return {
            {u"id"_s, id},
            {u"pattern"_s, job.pattern},
            {u"status"_s, job.handler->isActive() ? u"running"_s : u"stopped"_s},
            {u"total"_s, job.handler->results().size()},
            {u"outcome"_s, job.outcome},
            {u"error"_s, job.error}
        };
    }

    QJsonObject pluginJson(const PluginInfo *plugin)
    {
        QJsonArray categories;
        for (const QString &category : asConst(plugin->supportedCategories))
            categories.append(QJsonObject {{u"id"_s, category}, {u"name"_s, SearchPluginManager::categoryFullName(category)}});
        return {
            {u"name"_s, plugin->name},
            {u"fullName"_s, plugin->fullName},
            {u"version"_s, plugin->version.toString()},
            {u"url"_s, plugin->url},
            {u"enabled"_s, plugin->enabled},
            {u"supportedCategories"_s, categories},
            {u"iconPath"_s, plugin->iconPath.toString()}
        };
    }

    // Completes `reply` after `expected` installation/update outcomes of the
    // plugin manager (or a timeout), failing with the collected reasons.
    void awaitPluginOutcomes(const Reply &reply, const int expected, const bool updates)
    {
        if (expected <= 0)
            return reply.ok();

        auto *context = new QObject(CoreHost::instance());
        auto remaining = std::make_shared<int>(expected);
        auto errors = std::make_shared<QStringList>();
        const auto finish = [context, reply, errors]
        {
            if (errors->isEmpty())
                reply.ok();
            else
                reply.fail(ErrorKind::Other, errors->join(u'\n'));
            context->deleteLater();
        };
        const auto step = [remaining, finish]
        {
            if (--(*remaining) == 0)
                finish();
        };
        auto *manager = SearchPluginManager::instance();
        if (updates)
        {
            QObject::connect(manager, &SearchPluginManager::pluginUpdated, context, step);
            QObject::connect(manager, &SearchPluginManager::pluginUpdateFailed, context, [errors, step](const QString &name, const QString &reason)
            {
                errors->append(u"%1: %2"_s.arg(name, reason));
                step();
            });
        }
        else
        {
            QObject::connect(manager, &SearchPluginManager::pluginInstalled, context, step);
            QObject::connect(manager, &SearchPluginManager::pluginInstallationFailed, context, [errors, step](const QString &name, const QString &reason)
            {
                errors->append(u"%1: %2"_s.arg(name, reason));
                step();
            });
        }
        QTimer::singleShot(std::chrono::minutes(2), context, [finish] { finish(); });
    }
}

void Neo::registerSearchApi(Registry &registry)
{
    registry.add(u"searchEngineStatus"_s, [](const QJsonObject &)
    {
        const Utils::ForeignApps::PythonInfo python = Utils::ForeignApps::pythonInfo();
        QString message;
        if (!python.isValid())
            message = QCoreApplication::translate("SearchWidget", "Python must be installed to use the Search Engine.");
        else if (!python.isSupportedVersion())
            message = QCoreApplication::translate("SearchWidget", "Your Python version (%1) is outdated. Minimum requirement: %2.")
                .arg(python.version.toString(), Utils::ForeignApps::PythonInfo::MINIMUM_SUPPORTED_VERSION.toString());
        return QJsonObject {
            {u"pythonFound"_s, python.isValid() && python.isSupportedVersion()},
            {u"pythonPath"_s, python.executablePath.toString()},
            {u"pythonVersion"_s, python.isValid() ? python.version.toString() : QString()},
            {u"message"_s, message}
        };
    });

    registry.add(u"searchPlugins"_s, [](const QJsonObject &)
    {
        QJsonArray result;
        auto *manager = pluginManager();
        for (const QString &name : asConst(manager->allPlugins()))
        {
            if (const PluginInfo *plugin = manager->pluginInfo(name))
                result.append(pluginJson(plugin));
        }
        return result;
    });

    registry.addAsync(u"searchInstallPlugins"_s, [](const QJsonObject &args, const Reply &reply)
    {
        const QStringList sources = argStringList(args, u"sources"_s);
        awaitPluginOutcomes(reply, static_cast<int>(sources.size()), false);
        for (const QString &source : sources)
            pluginManager()->installPlugin(source.trimmed());
    });

    registry.add(u"searchUninstallPlugins"_s, [](const QJsonObject &args)
    {
        for (const QString &name : asConst(argStringList(args, u"names"_s)))
            pluginManager()->uninstallPlugin(name);
        return QJsonValue();
    });

    registry.add(u"searchEnablePlugins"_s, [](const QJsonObject &args)
    {
        const bool enable = argBool(args, u"enable"_s);
        for (const QString &name : asConst(argStringList(args, u"names"_s)))
            pluginManager()->enablePlugin(name, enable);
        return QJsonValue();
    });

    registry.addAsync(u"searchUpdatePlugins"_s, [](const QJsonObject &, const Reply &reply)
    {
        auto *manager = pluginManager();
        auto *context = new QObject(CoreHost::instance());
        QObject::connect(manager, &SearchPluginManager::checkForUpdatesFinished, context
                , [context, reply](const QHash<QString, PluginVersion> &updateInfo)
        {
            context->deleteLater();
            awaitPluginOutcomes(reply, static_cast<int>(updateInfo.size()), true);
            for (auto it = updateInfo.cbegin(); it != updateInfo.cend(); ++it)
                pluginManager()->updatePlugin(it.key());
        });
        QObject::connect(manager, &SearchPluginManager::checkForUpdatesFailed, context, [context, reply](const QString &reason)
        {
            context->deleteLater();
            reply.fail(ErrorKind::Network, reason);
        });
        manager->checkForUpdates();
    });

    registry.add(u"searchStart"_s, [](const QJsonObject &args)
    {
        if (!Utils::ForeignApps::pythonInfo().isValid())
            throwConflict(QCoreApplication::translate("SearchController", "Python must be installed to use the Search Engine."));

        const QString pattern = argString(args, u"pattern"_s).trimmed();
        if (pattern.isEmpty())
            throwInvalid(QCoreApplication::translate("SearchWidget", "Empty search pattern"));
        QString category = argString(args, u"category"_s).trimmed();
        if (category.isEmpty())
            category = u"all"_s;

        auto *manager = pluginManager();
        QStringList plugins = argStringList(args, u"plugins"_s);
        if (plugins.size() == 1)
        {
            const QString value = plugins[0].toLower();
            if (value == u"all")
                plugins = manager->allPlugins();
            else if ((value == u"enabled") || (value == u"multi"))
                plugins = manager->enabledPlugins();
        }
        else if (plugins.isEmpty())
        {
            plugins = manager->enabledPlugins();
        }
        if (plugins.isEmpty())
            throwConflict(QCoreApplication::translate("SearchWidget", "Please select at least one search plugin."));

        return QJsonValue(SearchJobs::instance()->start(pattern, category, plugins));
    });

    registry.add(u"searchStop"_s, [](const QJsonObject &args)
    {
        SearchJob &job = SearchJobs::instance()->job(argInt(args, u"id"_s));
        if (job.handler->isActive())
            job.handler->cancelSearch();
        return QJsonValue();
    });

    registry.add(u"searchStatus"_s, [](const QJsonObject &args)
    {
        QJsonArray result;
        auto *jobs = SearchJobs::instance();
        if (const auto id = argOptInt(args, u"id"_s))
        {
            result.append(jobInfo(*id, jobs->job(*id)));
            return result;
        }
        for (const qint64 id : asConst(jobs->ids()))
            result.append(jobInfo(id, jobs->job(id)));
        return result;
    });

    registry.add(u"searchResults"_s, [](const QJsonObject &args)
    {
        const SearchJob &job = SearchJobs::instance()->job(argInt(args, u"id"_s));
        const QList<SearchResult> results = job.handler->results();
        const qsizetype size = results.size();
        qint64 offset = argInt(args, u"offset"_s);
        const qint64 limit = argInt(args, u"limit"_s);
        if (offset < 0)
            offset = std::max<qint64>(0, size + offset);
        offset = std::min<qint64>(offset, size);
        const qint64 end = (limit <= 0) ? size : std::min<qint64>(size, offset + limit);

        QJsonArray page;
        for (qint64 i = offset; i < end; ++i)
        {
            const SearchResult &r = results[i];
            page.append(QJsonObject {
                {u"fileName"_s, r.fileName},
                {u"fileUrl"_s, r.fileUrl},
                {u"fileSize"_s, r.fileSize},
                {u"seeders"_s, r.nbSeeders},
                {u"leechers"_s, r.nbLeechers},
                {u"engineName"_s, r.engineName},
                {u"siteUrl"_s, r.siteUrl},
                {u"descrLink"_s, r.descrLink},
                {u"pubDate"_s, toSecs(r.pubDate, 0)}
            });
        }
        return QJsonObject {
            {u"status"_s, job.handler->isActive() ? u"running"_s : u"stopped"_s},
            {u"total"_s, size},
            {u"results"_s, page}
        };
    });

    registry.add(u"searchDelete"_s, [](const QJsonObject &args)
    {
        SearchJobs::instance()->remove(argInt(args, u"id"_s));
        return QJsonValue();
    });

    // Downloads a result through its plugin (nova2dl) when the plugin
    // provides a download function, like qBittorrent's search tab, then adds
    // it with the given options.
    registry.addAsync(u"searchDownloadTorrent"_s, [](const QJsonObject &args, const Reply &reply)
    {
        const QString url = argString(args, u"url"_s).trimmed();
        const QString plugin = argString(args, u"plugin"_s);
        const QJsonObject params = argObject(args, u"params"_s);
        if (url.isEmpty())
            throwInvalid(QCoreApplication::translate("SearchController", "Must specify URI or hash"));

        const auto add = [params, reply](const QString &source)
        {
            // Reuse the regular "addTorrent" handler (options, extras, replies).
            QJsonObject addArgs {
                {u"source"_s, swiftCase(u"url"_s, {{u"url"_s, source}})},
                {u"params"_s, params}
            };
            const Reply inner {reply.id(), [](void *context, const int32_t status, const char *data, const size_t length)
            {
                auto *outer = static_cast<Reply *>(context);
                if (status == QBTN_OK)
                    outer->ok();
                else
                    outer->fail(static_cast<ErrorKind>(status), QString::fromUtf8(data, static_cast<qsizetype>(length)));
                delete outer;
            }, new Reply(reply)};
            CoreHost::instance()->dispatch(u"addTorrent"_s, addArgs, inner);
        };

        if (url.startsWith(u"magnet:", Qt::CaseInsensitive) || plugin.isEmpty()
            || !pluginManager()->allPlugins().contains(plugin))
        {
            add(url);
            return;
        }

        SearchDownloadHandler *handler = pluginManager()->downloadTorrent(plugin, url);
        QObject::connect(handler, &SearchDownloadHandler::downloadFinished, handler
                , [handler, add, reply](const QString &path, const QString &errorMessage)
        {
            handler->deleteLater();
            if (!errorMessage.isEmpty() || path.isEmpty())
                reply.fail(ErrorKind::Network, errorMessage.isEmpty() ? QCoreApplication::translate("SearchController", "Download failed") : errorMessage);
            else
                add(path);
        });
    });
}
