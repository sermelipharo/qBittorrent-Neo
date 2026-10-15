/*
 * qBittorrent Neo — RSS reader and RSS auto-downloader.
 *
 * Semantics follow qBittorrent's RSS widgets and RSSController
 * (src/webui/api/rsscontroller.cpp). Item paths use "\" as separator; the
 * root folder is "".
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <algorithm>

#include <QJsonArray>
#include <QRegularExpression>

#include "base/global.h"
#include "base/rss/rss_article.h"
#include "base/rss/rss_autodownloader.h"
#include "base/rss/rss_autodownloadrule.h"
#include "base/rss/rss_feed.h"
#include "base/rss/rss_folder.h"
#include "base/rss/rss_session.h"
#include "corehost.h"
#include "jsonutil.h"
#include "params.h"
#include "registry.h"

using namespace Neo;

namespace
{
    RSS::Session *rssSession()
    {
        auto *session = RSS::Session::instance();
        if (!session)
            throwUnsupported(QCoreApplication::translate("RSS", "RSS is not ready yet"));
        return session;
    }

    RSS::AutoDownloader *autoDownloader()
    {
        auto *downloader = RSS::AutoDownloader::instance();
        if (!downloader)
            throwUnsupported(QCoreApplication::translate("RSS", "RSS is not ready yet"));
        return downloader;
    }

    template <typename T>
    void check(const nonstd::expected<T, QString> &result)
    {
        if (!result)
            throwConflict(result.error());
    }

    QJsonObject articleJson(const RSS::Article *article)
    {
        return {
            {u"id"_s, article->guid()},
            {u"date"_s, toSecs(article->date(), 0)},
            {u"title"_s, article->title()},
            {u"author"_s, article->author()},
            {u"description"_s, article->description()},
            {u"torrentUrl"_s, article->torrentUrl()},
            {u"link"_s, article->link()},
            {u"isRead"_s, article->isRead()}
        };
    }

    QJsonArray articlesJson(const QList<RSS::Article *> &articles)
    {
        QJsonArray result;
        for (const RSS::Article *article : articles)
            result.append(articleJson(article));
        return result;
    }

    QJsonObject feedJson(const RSS::Feed *feed, const bool withArticles)
    {
        return {
            {u"uid"_s, feed->uid().toString()},
            {u"url"_s, feed->url()},
            {u"path"_s, feed->path()},
            {u"title"_s, feed->title()},
            {u"lastBuildDate"_s, feed->lastBuildDate()},
            {u"isLoading"_s, feed->isLoading()},
            {u"hasError"_s, feed->hasError()},
            {u"refreshInterval"_s, static_cast<qint64>(feed->refreshInterval().count())},
            {u"unreadCount"_s, feed->unreadCount()},
            {u"articles"_s, withArticles ? articlesJson(feed->articles()) : QJsonArray()},
            {u"iconPath"_s, feed->iconPath().toString()}
        };
    }

    QJsonObject folderJson(const RSS::Folder *folder, const bool withArticles)
    {
        QJsonArray folders;
        QJsonArray feeds;
        for (const RSS::Item *item : asConst(folder->items()))
        {
            if (const auto *feed = qobject_cast<const RSS::Feed *>(item))
                feeds.append(feedJson(feed, withArticles));
            else if (const auto *subfolder = qobject_cast<const RSS::Folder *>(item))
                folders.append(folderJson(subfolder, withArticles));
        }
        return {
            {u"path"_s, folder->path()},
            {u"name"_s, folder->name()},
            {u"folders"_s, folders},
            {u"feeds"_s, feeds}
        };
    }

    RSS::Item *requireItem(const QString &path)
    {
        RSS::Item *item = path.isEmpty() ? rssSession()->rootFolder() : rssSession()->itemByPath(path);
        if (!item)
            throwNotFound(QCoreApplication::translate("RSS", "No such RSS item: %1").arg(path));
        return item;
    }

    QJsonObject ruleJson(const RSS::AutoDownloadRule &rule)
    {
        return {
            {u"name"_s, rule.name()},
            {u"enabled"_s, rule.isEnabled()},
            {u"priority"_s, rule.priority()},
            {u"useRegex"_s, rule.useRegex()},
            {u"mustContain"_s, rule.mustContain()},
            {u"mustNotContain"_s, rule.mustNotContain()},
            {u"episodeFilter"_s, rule.episodeFilter()},
            {u"affectedFeeds"_s, toJsonArray(rule.feedURLs())},
            {u"lastMatch"_s, rule.lastMatch().isValid() ? rule.lastMatch().toString(Qt::RFC2822Date) : QString()},
            {u"ignoreDays"_s, rule.ignoreDays()},
            {u"smartFilter"_s, rule.useSmartFilter()},
            {u"previouslyMatchedEpisodes"_s, toJsonArray(rule.previouslyMatchedEpisodes())},
            {u"torrentParams"_s, paramsTemplateJson(rule.addTorrentParams())}
        };
    }

    RSS::AutoDownloadRule parseRule(const QJsonObject &json)
    {
        RSS::AutoDownloadRule rule {argString(json, u"name"_s)};
        rule.setEnabled(argBool(json, u"enabled"_s, true));
        rule.setPriority(static_cast<int>(argInt(json, u"priority"_s)));
        rule.setUseRegex(argBool(json, u"useRegex"_s));
        rule.setMustContain(argString(json, u"mustContain"_s));
        rule.setMustNotContain(argString(json, u"mustNotContain"_s));
        rule.setEpisodeFilter(argString(json, u"episodeFilter"_s));
        rule.setFeedURLs(argStringList(json, u"affectedFeeds"_s));
        const QString lastMatch = argString(json, u"lastMatch"_s);
        if (!lastMatch.isEmpty())
            rule.setLastMatch(QDateTime::fromString(lastMatch, Qt::RFC2822Date));
        rule.setIgnoreDays(static_cast<int>(argInt(json, u"ignoreDays"_s)));
        rule.setUseSmartFilter(argBool(json, u"smartFilter"_s));
        rule.setPreviouslyMatchedEpisodes(argStringList(json, u"previouslyMatchedEpisodes"_s));
        rule.setAddTorrentParams(parseParamsTemplate(argObject(json, u"torrentParams"_s)));
        return rule;
    }

    QJsonArray matchingArticles(const RSS::AutoDownloadRule &rule)
    {
        QJsonArray result;
        for (const QString &feedURL : asConst(rule.feedURLs()))
        {
            const RSS::Feed *feed = rssSession()->feedByURL(feedURL);
            if (!feed)
                continue;
            QJsonArray titles;
            for (const RSS::Article *article : asConst(feed->articles()))
            {
                if (rule.matches(article->data()))
                    titles.append(article->title());
            }
            if (!titles.isEmpty())
                result.append(QJsonObject {{u"feedName"_s, feed->name()}, {u"articleTitles"_s, titles}});
        }
        return result;
    }

    QJsonValue base64(const QByteArray &data)
    {
        return QString::fromLatin1(data.toBase64());
    }
}

void Neo::registerRssApi(Registry &registry)
{
    registry.add(u"rssTree"_s, [](const QJsonObject &args)
    {
        return folderJson(rssSession()->rootFolder(), argBool(args, u"withArticles"_s));
    });
    registry.add(u"rssArticles"_s, [](const QJsonObject &args)
    {
        QList<RSS::Article *> articles = requireItem(argString(args, u"itemPath"_s))->articles();
        std::ranges::stable_sort(articles, [](const RSS::Article *a, const RSS::Article *b) { return a->date() > b->date(); });
        return articlesJson(articles);
    });
    registry.add(u"rssAddFolder"_s, [](const QJsonObject &args)
    {
        check(rssSession()->addFolder(argString(args, u"path"_s)));
        return QJsonValue();
    });
    registry.add(u"rssAddFeed"_s, [](const QJsonObject &args)
    {
        const QString url = argString(args, u"url"_s).trimmed();
        QString path = argString(args, u"path"_s);
        if (path.isEmpty())
            path = url;
        check(rssSession()->addFeed(url, path, std::chrono::seconds(argInt(args, u"refreshIntervalSecs"_s))));
        return QJsonValue();
    });
    registry.add(u"rssSetFeedUrl"_s, [](const QJsonObject &args)
    {
        check(rssSession()->setFeedURL(argString(args, u"path"_s), argString(args, u"url"_s).trimmed()));
        return QJsonValue();
    });
    registry.add(u"rssSetFeedRefreshInterval"_s, [](const QJsonObject &args)
    {
        auto *feed = qobject_cast<RSS::Feed *>(requireItem(argString(args, u"path"_s)));
        if (!feed)
            throwInvalid(QCoreApplication::translate("RSS", "Not a feed"));
        feed->setRefreshInterval(std::chrono::seconds(argInt(args, u"refreshIntervalSecs"_s)));
        return QJsonValue();
    });
    registry.add(u"rssRemoveItem"_s, [](const QJsonObject &args)
    {
        check(rssSession()->removeItem(argString(args, u"path"_s)));
        return QJsonValue();
    });
    registry.add(u"rssMoveItem"_s, [](const QJsonObject &args)
    {
        check(rssSession()->moveItem(argString(args, u"itemPath"_s), argString(args, u"destPath"_s)));
        return QJsonValue();
    });
    registry.add(u"rssMarkAsRead"_s, [](const QJsonObject &args)
    {
        RSS::Item *item = requireItem(argString(args, u"itemPath"_s));
        if (const auto articleId = argOptString(args, u"articleId"_s))
        {
            if (auto *feed = qobject_cast<RSS::Feed *>(item))
            {
                if (RSS::Article *article = feed->articleByGUID(*articleId))
                    article->markAsRead();
            }
        }
        else
        {
            item->markAsRead();
        }
        return QJsonValue();
    });
    registry.add(u"rssRefreshItem"_s, [](const QJsonObject &args)
    {
        requireItem(argString(args, u"itemPath"_s))->refresh();
        return QJsonValue();
    });

    // ---- Auto-downloader -------------------------------------------------
    registry.add(u"rssRules"_s, [](const QJsonObject &)
    {
        QJsonArray result;
        for (const RSS::AutoDownloadRule &rule : asConst(autoDownloader()->rules()))
            result.append(ruleJson(rule));
        return result;
    });
    registry.add(u"rssSetRule"_s, [](const QJsonObject &args)
    {
        const RSS::AutoDownloadRule rule = parseRule(argObject(args, u"rule"_s));
        if (rule.name().trimmed().isEmpty())
            throwInvalid(QCoreApplication::translate("RSS", "Rule name cannot be empty"));
        autoDownloader()->setRule(rule);
        return QJsonValue();
    });
    registry.add(u"rssRenameRule"_s, [](const QJsonObject &args)
    {
        if (!autoDownloader()->renameRule(argString(args, u"oldName"_s), argString(args, u"newName"_s)))
            throwConflict(QCoreApplication::translate("RSS", "Unable to rename the rule"));
        return QJsonValue();
    });
    registry.add(u"rssRemoveRule"_s, [](const QJsonObject &args)
    {
        autoDownloader()->removeRule(argString(args, u"name"_s));
        return QJsonValue();
    });
    registry.add(u"rssMatchingArticles"_s, [](const QJsonObject &args)
    {
        const QString name = argString(args, u"ruleName"_s);
        if (!autoDownloader()->hasRule(name))
            throwNotFound(QCoreApplication::translate("RSS", "No such rule: %1").arg(name));
        return matchingArticles(autoDownloader()->ruleByName(name));
    });
    registry.add(u"rssPreviewRuleMatches"_s, [](const QJsonObject &args)
    {
        return matchingArticles(parseRule(argObject(args, u"rule"_s)));
    });
    registry.add(u"rssClearRuleHistory"_s, [](const QJsonObject &args)
    {
        const QString name = argString(args, u"ruleName"_s);
        if (!autoDownloader()->hasRule(name))
            throwNotFound(QCoreApplication::translate("RSS", "No such rule: %1").arg(name));
        RSS::AutoDownloadRule rule = autoDownloader()->ruleByName(name);
        rule.setPreviouslyMatchedEpisodes({});
        autoDownloader()->setRule(rule);
        return QJsonValue();
    });
    registry.add(u"rssImportRules"_s, [](const QJsonObject &args)
    {
        const QByteArray data = QByteArray::fromBase64(argString(args, u"data"_s).toLatin1());
        // qBittorrent exports JSON or the legacy (QDataStream) format.
        const auto format = data.trimmed().startsWith('{')
            ? RSS::AutoDownloader::RulesFileFormat::JSON : RSS::AutoDownloader::RulesFileFormat::Legacy;
        try
        {
            autoDownloader()->importRules(data, format);
        }
        catch (const std::exception &error)
        {
            throwInvalid(QString::fromUtf8(error.what()));
        }
        return QJsonValue();
    });
    registry.add(u"rssExportRules"_s, [](const QJsonObject &)
    {
        return base64(autoDownloader()->exportRules(RSS::AutoDownloader::RulesFileFormat::JSON));
    });
    registry.add(u"rssExportRulesLegacy"_s, [](const QJsonObject &)
    {
        return base64(autoDownloader()->exportRules(RSS::AutoDownloader::RulesFileFormat::Legacy));
    });
    registry.add(u"rssValidateRuleExpression"_s, [](const QJsonObject &args)
    {
        const QString expression = argString(args, u"expression"_s);
        if (argBool(args, u"useRegex"_s))
        {
            const QRegularExpression regex {expression, QRegularExpression::CaseInsensitiveOption};
            return QJsonValue(regex.isValid() ? QString() : regex.errorString());
        }
        for (const QString &token : asConst(expression.split(QRegularExpression(u"[\\s|]"_s), Qt::SkipEmptyParts)))
        {
            const QRegularExpression regex {QRegularExpression::wildcardToRegularExpression(
                token, QRegularExpression::UnanchoredWildcardConversion)};
            if (!regex.isValid())
                return QJsonValue(QCoreApplication::translate("RSS", "Invalid wildcard: %1").arg(token));
        }
        return QJsonValue(QString());
    });
    registry.add(u"rssIsValidEpisodeFilter"_s, [](const QJsonObject &args)
    {
        // The pattern of qBittorrent's RSS Downloader dialog.
        static const QRegularExpression episodeRegex {u"^(^\\d{1,4}x(\\d{1,4}(-(\\d{1,4})?)?;){1,}){1,1}"_s
            , QRegularExpression::CaseInsensitiveOption};
        const QString filter = argString(args, u"filter"_s);
        return QJsonValue(filter.isEmpty() || episodeRegex.match(filter).hasMatch());
    });
}
