/*
 * qBittorrent Neo — application-level calls (version, paths, cookies,
 * network interfaces, WebUI state, passwords, tracker favicons, port test).
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <QHostAddress>
#include <QJsonArray>
#include <QJsonDocument>
#include <QNetworkCookie>
#include <QNetworkInterface>
#include <QPointer>
#include <QSysInfo>
#include <QTimer>
#include <QUrl>

#include <libtorrent/version.hpp>

#include "base/bittorrent/session.h"
#include "base/global.h"
#include "base/net/downloadmanager.h"
#include "base/preferences.h"
#include "base/utils/fs.h"
#include "base/utils/password.h"
#include "base/version.h"
#include "corehost.h"
#include "neoapplication.h"
#include "registry.h"

#ifndef DISABLE_WEBUI
#include "webui/webapplication.h"
#include "webui/webui.h"
#endif

using namespace Neo;

namespace
{
    const qint64 MAX_FAVICON_SIZE = 64 * 1024;

    // "Test Port" (Settings > Network): Transmission's port checker connects
    // back to the caller's address on <port> and answers "1" (reachable) or
    // "0". It runs only when the user clicks the button; see docs/SECURITY.md.
    const QString PORT_CHECK_URL = u"https://portcheck.transmissionbt.com/"_s;
    const qint64 MAX_PORT_CHECK_SIZE = 16;
    const auto PORT_CHECK_TIMEOUT = std::chrono::seconds(20);

    // Same derivation as qBittorrent's tracker filter: the tracker's http(s)
    // scheme (plain http otherwise) and the IP address or last two labels of
    // the host name.
    QStringList faviconUrls(const QString &trackerUrl)
    {
        const QUrl url {trackerUrl.trimmed()};
        const QString host = url.host();
        if (!url.isValid() || host.isEmpty())
            return {};
        const QString scheme = url.scheme().startsWith(u"http") ? url.scheme() : u"http"_s;
        QString faviconHost;
        if (const QHostAddress address {host}; !address.isNull())
            faviconHost = (address.protocol() == QAbstractSocket::IPv6Protocol) ? (u'[' + host + u']') : host;
        else
            faviconHost = host.section(u'.', -2, -1);
        return {u"%1://%2/favicon.ico"_s.arg(scheme, faviconHost), u"%1://%2/favicon.png"_s.arg(scheme, faviconHost)};
    }

    void fetchFavicon(QStringList urls, const Reply &reply, QObject *context)
    {
        if (urls.isEmpty())
            return reply.fail(ErrorKind::Network, u"favicon not available"_s);

        const QString url = urls.takeFirst();
        Net::DownloadManager::instance()->download(Net::DownloadRequest(url).limit(MAX_FAVICON_SIZE)
                , Preferences::instance()->useProxyForGeneralPurposes(), context
                , [urls, reply, context](const Net::DownloadResult &result)
        {
            if (reply.isDone())
                return;
            const bool isHtml = result.data.trimmed().startsWith('<');
            if ((result.status == Net::DownloadStatus::Success) && !result.data.isEmpty() && !isHtml)
                reply.ok(QString::fromLatin1(result.data.toBase64()));
            else
                fetchFavicon(urls, reply, context);
        });
    }
}

void Neo::registerAppApi(Registry &registry)
{
    registry.add(u"version"_s, [](const QJsonObject &)
    {
        return QJsonValue(QStringLiteral(QBT_VERSION));
    });

    registry.add(u"buildInfo"_s, [](const QJsonObject &)
    {
        QString webapi;
#ifndef DISABLE_WEBUI
        webapi = API_VERSION.toString();
#endif
        return QJsonObject {
            {u"app"_s, QStringLiteral(QBT_VERSION_2)},
            {u"qbittorrentCompat"_s, QStringLiteral(QBT_VERSION_2)},
            {u"webapi"_s, webapi},
            {u"engine"_s, QString(u"libtorrent "_s + QString::fromLatin1(LIBTORRENT_VERSION))},
            // The record field is named after the sibling app's toolchain;
            // here it carries the Qt version the core runs on.
            {u"rustc"_s, QString(u"Qt "_s + QString::fromLatin1(qVersion()))},
            {u"platform"_s, QSysInfo::prettyProductName()},
            {u"bitness"_s, static_cast<int>(QT_POINTER_SIZE * 8)}
        };
    });

    registry.add(u"defaultSavePath"_s, [](const QJsonObject &)
    {
        return QJsonValue(BitTorrent::Session::instance()->savePath().toString());
    });

    registry.add(u"freeDiskSpace"_s, [](const QJsonObject &args)
    {
        return QJsonValue(Utils::Fs::freeDiskSpaceOnPath(Path(argString(args, u"path"_s))));
    });

    registry.add(u"networkInterfaces"_s, [](const QJsonObject &)
    {
        QJsonArray result;
        for (const QNetworkInterface &iface : asConst(QNetworkInterface::allInterfaces()))
        {
            if (iface.addressEntries().isEmpty())
                continue;
            QJsonArray addresses;
            for (const QNetworkAddressEntry &entry : asConst(iface.addressEntries()))
                addresses.append(entry.ip().toString());
            result.append(QJsonObject {
                {u"name"_s, iface.humanReadableName()},
                {u"value"_s, iface.name()},
                {u"addresses"_s, addresses}
            });
        }
        return result;
    });

    registry.add(u"networkInterfaceAddresses"_s, [](const QJsonObject &args)
    {
        const QString name = argString(args, u"interface"_s);
        QJsonArray result;
        const QList<QNetworkAddressEntry> entries = name.isEmpty()
            ? QList<QNetworkAddressEntry>()
            : QNetworkInterface::interfaceFromName(name).addressEntries();
        for (const QNetworkAddressEntry &entry : entries)
            result.append(entry.ip().toString());
        return result;
    });

    registry.add(u"cookies"_s, [](const QJsonObject &)
    {
        QJsonArray result;
        for (const QNetworkCookie &cookie : asConst(Net::DownloadManager::instance()->allCookies()))
        {
            result.append(QJsonObject {
                {u"name"_s, QString::fromLatin1(cookie.name())},
                {u"domain"_s, cookie.domain()},
                {u"path"_s, cookie.path()},
                {u"value"_s, QString::fromLatin1(cookie.value())},
                {u"expirationDate"_s, cookie.expirationDate().isValid() ? cookie.expirationDate().toSecsSinceEpoch() : 0}
            });
        }
        return result;
    });

    registry.add(u"setCookies"_s, [](const QJsonObject &args)
    {
        QList<QNetworkCookie> cookies;
        for (const QJsonValue &value : asConst(args.value(u"cookies"_s).toArray()))
        {
            const QJsonObject item = value.toObject();
            QNetworkCookie cookie {item.value(u"name").toString().toLatin1(), item.value(u"value").toString().toLatin1()};
            cookie.setDomain(item.value(u"domain").toString());
            cookie.setPath(item.value(u"path").toString());
            const qint64 expires = item.value(u"expirationDate").toInteger();
            if (expires > 0)
                cookie.setExpirationDate(QDateTime::fromSecsSinceEpoch(expires));
            cookies.append(cookie);
        }
        Net::DownloadManager::instance()->setAllCookies(cookies);
        return QJsonValue();
    });

    registry.add(u"sendTestEmail"_s, [](const QJsonObject &)
    {
        CoreHost::instance()->app()->sendTestEmail();
        return QJsonValue();
    });

    registry.add(u"webuiStatus"_s, [](const QJsonObject &)
    {
        const auto *pref = Preferences::instance();
        QJsonObject status {
            {u"enabled"_s, pref->isWebUIEnabled()},
            {u"running"_s, false},
            {u"https"_s, pref->isWebUIHttpsEnabled()},
            {u"address"_s, pref->getWebUIAddress()},
            {u"port"_s, pref->getWebUIPort()},
            {u"url"_s, QString()},
            {u"error"_s, QString()},
            {u"username"_s, pref->getWebUIUsername()},
            {u"temporaryPassword"_s, QString()}
        };
#ifndef DISABLE_WEBUI
        if (const WebUI *webui = CoreHost::instance()->app()->webUI())
        {
            const bool running = webui->isEnabled() && !webui->isErrored();
            status[u"running"_s] = running;
            status[u"error"_s] = webui->errorMessage();
            if (running)
            {
                const QHostAddress address = webui->hostAddress();
                const QString host = address.isEqual(QHostAddress::Any, QHostAddress::ConvertUnspecifiedAddress)
                    ? u"localhost"_s : address.toString();
                status[u"https"_s] = webui->isHttps();
                status[u"port"_s] = webui->port();
                status[u"url"_s] = u"%1://%2:%3"_s.arg((webui->isHttps() ? u"https"_s : u"http"_s), host, QString::number(webui->port()));
            }
        }
#endif
        return status;
    });

    // WebAPI-style partial update used by the app for secrets the core must
    // hash itself.
    registry.add(u"setPreferencesJson"_s, [](const QJsonObject &args)
    {
        const QJsonObject json = QJsonDocument::fromJson(argString(args, u"json"_s).toUtf8()).object();
        auto *pref = Preferences::instance();
        if (json.contains(u"web_ui_password"))
        {
            const QString password = json.value(u"web_ui_password").toString();
            if (password.size() < 6)
                throwInvalid(QCoreApplication::translate("OptionsDialog", "The WebUI password must be at least 6 characters long."));
            pref->setWebUIPassword(Utils::Password::PBKDF2::generate(password));
        }
        if (json.contains(u"web_ui_username"))
            pref->setWebUIUsername(json.value(u"web_ui_username").toString());
        pref->apply();
        return QJsonValue();
    });

    registry.add(u"hashUiLockPassword"_s, [](const QJsonObject &args)
    {
        return QJsonValue(QString::fromLatin1(Utils::Password::PBKDF2::generate(argString(args, u"password"_s))));
    });

    registry.add(u"verifyUiLockPassword"_s, [](const QJsonObject &args)
    {
        return QJsonValue(Utils::Password::PBKDF2::verify(argString(args, u"stored"_s).toLatin1(), argString(args, u"password"_s)));
    });

    registry.addAsync(u"fetchTrackerFavicon"_s, [](const QJsonObject &args, const Reply &reply)
    {
        const QStringList urls = faviconUrls(argString(args, u"trackerUrl"_s));
        if (urls.isEmpty())
            throwInvalid(u"tracker URL has no host"_s);
        fetchFavicon(urls, reply, CoreHost::instance());
    });

    registry.addAsync(u"checkPort"_s, [](const QJsonObject &args, const Reply &reply)
    {
        const qint64 port = argInt(args, u"port"_s);
        if ((port < 1) || (port > 65535))
            throwInvalid(u"invalid port"_s);

        QObject *context = CoreHost::instance();
        QTimer::singleShot(PORT_CHECK_TIMEOUT, context, [reply]
        {
            if (!reply.isDone())
                reply.fail(ErrorKind::Network, u"The connection to the port checker timed out"_s);
        });
        Net::DownloadManager::instance()->download(
                Net::DownloadRequest(PORT_CHECK_URL + QString::number(port)).limit(MAX_PORT_CHECK_SIZE)
                , Preferences::instance()->useProxyForGeneralPurposes(), context
                , [reply](const Net::DownloadResult &result)
        {
            if (reply.isDone())
                return;
            if (result.status != Net::DownloadStatus::Success)
                return reply.fail(ErrorKind::Network, result.errorString);
            const QByteArray answer = result.data.trimmed();
            if (answer == "1")
                reply.ok(true);
            else if (answer == "0")
                reply.ok(false);
            else
                reply.fail(ErrorKind::Network, u"The port checker sent an unexpected answer"_s);
        });
    });
}
