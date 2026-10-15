/*
 * qBittorrent Neo — the app's `Preferences` record, read from and written to
 * qBittorrent's Preferences, Session, RSS and application settings.
 *
 * Every field has the meaning (and unit) of the WebAPI preference of the same
 * name (see AppController::preferencesAction/setPreferencesAction in
 * src/webui/api/appcontroller.cpp). Writing applies only the fields that
 * differ from the current values, so untouched settings keep their exact
 * stored value (e.g. the "Default" disk I/O type).
 *
 * Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include <functional>

#include <QHostAddress>
#include <QJsonArray>
#include <QNetworkInterface>
#include <QTime>
#include <QTranslator>

#include "base/bittorrent/session.h"
#include "base/global.h"
#include "base/net/portforwarder.h"
#include "base/net/proxyconfigurationmanager.h"
#include "base/preferences.h"
#include "base/rss/rss_autodownloader.h"
#include "base/rss/rss_session.h"
#include "base/torrentfileguard.h"
#include "base/torrentfileswatcher.h"
#include "base/utils/net.h"
#include "corehost.h"
#include "jsonutil.h"
#include "maindata.h"
#include "neoapplication.h"
#include "params.h"
#include "registry.h"

using namespace Neo;

namespace
{
    // Enum <-> name tables using the case names of the app's Swift enums.
    template <typename E>
    struct NameTable
    {
        QList<std::pair<E, QString>> items;

        QString name(const E value) const
        {
            for (const auto &[v, n] : items)
            {
                if (v == value)
                    return n;
            }
            return items.first().second;
        }

        E value(const QString &name) const
        {
            for (const auto &[v, n] : items)
            {
                if (n == name)
                    return v;
            }
            return items.first().first;
        }
    };

    const NameTable<int> FILE_LOG_AGE_TYPES {{{0, u"days"_s}, {1, u"months"_s}, {2, u"years"_s}}};
    const NameTable<TorrentFileGuard::AutoDeleteMode> AUTO_DELETE_MODES {{
        {TorrentFileGuard::Never, u"never"_s}, {TorrentFileGuard::IfAdded, u"ifAdded"_s}, {TorrentFileGuard::Always, u"always"_s}}};
    const NameTable<BitTorrent::BTProtocol> BT_PROTOCOLS {{
        {BitTorrent::BTProtocol::Both, u"both"_s}, {BitTorrent::BTProtocol::TCP, u"tcp"_s}, {BitTorrent::BTProtocol::UTP, u"utp"_s}}};
    const NameTable<Net::ProxyType> PROXY_TYPES {{
        {Net::ProxyType::None, u"none"_s}, {Net::ProxyType::HTTP, u"http"_s},
        {Net::ProxyType::SOCKS5, u"socks5"_s}, {Net::ProxyType::SOCKS4, u"socks4"_s}}};
    const NameTable<Scheduler::Days> SCHEDULER_DAYS {{
        {Scheduler::Days::EveryDay, u"everyDay"_s}, {Scheduler::Days::Weekday, u"weekday"_s},
        {Scheduler::Days::Weekend, u"weekend"_s}, {Scheduler::Days::Monday, u"monday"_s},
        {Scheduler::Days::Tuesday, u"tuesday"_s}, {Scheduler::Days::Wednesday, u"wednesday"_s},
        {Scheduler::Days::Thursday, u"thursday"_s}, {Scheduler::Days::Friday, u"friday"_s},
        {Scheduler::Days::Saturday, u"saturday"_s}, {Scheduler::Days::Sunday, u"sunday"_s}}};
    const NameTable<int> ENCRYPTION_MODES {{{0, u"allow"_s}, {1, u"require"_s}, {2, u"disable"_s}}};
    const NameTable<DNS::Service> DYNDNS_SERVICES {{{DNS::Service::DynDNS, u"dynDns"_s}, {DNS::Service::NoIP, u"noIp"_s}}};
    const NameTable<BitTorrent::ResumeDataStorageType> RESUME_STORAGE_TYPES {{
        {BitTorrent::ResumeDataStorageType::Legacy, u"legacy"_s}, {BitTorrent::ResumeDataStorageType::SQLite, u"sqLite"_s}}};
    const NameTable<BitTorrent::TorrentContentRemoveOption> CONTENT_REMOVE_OPTIONS {{
        {BitTorrent::TorrentContentRemoveOption::Delete, u"delete"_s},
        {BitTorrent::TorrentContentRemoveOption::MoveToTrash, u"moveToTrash"_s}}};
    // qBittorrent's "Default" disk I/O type has no case in the app; it is
    // shown as memory-mapped (libtorrent's default on macOS).
    const NameTable<BitTorrent::DiskIOType> DISK_IO_TYPES {{
        {BitTorrent::DiskIOType::MMap, u"mMap"_s}, {BitTorrent::DiskIOType::Default, u"mMap"_s},
        {BitTorrent::DiskIOType::Posix, u"posix"_s}, {BitTorrent::DiskIOType::SimplePreadPwrite, u"simplePreadPwrite"_s}}};
    const NameTable<BitTorrent::DiskIOReadMode> DISK_IO_READ_MODES {{
        {BitTorrent::DiskIOReadMode::DisableOSCache, u"disableOsCache"_s},
        {BitTorrent::DiskIOReadMode::EnableOSCache, u"enableOsCache"_s}}};
    const NameTable<BitTorrent::DiskIOWriteMode> DISK_IO_WRITE_MODES {{
        {BitTorrent::DiskIOWriteMode::DisableOSCache, u"disableOsCache"_s},
        {BitTorrent::DiskIOWriteMode::EnableOSCache, u"enableOsCache"_s},
        {BitTorrent::DiskIOWriteMode::WriteThrough, u"writeThrough"_s}}};
    const NameTable<BitTorrent::MixedModeAlgorithm> UTP_MIXED_MODES {{
        {BitTorrent::MixedModeAlgorithm::TCP, u"preferTcp"_s}, {BitTorrent::MixedModeAlgorithm::Proportional, u"peerProportional"_s}}};
    const NameTable<BitTorrent::ChokingAlgorithm> CHOKING_ALGORITHMS {{
        {BitTorrent::ChokingAlgorithm::FixedSlots, u"fixedSlots"_s}, {BitTorrent::ChokingAlgorithm::RateBased, u"rateBased"_s}}};
    const NameTable<BitTorrent::SeedChokingAlgorithm> SEED_CHOKING_ALGORITHMS {{
        {BitTorrent::SeedChokingAlgorithm::RoundRobin, u"roundRobin"_s},
        {BitTorrent::SeedChokingAlgorithm::FastestUpload, u"fastestUpload"_s},
        {BitTorrent::SeedChokingAlgorithm::AntiLeech, u"antiLeech"_s}}};

    QStringList stringList(const QJsonValue &value)
    {
        QStringList result;
        for (const QJsonValue &item : asConst(value.toArray()))
            result.append(item.toString());
        return result;
    }

    int toInt(const QJsonValue &value)
    {
        return static_cast<int>(value.toInteger(static_cast<qint64>(value.toDouble())));
    }

    QJsonArray watchedFoldersJson()
    {
        QJsonArray result;
        const auto *watcher = TorrentFilesWatcher::instance();
        if (!watcher)
            return result;
        const QHash<Path, TorrentFilesWatcher::WatchedFolderOptions> folders = watcher->folders();
        for (auto it = folders.cbegin(); it != folders.cend(); ++it)
        {
            result.append(QJsonObject {
                {u"path"_s, it.key().toString()},
                {u"recursive"_s, it.value().recursive},
                {u"params"_s, paramsTemplateJson(it.value().addTorrentParams)}
            });
        }
        return result;
    }

    void setWatchedFolders(const QJsonValue &value)
    {
        auto *watcher = TorrentFilesWatcher::instance();
        if (!watcher)
            return;
        QList<Path> keep;
        for (const QJsonValue &item : asConst(value.toArray()))
        {
            const QJsonObject folder = item.toObject();
            const Path path {folder.value(u"path").toString()};
            if (path.isEmpty())
                continue;
            TorrentFilesWatcher::WatchedFolderOptions options;
            options.recursive = folder.value(u"recursive").toBool();
            options.addTorrentParams = parseParamsTemplate(folder.value(u"params").toObject());
            try
            {
                watcher->setWatchedFolder(path, options);
                keep.append(path);
            }
            catch (const std::exception &error)
            {
                throwInvalid(QString::fromUtf8(error.what()));
            }
        }
        for (const Path &path : asConst(watcher->folders().keys()))
        {
            if (!keep.contains(path))
                watcher->removeWatchedFolder(path);
        }
    }

    QJsonObject behaviorJson()
    {
        const auto *pref = Preferences::instance();
        const auto *session = BitTorrent::Session::instance();
        const NeoApplication *app = CoreHost::instance()->app();
        return {
            {u"locale"_s, pref->getLocale()},
            {u"performanceWarning"_s, session->isPerformanceWarningEnabled()},
            {u"statusBarExternalIp"_s, pref->isStatusbarExternalIPDisplayed()},
            {u"confirmTorrentDeletion"_s, pref->confirmTorrentDeletion()},
            {u"fileLogEnabled"_s, app->isFileLoggerEnabled()},
            {u"fileLogPath"_s, app->fileLoggerPath().toString()},
            {u"fileLogBackupEnabled"_s, app->isFileLoggerBackup()},
            {u"fileLogMaxSize"_s, app->fileLoggerMaxSize() / 1024},
            {u"fileLogDeleteOld"_s, app->isFileLoggerDeleteOld()},
            {u"fileLogAge"_s, app->fileLoggerAge()},
            {u"fileLogAgeType"_s, FILE_LOG_AGE_TYPES.name(app->fileLoggerAgeType())},
            {u"deleteTorrentContentFiles"_s, pref->removeTorrentContent()}
        };
    }

    QJsonObject downloadsJson()
    {
        const auto *pref = Preferences::instance();
        const auto *session = BitTorrent::Session::instance();
        return {
            {u"torrentContentLayout"_s, contentLayoutName(session->torrentContentLayout())},
            {u"addToTopOfQueue"_s, session->isAddTorrentToQueueTop()},
            {u"addStoppedEnabled"_s, session->isAddTorrentStopped()},
            {u"torrentStopCondition"_s, stopConditionName(session->torrentStopCondition())},
            {u"mergeTrackers"_s, session->isMergeTrackersEnabled()},
            {u"autoDeleteMode"_s, AUTO_DELETE_MODES.name(TorrentFileGuard::autoDeleteMode())},
            {u"preallocateAll"_s, session->isPreallocationEnabled()},
            {u"incompleteFilesExt"_s, session->isAppendExtensionEnabled()},
            {u"useUnwantedFolder"_s, session->isUnwantedFolderEnabled()},
            {u"autoTmmEnabled"_s, !session->isAutoTMMDisabledByDefault()},
            {u"torrentChangedTmmEnabled"_s, !session->isDisableAutoTMMWhenCategoryChanged()},
            {u"savePathChangedTmmEnabled"_s, !session->isDisableAutoTMMWhenDefaultSavePathChanged()},
            {u"categoryChangedTmmEnabled"_s, !session->isDisableAutoTMMWhenCategorySavePathChanged()},
            // qBittorrent 5.2 always supports subcategories.
            {u"useSubcategories"_s, true},
            {u"savePath"_s, session->savePath().toString()},
            {u"tempPathEnabled"_s, session->isDownloadPathEnabled()},
            {u"tempPath"_s, session->downloadPath().toString()},
            {u"useCategoryPathsInManualMode"_s, session->useCategoryPathsInManualMode()},
            {u"exportDir"_s, session->torrentExportDirectory().toString()},
            {u"exportDirFin"_s, session->finishedTorrentExportDirectory().toString()},
            {u"watchedFolders"_s, watchedFoldersJson()},
            {u"excludedFileNamesEnabled"_s, session->isExcludedFileNamesEnabled()},
            {u"excludedFileNames"_s, toJsonArray(session->excludedFileNames())},
            {u"mailNotificationEnabled"_s, pref->isMailNotificationEnabled()},
            {u"mailNotificationSender"_s, pref->getMailNotificationSender()},
            {u"mailNotificationEmail"_s, pref->getMailNotificationEmail()},
            {u"mailNotificationSmtp"_s, pref->getMailNotificationSMTP()},
            {u"mailNotificationSslEnabled"_s, pref->getMailNotificationSMTPSSL()},
            {u"mailNotificationAuthEnabled"_s, pref->getMailNotificationSMTPAuth()},
            {u"mailNotificationUsername"_s, pref->getMailNotificationSMTPUsername()},
            {u"mailNotificationPassword"_s, pref->getMailNotificationSMTPPassword()},
            {u"autorunOnTorrentAddedEnabled"_s, pref->isAutoRunOnTorrentAddedEnabled()},
            {u"autorunOnTorrentAddedProgram"_s, pref->getAutoRunOnTorrentAddedProgram()},
            {u"autorunEnabled"_s, pref->isAutoRunOnTorrentFinishedEnabled()},
            {u"autorunProgram"_s, pref->getAutoRunOnTorrentFinishedProgram()}
        };
    }

    QJsonObject connectionJson()
    {
        const auto *pref = Preferences::instance();
        const auto *session = BitTorrent::Session::instance();
        const Net::ProxyConfiguration proxy = Net::ProxyConfigurationManager::instance()->proxyConfiguration();
        return {
            {u"bittorrentProtocol"_s, BT_PROTOCOLS.name(session->btProtocol())},
            {u"listenPort"_s, session->port()},
            {u"sslEnabled"_s, session->isSSLEnabled()},
            {u"sslListenPort"_s, session->sslPort()},
            {u"upnp"_s, Net::PortForwarder::instance()->isEnabled()},
            {u"maxConnec"_s, session->maxConnections()},
            {u"maxConnecPerTorrent"_s, session->maxConnectionsPerTorrent()},
            {u"maxUploads"_s, session->maxUploads()},
            {u"maxUploadsPerTorrent"_s, session->maxUploadsPerTorrent()},
            {u"i2pEnabled"_s, session->isI2PEnabled()},
            {u"i2pAddress"_s, session->I2PAddress()},
            {u"i2pPort"_s, session->I2PPort()},
            {u"i2pMixedMode"_s, session->I2PMixedMode()},
            {u"i2pInboundQuantity"_s, session->I2PInboundQuantity()},
            {u"i2pOutboundQuantity"_s, session->I2POutboundQuantity()},
            {u"i2pInboundLength"_s, session->I2PInboundLength()},
            {u"i2pOutboundLength"_s, session->I2POutboundLength()},
            {u"proxyType"_s, PROXY_TYPES.name(proxy.type)},
            {u"proxyIp"_s, proxy.ip},
            {u"proxyPort"_s, proxy.port},
            {u"proxyAuthEnabled"_s, proxy.authEnabled},
            {u"proxyUsername"_s, proxy.username},
            {u"proxyPassword"_s, proxy.password},
            {u"proxyHostnameLookup"_s, proxy.hostnameLookupEnabled},
            {u"proxyBittorrent"_s, pref->useProxyForBT()},
            {u"proxyPeerConnections"_s, session->isProxyPeerConnectionsEnabled()},
            {u"proxyRss"_s, pref->useProxyForRSS()},
            {u"proxyMisc"_s, pref->useProxyForGeneralPurposes()},
            {u"ipFilterEnabled"_s, session->isIPFilteringEnabled()},
            {u"ipFilterPath"_s, session->IPFilterFile().toString()},
            {u"ipFilterTrackers"_s, session->isTrackerFilteringEnabled()},
            {u"bannedIps"_s, toJsonArray(session->bannedIPs())}
        };
    }

    QJsonObject speedJson()
    {
        const auto *pref = Preferences::instance();
        const auto *session = BitTorrent::Session::instance();
        const QTime start = pref->getSchedulerStartTime();
        const QTime end = pref->getSchedulerEndTime();
        return {
            {u"dlLimit"_s, session->globalDownloadSpeedLimit()},
            {u"upLimit"_s, session->globalUploadSpeedLimit()},
            {u"altDlLimit"_s, session->altGlobalDownloadSpeedLimit()},
            {u"altUpLimit"_s, session->altGlobalUploadSpeedLimit()},
            {u"limitUtpRate"_s, session->isUTPRateLimited()},
            {u"limitTcpOverhead"_s, session->includeOverheadInLimits()},
            {u"limitLanPeers"_s, !session->ignoreLimitsOnLAN()},
            {u"schedulerEnabled"_s, session->isBandwidthSchedulerEnabled()},
            {u"scheduleFromHour"_s, start.hour()},
            {u"scheduleFromMin"_s, start.minute()},
            {u"scheduleToHour"_s, end.hour()},
            {u"scheduleToMin"_s, end.minute()},
            {u"schedulerDays"_s, SCHEDULER_DAYS.name(pref->getSchedulerDays())}
        };
    }

    QJsonObject bittorrentJson()
    {
        const auto *session = BitTorrent::Session::instance();
        return {
            {u"dht"_s, session->isDHTEnabled()},
            {u"pex"_s, session->isPeXEnabled()},
            {u"lsd"_s, session->isLSDEnabled()},
            {u"encryption"_s, ENCRYPTION_MODES.name(session->encryption())},
            {u"anonymousMode"_s, session->isAnonymousModeEnabled()},
            {u"maxActiveCheckingTorrents"_s, session->maxActiveCheckingTorrents()},
            {u"queueingEnabled"_s, session->isQueueingSystemEnabled()},
            {u"maxActiveDownloads"_s, session->maxActiveDownloads()},
            {u"maxActiveTorrents"_s, session->maxActiveTorrents()},
            {u"maxActiveUploads"_s, session->maxActiveUploads()},
            {u"dontCountSlowTorrents"_s, session->ignoreSlowTorrentsForQueueing()},
            {u"slowTorrentDlRateThreshold"_s, session->downloadRateForSlowTorrents()},
            {u"slowTorrentUlRateThreshold"_s, session->uploadRateForSlowTorrents()},
            {u"slowTorrentInactiveTimer"_s, session->slowTorrentsInactivityTimer()},
            {u"maxRatio"_s, session->globalMaxRatio()},
            {u"maxSeedingTime"_s, session->globalMaxSeedingMinutes()},
            {u"maxInactiveSeedingTime"_s, session->globalMaxInactiveSeedingMinutes()},
            {u"maxRatioAct"_s, shareLimitActionName(session->shareLimitAction())},
            {u"addTrackersEnabled"_s, session->isAddTrackersEnabled()},
            {u"addTrackers"_s, session->additionalTrackers()},
            {u"addTrackersFromUrlEnabled"_s, session->isAddTrackersFromURLEnabled()},
            {u"addTrackersUrl"_s, session->additionalTrackersURL()},
            {u"addTrackersUrlList"_s, session->additionalTrackersFromURL()}
        };
    }

    QJsonObject rssJson()
    {
        const auto *rss = RSS::Session::instance();
        const auto *autoDownloader = RSS::AutoDownloader::instance();
        if (!rss || !autoDownloader)
            return {};  // Not created yet (session still restoring): app defaults apply.
        return {
            {u"rssRefreshInterval"_s, rss->refreshInterval()},
            {u"rssFetchDelay"_s, static_cast<qint64>(rss->fetchDelay().count())},
            {u"rssMaxArticlesPerFeed"_s, rss->maxArticlesPerFeed()},
            {u"rssProcessingEnabled"_s, rss->isProcessingEnabled()},
            {u"rssAutoDownloadingEnabled"_s, autoDownloader->isProcessingEnabled()},
            {u"rssDownloadRepackProperEpisodes"_s, autoDownloader->downloadRepacks()},
            {u"rssSmartEpisodeFilters"_s, toJsonArray(autoDownloader->smartEpisodeFilters())}
        };
    }

    QJsonObject webuiJson()
    {
        const auto *pref = Preferences::instance();
        QStringList subnets;
        for (const Utils::Net::Subnet &subnet : asConst(pref->getWebUIAuthSubnetWhitelist()))
            subnets.append(Utils::Net::subnetToString(subnet));
        return {
            {u"webUiEnabled"_s, pref->isWebUIEnabled()},
            {u"webUiDomainList"_s, pref->getServerDomains()},
            {u"webUiAddress"_s, pref->getWebUIAddress()},
            {u"webUiPort"_s, pref->getWebUIPort()},
            {u"webUiUpnp"_s, pref->useUPnPForWebUIPort()},
            {u"useHttps"_s, pref->isWebUIHttpsEnabled()},
            {u"webUiHttpsCertPath"_s, pref->getWebUIHttpsCertificatePath().toString()},
            {u"webUiHttpsKeyPath"_s, pref->getWebUIHttpsKeyPath().toString()},
            {u"webUiUsername"_s, pref->getWebUIUsername()},
            {u"webUiPasswordPbkdf2"_s, QString::fromLatin1(pref->getWebUIPassword())},
            {u"webUiApiKey"_s, pref->getWebUIApiKey()},
            {u"bypassLocalAuth"_s, !pref->isWebUILocalAuthEnabled()},
            {u"bypassAuthSubnetWhitelistEnabled"_s, pref->isWebUIAuthSubnetWhitelistEnabled()},
            {u"bypassAuthSubnetWhitelist"_s, toJsonArray(subnets)},
            {u"webUiMaxAuthFailCount"_s, pref->getWebUIMaxAuthFailCount()},
            {u"webUiBanDuration"_s, static_cast<qint64>(pref->getWebUIBanDuration().count())},
            {u"webUiSessionTimeout"_s, pref->getWebUISessionTimeout()},
            {u"alternativeWebuiEnabled"_s, pref->isAltWebUIEnabled()},
            {u"alternativeWebuiPath"_s, pref->getWebUIRootFolder().toString()},
            {u"webUiClickjackingProtectionEnabled"_s, pref->isWebUIClickjackingProtectionEnabled()},
            {u"webUiCsrfProtectionEnabled"_s, pref->isWebUICSRFProtectionEnabled()},
            {u"webUiSecureCookieEnabled"_s, pref->isWebUISecureCookieEnabled()},
            {u"webUiHostHeaderValidationEnabled"_s, pref->isWebUIHostHeaderValidationEnabled()},
            {u"webUiUseCustomHttpHeadersEnabled"_s, pref->isWebUICustomHTTPHeadersEnabled()},
            {u"webUiCustomHttpHeaders"_s, pref->getWebUICustomHTTPHeaders()},
            {u"webUiReverseProxyEnabled"_s, pref->isWebUIReverseProxySupportEnabled()},
            {u"webUiReverseProxiesList"_s, pref->getWebUITrustedReverseProxiesList()},
            {u"dyndnsEnabled"_s, pref->isDynDNSEnabled()},
            {u"dyndnsService"_s, DYNDNS_SERVICES.name(pref->getDynDNSService())},
            {u"dyndnsUsername"_s, pref->getDynDNSUsername()},
            {u"dyndnsPassword"_s, pref->getDynDNSPassword()},
            {u"dyndnsDomain"_s, pref->getDynDomainName()}
        };
    }

    QJsonObject advancedJson()
    {
        const auto *pref = Preferences::instance();
        const auto *session = BitTorrent::Session::instance();
        const NeoApplication *app = CoreHost::instance()->app();
        return {
            {u"resumeDataStorageType"_s, RESUME_STORAGE_TYPES.name(session->resumeDataStorageType())},
            {u"torrentContentRemoveOption"_s, CONTENT_REMOVE_OPTIONS.name(session->torrentContentRemoveOption())},
            {u"memoryWorkingSetLimit"_s, app->memoryWorkingSetLimit()},
            {u"currentNetworkInterface"_s, session->networkInterface()},
            {u"currentInterfaceName"_s, session->networkInterfaceName()},
            {u"currentInterfaceAddress"_s, session->networkInterfaceAddress()},
            {u"saveResumeDataInterval"_s, session->saveResumeDataInterval()},
            {u"saveStatisticsInterval"_s, static_cast<qint64>(session->saveStatisticsInterval().count())},
            {u"torrentFileSizeLimit"_s, pref->getTorrentFileSizeLimit()},
            {u"confirmTorrentRecheck"_s, pref->confirmTorrentRecheck()},
            {u"recheckCompletedTorrents"_s, pref->recheckTorrentsOnCompletion()},
            {u"appInstanceName"_s, app->instanceName()},
            {u"refreshInterval"_s, session->refreshInterval()},
            {u"resolvePeerHostNames"_s, pref->resolvePeerHostNames()},
            {u"resolvePeerCountries"_s, pref->resolvePeerCountries()},
            {u"reannounceWhenAddressChanged"_s, session->isReannounceWhenAddressChangedEnabled()},
            {u"enableEmbeddedTracker"_s, session->isTrackerEnabled()},
            {u"embeddedTrackerPort"_s, pref->getTrackerPort()},
            {u"embeddedTrackerPortForwarding"_s, pref->isTrackerPortForwardingEnabled()},
            {u"markOfTheWeb"_s, pref->isMarkOfTheWebEnabled()},
            {u"ignoreSslErrors"_s, pref->isIgnoreSSLErrors()},
            {u"pythonExecutablePath"_s, pref->getPythonExecutablePath().toString()},
            {u"startPaused"_s, session->isStartPaused()},
            {u"shutdownTimeout"_s, session->shutdownTimeout()},
            {u"bdecodeDepthLimit"_s, pref->getBdecodeDepthLimit()},
            {u"bdecodeTokenLimit"_s, pref->getBdecodeTokenLimit()},
            {u"asyncIoThreads"_s, session->asyncIOThreads()},
            {u"hashingThreads"_s, session->hashingThreads()},
            {u"filePoolSize"_s, session->filePoolSize()},
            {u"checkingMemoryUse"_s, session->checkingMemUsage()},
            {u"diskCache"_s, session->diskCacheSize()},
            {u"diskCacheTtl"_s, session->diskCacheTTL()},
            {u"diskQueueSize"_s, session->diskQueueSize()},
            {u"diskIoType"_s, DISK_IO_TYPES.name(session->diskIOType())},
            {u"diskIoReadMode"_s, DISK_IO_READ_MODES.name(session->diskIOReadMode())},
            {u"diskIoWriteMode"_s, DISK_IO_WRITE_MODES.name(session->diskIOWriteMode())},
            {u"enableCoalesceReadWrite"_s, session->isCoalesceReadWriteEnabled()},
            {u"enablePieceExtentAffinity"_s, session->usePieceExtentAffinity()},
            {u"enableUploadSuggestions"_s, session->isSuggestModeEnabled()},
            {u"sendBufferWatermark"_s, session->sendBufferWatermark()},
            {u"sendBufferLowWatermark"_s, session->sendBufferLowWatermark()},
            {u"sendBufferWatermarkFactor"_s, session->sendBufferWatermarkFactor()},
            {u"connectionSpeed"_s, session->connectionSpeed()},
            {u"socketSendBufferSize"_s, session->socketSendBufferSize()},
            {u"socketReceiveBufferSize"_s, session->socketReceiveBufferSize()},
            {u"socketBacklogSize"_s, session->socketBacklogSize()},
            {u"outgoingPortsMin"_s, session->outgoingPortsMin()},
            {u"outgoingPortsMax"_s, session->outgoingPortsMax()},
            {u"upnpLeaseDuration"_s, session->UPnPLeaseDuration()},
            {u"peerTos"_s, session->peerDSCP()},
            {u"utpTcpMixedMode"_s, UTP_MIXED_MODES.name(session->utpMixedMode())},
            {u"hostnameCacheTtl"_s, session->hostnameCacheTTL()},
            {u"idnSupportEnabled"_s, session->isIDNSupportEnabled()},
            {u"enableMultiConnectionsFromSameIp"_s, session->multiConnectionsPerIpEnabled()},
            {u"validateHttpsTrackerCertificate"_s, session->validateHTTPSTrackerCertificate()},
            {u"ssrfMitigation"_s, session->isSSRFMitigationEnabled()},
            {u"blockPeersOnPrivilegedPorts"_s, session->blockPeersOnPrivilegedPorts()},
            {u"uploadSlotsBehavior"_s, CHOKING_ALGORITHMS.name(session->chokingAlgorithm())},
            {u"uploadChokingAlgorithm"_s, SEED_CHOKING_ALGORITHMS.name(session->seedChokingAlgorithm())},
            {u"announceToAllTrackers"_s, session->announceToAllTrackers()},
            {u"announceToAllTiers"_s, session->announceToAllTiers()},
            {u"announceIp"_s, session->announceIP()},
            {u"announcePort"_s, session->announcePort()},
            {u"maxConcurrentHttpAnnounces"_s, session->maxConcurrentHTTPAnnounces()},
            {u"stopTrackerTimeout"_s, session->stopTrackerTimeout()},
            {u"peerTurnover"_s, session->peerTurnover()},
            {u"peerTurnoverCutoff"_s, session->peerTurnoverCutoff()},
            {u"peerTurnoverInterval"_s, session->peerTurnoverInterval()},
            {u"requestQueueSize"_s, session->requestQueueSize()},
            {u"dhtBootstrapNodes"_s, session->getDHTBootstrapNodes()}
        };
    }

    QJsonObject preferencesJson()
    {
        return {
            {u"behavior"_s, behaviorJson()},
            {u"downloads"_s, downloadsJson()},
            {u"connection"_s, connectionJson()},
            {u"speed"_s, speedJson()},
            {u"bittorrent"_s, bittorrentJson()},
            {u"rss"_s, rssJson()},
            {u"webui"_s, webuiJson()},
            {u"advanced"_s, advancedJson()}
        };
    }

    using Setter = std::function<void (const QJsonValue &value)>;

    Setter proxySetter(std::function<void (Net::ProxyConfiguration &, const QJsonValue &)> apply)
    {
        return [apply = std::move(apply)](const QJsonValue &v)
        {
            auto *manager = Net::ProxyConfigurationManager::instance();
            Net::ProxyConfiguration conf = manager->proxyConfiguration();
            apply(conf, v);
            manager->setProxyConfiguration(conf);
        };
    }

    // "group.field" -> setter. Fields without a setter are read-only
    // (currentInterfaceName, addTrackersUrlList, webUiApiKey, useSubcategories).
    QHash<QString, Setter> buildSetters()
    {
        auto *pref = Preferences::instance();
        auto *session = BitTorrent::Session::instance();
        NeoApplication *app = CoreHost::instance()->app();

        QHash<QString, Setter> s;
        // Behavior
        s[u"behavior.locale"_s] = [pref](const QJsonValue &v)
        {
            const QString locale = v.toString();
            auto *translator = new QTranslator(qApp);
            if (translator->load(u":/lang/qbittorrent_"_s + locale))
                qApp->installTranslator(translator);
            else
                delete translator;
            pref->setLocale(locale);
        };
        s[u"behavior.performanceWarning"_s] = [session](const QJsonValue &v) { session->setPerformanceWarningEnabled(v.toBool()); };
        s[u"behavior.statusBarExternalIp"_s] = [pref](const QJsonValue &v) { pref->setStatusbarExternalIPDisplayed(v.toBool()); };
        s[u"behavior.confirmTorrentDeletion"_s] = [pref](const QJsonValue &v) { pref->setConfirmTorrentDeletion(v.toBool()); };
        s[u"behavior.fileLogEnabled"_s] = [app](const QJsonValue &v) { app->setFileLoggerEnabled(v.toBool()); };
        s[u"behavior.fileLogPath"_s] = [app](const QJsonValue &v) { app->setFileLoggerPath(Path(v.toString())); };
        s[u"behavior.fileLogBackupEnabled"_s] = [app](const QJsonValue &v) { app->setFileLoggerBackup(v.toBool()); };
        s[u"behavior.fileLogMaxSize"_s] = [app](const QJsonValue &v) { app->setFileLoggerMaxSize(toInt(v) * 1024); };
        s[u"behavior.fileLogDeleteOld"_s] = [app](const QJsonValue &v) { app->setFileLoggerDeleteOld(v.toBool()); };
        s[u"behavior.fileLogAge"_s] = [app](const QJsonValue &v) { app->setFileLoggerAge(toInt(v)); };
        s[u"behavior.fileLogAgeType"_s] = [app](const QJsonValue &v) { app->setFileLoggerAgeType(FILE_LOG_AGE_TYPES.value(v.toString())); };
        s[u"behavior.deleteTorrentContentFiles"_s] = [pref](const QJsonValue &v) { pref->setRemoveTorrentContent(v.toBool()); };

        // Downloads
        s[u"downloads.torrentContentLayout"_s] = [session](const QJsonValue &v) { session->setTorrentContentLayout(parseContentLayout(v.toString())); };
        s[u"downloads.addToTopOfQueue"_s] = [session](const QJsonValue &v) { session->setAddTorrentToQueueTop(v.toBool()); };
        s[u"downloads.addStoppedEnabled"_s] = [session](const QJsonValue &v) { session->setAddTorrentStopped(v.toBool()); };
        s[u"downloads.torrentStopCondition"_s] = [session](const QJsonValue &v) { session->setTorrentStopCondition(parseStopCondition(v.toString())); };
        s[u"downloads.mergeTrackers"_s] = [session](const QJsonValue &v) { session->setMergeTrackersEnabled(v.toBool()); };
        s[u"downloads.autoDeleteMode"_s] = [](const QJsonValue &v) { TorrentFileGuard::setAutoDeleteMode(AUTO_DELETE_MODES.value(v.toString())); };
        s[u"downloads.preallocateAll"_s] = [session](const QJsonValue &v) { session->setPreallocationEnabled(v.toBool()); };
        s[u"downloads.incompleteFilesExt"_s] = [session](const QJsonValue &v) { session->setAppendExtensionEnabled(v.toBool()); };
        s[u"downloads.useUnwantedFolder"_s] = [session](const QJsonValue &v) { session->setUnwantedFolderEnabled(v.toBool()); };
        s[u"downloads.autoTmmEnabled"_s] = [session](const QJsonValue &v) { session->setAutoTMMDisabledByDefault(!v.toBool()); };
        s[u"downloads.torrentChangedTmmEnabled"_s] = [session](const QJsonValue &v) { session->setDisableAutoTMMWhenCategoryChanged(!v.toBool()); };
        s[u"downloads.savePathChangedTmmEnabled"_s] = [session](const QJsonValue &v) { session->setDisableAutoTMMWhenDefaultSavePathChanged(!v.toBool()); };
        s[u"downloads.categoryChangedTmmEnabled"_s] = [session](const QJsonValue &v) { session->setDisableAutoTMMWhenCategorySavePathChanged(!v.toBool()); };
        s[u"downloads.savePath"_s] = [session](const QJsonValue &v) { session->setSavePath(Path(v.toString())); };
        s[u"downloads.tempPathEnabled"_s] = [session](const QJsonValue &v) { session->setDownloadPathEnabled(v.toBool()); };
        s[u"downloads.tempPath"_s] = [session](const QJsonValue &v) { session->setDownloadPath(Path(v.toString())); };
        s[u"downloads.useCategoryPathsInManualMode"_s] = [session](const QJsonValue &v) { session->setUseCategoryPathsInManualMode(v.toBool()); };
        s[u"downloads.exportDir"_s] = [session](const QJsonValue &v) { session->setTorrentExportDirectory(Path(v.toString())); };
        s[u"downloads.exportDirFin"_s] = [session](const QJsonValue &v) { session->setFinishedTorrentExportDirectory(Path(v.toString())); };
        s[u"downloads.watchedFolders"_s] = setWatchedFolders;
        s[u"downloads.excludedFileNamesEnabled"_s] = [session](const QJsonValue &v) { session->setExcludedFileNamesEnabled(v.toBool()); };
        s[u"downloads.excludedFileNames"_s] = [session](const QJsonValue &v) { session->setExcludedFileNames(stringList(v)); };
        s[u"downloads.mailNotificationEnabled"_s] = [pref](const QJsonValue &v) { pref->setMailNotificationEnabled(v.toBool()); };
        s[u"downloads.mailNotificationSender"_s] = [pref](const QJsonValue &v) { pref->setMailNotificationSender(v.toString()); };
        s[u"downloads.mailNotificationEmail"_s] = [pref](const QJsonValue &v) { pref->setMailNotificationEmail(v.toString()); };
        s[u"downloads.mailNotificationSmtp"_s] = [pref](const QJsonValue &v) { pref->setMailNotificationSMTP(v.toString()); };
        s[u"downloads.mailNotificationSslEnabled"_s] = [pref](const QJsonValue &v) { pref->setMailNotificationSMTPSSL(v.toBool()); };
        s[u"downloads.mailNotificationAuthEnabled"_s] = [pref](const QJsonValue &v) { pref->setMailNotificationSMTPAuth(v.toBool()); };
        s[u"downloads.mailNotificationUsername"_s] = [pref](const QJsonValue &v) { pref->setMailNotificationSMTPUsername(v.toString()); };
        s[u"downloads.mailNotificationPassword"_s] = [pref](const QJsonValue &v) { pref->setMailNotificationSMTPPassword(v.toString()); };
        s[u"downloads.autorunOnTorrentAddedEnabled"_s] = [pref](const QJsonValue &v) { pref->setAutoRunOnTorrentAddedEnabled(v.toBool()); };
        s[u"downloads.autorunOnTorrentAddedProgram"_s] = [pref](const QJsonValue &v) { pref->setAutoRunOnTorrentAddedProgram(v.toString().trimmed()); };
        s[u"downloads.autorunEnabled"_s] = [pref](const QJsonValue &v) { pref->setAutoRunOnTorrentFinishedEnabled(v.toBool()); };
        s[u"downloads.autorunProgram"_s] = [pref](const QJsonValue &v) { pref->setAutoRunOnTorrentFinishedProgram(v.toString().trimmed()); };

        // Connection
        s[u"connection.bittorrentProtocol"_s] = [session](const QJsonValue &v) { session->setBTProtocol(BT_PROTOCOLS.value(v.toString())); };
        s[u"connection.listenPort"_s] = [session](const QJsonValue &v) { session->setPort(toInt(v)); };
        s[u"connection.sslEnabled"_s] = [session](const QJsonValue &v) { session->setSSLEnabled(v.toBool()); };
        s[u"connection.sslListenPort"_s] = [session](const QJsonValue &v) { session->setSSLPort(toInt(v)); };
        s[u"connection.upnp"_s] = [](const QJsonValue &v) { Net::PortForwarder::instance()->setEnabled(v.toBool()); };
        s[u"connection.maxConnec"_s] = [session](const QJsonValue &v) { session->setMaxConnections(toInt(v)); };
        s[u"connection.maxConnecPerTorrent"_s] = [session](const QJsonValue &v) { session->setMaxConnectionsPerTorrent(toInt(v)); };
        s[u"connection.maxUploads"_s] = [session](const QJsonValue &v) { session->setMaxUploads(toInt(v)); };
        s[u"connection.maxUploadsPerTorrent"_s] = [session](const QJsonValue &v) { session->setMaxUploadsPerTorrent(toInt(v)); };
        s[u"connection.i2pEnabled"_s] = [session](const QJsonValue &v) { session->setI2PEnabled(v.toBool()); };
        s[u"connection.i2pAddress"_s] = [session](const QJsonValue &v) { session->setI2PAddress(v.toString()); };
        s[u"connection.i2pPort"_s] = [session](const QJsonValue &v) { session->setI2PPort(toInt(v)); };
        s[u"connection.i2pMixedMode"_s] = [session](const QJsonValue &v) { session->setI2PMixedMode(v.toBool()); };
        s[u"connection.i2pInboundQuantity"_s] = [session](const QJsonValue &v) { session->setI2PInboundQuantity(toInt(v)); };
        s[u"connection.i2pOutboundQuantity"_s] = [session](const QJsonValue &v) { session->setI2POutboundQuantity(toInt(v)); };
        s[u"connection.i2pInboundLength"_s] = [session](const QJsonValue &v) { session->setI2PInboundLength(toInt(v)); };
        s[u"connection.i2pOutboundLength"_s] = [session](const QJsonValue &v) { session->setI2POutboundLength(toInt(v)); };
        s[u"connection.proxyType"_s] = proxySetter([](Net::ProxyConfiguration &c, const QJsonValue &v) { c.type = PROXY_TYPES.value(v.toString()); });
        s[u"connection.proxyIp"_s] = proxySetter([](Net::ProxyConfiguration &c, const QJsonValue &v) { c.ip = v.toString(); });
        s[u"connection.proxyPort"_s] = proxySetter([](Net::ProxyConfiguration &c, const QJsonValue &v) { c.port = static_cast<ushort>(toInt(v)); });
        s[u"connection.proxyAuthEnabled"_s] = proxySetter([](Net::ProxyConfiguration &c, const QJsonValue &v) { c.authEnabled = v.toBool(); });
        s[u"connection.proxyUsername"_s] = proxySetter([](Net::ProxyConfiguration &c, const QJsonValue &v) { c.username = v.toString(); });
        s[u"connection.proxyPassword"_s] = proxySetter([](Net::ProxyConfiguration &c, const QJsonValue &v) { c.password = v.toString(); });
        s[u"connection.proxyHostnameLookup"_s] = proxySetter([](Net::ProxyConfiguration &c, const QJsonValue &v) { c.hostnameLookupEnabled = v.toBool(); });
        s[u"connection.proxyBittorrent"_s] = [pref](const QJsonValue &v) { pref->setUseProxyForBT(v.toBool()); };
        s[u"connection.proxyPeerConnections"_s] = [session](const QJsonValue &v) { session->setProxyPeerConnectionsEnabled(v.toBool()); };
        s[u"connection.proxyRss"_s] = [pref](const QJsonValue &v) { pref->setUseProxyForRSS(v.toBool()); };
        s[u"connection.proxyMisc"_s] = [pref](const QJsonValue &v) { pref->setUseProxyForGeneralPurposes(v.toBool()); };
        s[u"connection.ipFilterEnabled"_s] = [session](const QJsonValue &v) { session->setIPFilteringEnabled(v.toBool()); };
        s[u"connection.ipFilterPath"_s] = [session](const QJsonValue &v) { session->setIPFilterFile(Path(v.toString())); };
        s[u"connection.ipFilterTrackers"_s] = [session](const QJsonValue &v) { session->setTrackerFilteringEnabled(v.toBool()); };
        s[u"connection.bannedIps"_s] = [session](const QJsonValue &v) { session->setBannedIPs(stringList(v)); };

        // Speed
        s[u"speed.dlLimit"_s] = [session](const QJsonValue &v) { session->setGlobalDownloadSpeedLimit(toInt(v)); };
        s[u"speed.upLimit"_s] = [session](const QJsonValue &v) { session->setGlobalUploadSpeedLimit(toInt(v)); };
        s[u"speed.altDlLimit"_s] = [session](const QJsonValue &v) { session->setAltGlobalDownloadSpeedLimit(toInt(v)); };
        s[u"speed.altUpLimit"_s] = [session](const QJsonValue &v) { session->setAltGlobalUploadSpeedLimit(toInt(v)); };
        s[u"speed.limitUtpRate"_s] = [session](const QJsonValue &v) { session->setUTPRateLimited(v.toBool()); };
        s[u"speed.limitTcpOverhead"_s] = [session](const QJsonValue &v) { session->setIncludeOverheadInLimits(v.toBool()); };
        s[u"speed.limitLanPeers"_s] = [session](const QJsonValue &v) { session->setIgnoreLimitsOnLAN(!v.toBool()); };
        s[u"speed.schedulerEnabled"_s] = [session](const QJsonValue &v) { session->setBandwidthSchedulerEnabled(v.toBool()); };
        s[u"speed.scheduleFromHour"_s] = [pref](const QJsonValue &v) { pref->setSchedulerStartTime({toInt(v), pref->getSchedulerStartTime().minute()}); };
        s[u"speed.scheduleFromMin"_s] = [pref](const QJsonValue &v) { pref->setSchedulerStartTime({pref->getSchedulerStartTime().hour(), toInt(v)}); };
        s[u"speed.scheduleToHour"_s] = [pref](const QJsonValue &v) { pref->setSchedulerEndTime({toInt(v), pref->getSchedulerEndTime().minute()}); };
        s[u"speed.scheduleToMin"_s] = [pref](const QJsonValue &v) { pref->setSchedulerEndTime({pref->getSchedulerEndTime().hour(), toInt(v)}); };
        s[u"speed.schedulerDays"_s] = [pref](const QJsonValue &v) { pref->setSchedulerDays(SCHEDULER_DAYS.value(v.toString())); };

        // BitTorrent
        s[u"bittorrent.dht"_s] = [session](const QJsonValue &v) { session->setDHTEnabled(v.toBool()); };
        s[u"bittorrent.pex"_s] = [session](const QJsonValue &v) { session->setPeXEnabled(v.toBool()); };
        s[u"bittorrent.lsd"_s] = [session](const QJsonValue &v) { session->setLSDEnabled(v.toBool()); };
        s[u"bittorrent.encryption"_s] = [session](const QJsonValue &v) { session->setEncryption(ENCRYPTION_MODES.value(v.toString())); };
        s[u"bittorrent.anonymousMode"_s] = [session](const QJsonValue &v) { session->setAnonymousModeEnabled(v.toBool()); };
        s[u"bittorrent.maxActiveCheckingTorrents"_s] = [session](const QJsonValue &v) { session->setMaxActiveCheckingTorrents(toInt(v)); };
        s[u"bittorrent.queueingEnabled"_s] = [session](const QJsonValue &v) { session->setQueueingSystemEnabled(v.toBool()); };
        s[u"bittorrent.maxActiveDownloads"_s] = [session](const QJsonValue &v) { session->setMaxActiveDownloads(toInt(v)); };
        s[u"bittorrent.maxActiveTorrents"_s] = [session](const QJsonValue &v) { session->setMaxActiveTorrents(toInt(v)); };
        s[u"bittorrent.maxActiveUploads"_s] = [session](const QJsonValue &v) { session->setMaxActiveUploads(toInt(v)); };
        s[u"bittorrent.dontCountSlowTorrents"_s] = [session](const QJsonValue &v) { session->setIgnoreSlowTorrentsForQueueing(v.toBool()); };
        s[u"bittorrent.slowTorrentDlRateThreshold"_s] = [session](const QJsonValue &v) { session->setDownloadRateForSlowTorrents(toInt(v)); };
        s[u"bittorrent.slowTorrentUlRateThreshold"_s] = [session](const QJsonValue &v) { session->setUploadRateForSlowTorrents(toInt(v)); };
        s[u"bittorrent.slowTorrentInactiveTimer"_s] = [session](const QJsonValue &v) { session->setSlowTorrentsInactivityTimer(toInt(v)); };
        s[u"bittorrent.maxRatio"_s] = [session](const QJsonValue &v) { session->setGlobalMaxRatio((v.toDouble() < 0) ? -1 : v.toDouble()); };
        s[u"bittorrent.maxSeedingTime"_s] = [session](const QJsonValue &v) { session->setGlobalMaxSeedingMinutes(std::max(toInt(v), -1)); };
        s[u"bittorrent.maxInactiveSeedingTime"_s] = [session](const QJsonValue &v) { session->setGlobalMaxInactiveSeedingMinutes(std::max(toInt(v), -1)); };
        s[u"bittorrent.maxRatioAct"_s] = [session](const QJsonValue &v)
        {
            const BitTorrent::ShareLimitAction action = parseShareLimitAction(v.toString());
            session->setShareLimitAction((action == BitTorrent::ShareLimitAction::Default) ? BitTorrent::ShareLimitAction::Stop : action);
        };
        s[u"bittorrent.addTrackersEnabled"_s] = [session](const QJsonValue &v) { session->setAddTrackersEnabled(v.toBool()); };
        s[u"bittorrent.addTrackers"_s] = [session](const QJsonValue &v) { session->setAdditionalTrackers(v.toString()); };
        s[u"bittorrent.addTrackersFromUrlEnabled"_s] = [session](const QJsonValue &v) { session->setAddTrackersFromURLEnabled(v.toBool()); };
        s[u"bittorrent.addTrackersUrl"_s] = [session](const QJsonValue &v) { session->setAdditionalTrackersURL(v.toString()); };

        // RSS (only once the RSS session exists)
        if (RSS::Session::instance() && RSS::AutoDownloader::instance())
        {
            s[u"rss.rssRefreshInterval"_s] = [](const QJsonValue &v) { RSS::Session::instance()->setRefreshInterval(toInt(v)); };
            s[u"rss.rssFetchDelay"_s] = [](const QJsonValue &v) { RSS::Session::instance()->setFetchDelay(std::chrono::seconds(toInt(v))); };
            s[u"rss.rssMaxArticlesPerFeed"_s] = [](const QJsonValue &v) { RSS::Session::instance()->setMaxArticlesPerFeed(toInt(v)); };
            s[u"rss.rssProcessingEnabled"_s] = [](const QJsonValue &v) { RSS::Session::instance()->setProcessingEnabled(v.toBool()); };
            s[u"rss.rssAutoDownloadingEnabled"_s] = [](const QJsonValue &v) { RSS::AutoDownloader::instance()->setProcessingEnabled(v.toBool()); };
            s[u"rss.rssDownloadRepackProperEpisodes"_s] = [](const QJsonValue &v) { RSS::AutoDownloader::instance()->setDownloadRepacks(v.toBool()); };
            s[u"rss.rssSmartEpisodeFilters"_s] = [](const QJsonValue &v) { RSS::AutoDownloader::instance()->setSmartEpisodeFilters(stringList(v)); };
        }

        // WebUI
        s[u"webui.webUiEnabled"_s] = [pref](const QJsonValue &v) { pref->setWebUIEnabled(v.toBool()); };
        s[u"webui.webUiDomainList"_s] = [pref](const QJsonValue &v) { pref->setServerDomains(v.toString()); };
        s[u"webui.webUiAddress"_s] = [pref](const QJsonValue &v) { pref->setWebUIAddress(v.toString()); };
        s[u"webui.webUiPort"_s] = [pref](const QJsonValue &v) { pref->setWebUIPort(static_cast<quint16>(toInt(v))); };
        s[u"webui.webUiUpnp"_s] = [pref](const QJsonValue &v) { pref->setUPnPForWebUIPort(v.toBool()); };
        s[u"webui.useHttps"_s] = [pref](const QJsonValue &v) { pref->setWebUIHttpsEnabled(v.toBool()); };
        s[u"webui.webUiHttpsCertPath"_s] = [pref](const QJsonValue &v) { pref->setWebUIHttpsCertificatePath(Path(v.toString())); };
        s[u"webui.webUiHttpsKeyPath"_s] = [pref](const QJsonValue &v) { pref->setWebUIHttpsKeyPath(Path(v.toString())); };
        s[u"webui.webUiUsername"_s] = [pref](const QJsonValue &v)
        {
            const QString username = v.toString();
            if (username.length() < 3)
                throwInvalid(QCoreApplication::translate("AppController", "WebUI username must be at least 3 characters long"));
            if (username.contains(u':'))
                throwInvalid(QCoreApplication::translate("AppController", "WebUI username cannot contain a colon"));
            pref->setWebUIUsername(username);
        };
        // Only an empty value (no password) or an already hashed one is
        // accepted; plain passwords go through setPreferencesJson.
        s[u"webui.webUiPasswordPbkdf2"_s] = [pref](const QJsonValue &v)
        {
            const QByteArray hash = v.toString().toLatin1();
            if (hash.isEmpty() || hash.contains(':'))
                pref->setWebUIPassword(hash);
        };
        s[u"webui.bypassLocalAuth"_s] = [pref](const QJsonValue &v) { pref->setWebUILocalAuthEnabled(!v.toBool()); };
        s[u"webui.bypassAuthSubnetWhitelistEnabled"_s] = [pref](const QJsonValue &v) { pref->setWebUIAuthSubnetWhitelistEnabled(v.toBool()); };
        s[u"webui.bypassAuthSubnetWhitelist"_s] = [pref](const QJsonValue &v) { pref->setWebUIAuthSubnetWhitelist(stringList(v)); };
        s[u"webui.webUiMaxAuthFailCount"_s] = [pref](const QJsonValue &v) { pref->setWebUIMaxAuthFailCount(toInt(v)); };
        s[u"webui.webUiBanDuration"_s] = [pref](const QJsonValue &v) { pref->setWebUIBanDuration(std::chrono::seconds(toInt(v))); };
        s[u"webui.webUiSessionTimeout"_s] = [pref](const QJsonValue &v) { pref->setWebUISessionTimeout(toInt(v)); };
        s[u"webui.alternativeWebuiEnabled"_s] = [pref](const QJsonValue &v) { pref->setAltWebUIEnabled(v.toBool()); };
        s[u"webui.alternativeWebuiPath"_s] = [pref](const QJsonValue &v) { pref->setWebUIRootFolder(Path(v.toString())); };
        s[u"webui.webUiClickjackingProtectionEnabled"_s] = [pref](const QJsonValue &v) { pref->setWebUIClickjackingProtectionEnabled(v.toBool()); };
        s[u"webui.webUiCsrfProtectionEnabled"_s] = [pref](const QJsonValue &v) { pref->setWebUICSRFProtectionEnabled(v.toBool()); };
        s[u"webui.webUiSecureCookieEnabled"_s] = [pref](const QJsonValue &v) { pref->setWebUISecureCookieEnabled(v.toBool()); };
        s[u"webui.webUiHostHeaderValidationEnabled"_s] = [pref](const QJsonValue &v) { pref->setWebUIHostHeaderValidationEnabled(v.toBool()); };
        s[u"webui.webUiUseCustomHttpHeadersEnabled"_s] = [pref](const QJsonValue &v) { pref->setWebUICustomHTTPHeadersEnabled(v.toBool()); };
        s[u"webui.webUiCustomHttpHeaders"_s] = [pref](const QJsonValue &v) { pref->setWebUICustomHTTPHeaders(v.toString()); };
        s[u"webui.webUiReverseProxyEnabled"_s] = [pref](const QJsonValue &v) { pref->setWebUIReverseProxySupportEnabled(v.toBool()); };
        s[u"webui.webUiReverseProxiesList"_s] = [pref](const QJsonValue &v) { pref->setWebUITrustedReverseProxiesList(v.toString()); };
        s[u"webui.dyndnsEnabled"_s] = [pref](const QJsonValue &v) { pref->setDynDNSEnabled(v.toBool()); };
        s[u"webui.dyndnsService"_s] = [pref](const QJsonValue &v) { pref->setDynDNSService(DYNDNS_SERVICES.value(v.toString())); };
        s[u"webui.dyndnsUsername"_s] = [pref](const QJsonValue &v) { pref->setDynDNSUsername(v.toString()); };
        s[u"webui.dyndnsPassword"_s] = [pref](const QJsonValue &v) { pref->setDynDNSPassword(v.toString()); };
        s[u"webui.dyndnsDomain"_s] = [pref](const QJsonValue &v) { pref->setDynDomainName(v.toString()); };

        // Advanced
        s[u"advanced.resumeDataStorageType"_s] = [session](const QJsonValue &v) { session->setResumeDataStorageType(RESUME_STORAGE_TYPES.value(v.toString())); };
        s[u"advanced.torrentContentRemoveOption"_s] = [session](const QJsonValue &v) { session->setTorrentContentRemoveOption(CONTENT_REMOVE_OPTIONS.value(v.toString())); };
        s[u"advanced.memoryWorkingSetLimit"_s] = [app](const QJsonValue &v) { app->setMemoryWorkingSetLimit(toInt(v)); };
        s[u"advanced.currentNetworkInterface"_s] = [session](const QJsonValue &v)
        {
            const QString value = v.toString();
            QString name;
            for (const QNetworkInterface &iface : asConst(QNetworkInterface::allInterfaces()))
            {
                if (!iface.addressEntries().isEmpty() && (iface.name() == value))
                    name = iface.humanReadableName();
            }
            session->setNetworkInterface(value);
            if (!name.isEmpty() || value.isEmpty())
                session->setNetworkInterfaceName(name);
        };
        s[u"advanced.currentInterfaceAddress"_s] = [session](const QJsonValue &v)
        {
            const QHostAddress address {v.toString().trimmed()};
            session->setNetworkInterfaceAddress(address.isNull() ? QString() : address.toString());
        };
        s[u"advanced.saveResumeDataInterval"_s] = [session](const QJsonValue &v) { session->setSaveResumeDataInterval(toInt(v)); };
        s[u"advanced.saveStatisticsInterval"_s] = [session](const QJsonValue &v) { session->setSaveStatisticsInterval(std::chrono::minutes(toInt(v))); };
        s[u"advanced.torrentFileSizeLimit"_s] = [pref](const QJsonValue &v) { pref->setTorrentFileSizeLimit(v.toInteger()); };
        s[u"advanced.confirmTorrentRecheck"_s] = [pref](const QJsonValue &v) { pref->setConfirmTorrentRecheck(v.toBool()); };
        s[u"advanced.recheckCompletedTorrents"_s] = [pref](const QJsonValue &v) { pref->recheckTorrentsOnCompletion(v.toBool()); };
        s[u"advanced.appInstanceName"_s] = [app](const QJsonValue &v) { app->setInstanceName(v.toString()); };
        s[u"advanced.refreshInterval"_s] = [session](const QJsonValue &v) { session->setRefreshInterval(toInt(v)); };
        s[u"advanced.resolvePeerHostNames"_s] = [pref](const QJsonValue &v) { pref->resolvePeerHostNames(v.toBool()); };
        s[u"advanced.resolvePeerCountries"_s] = [pref](const QJsonValue &v) { pref->resolvePeerCountries(v.toBool()); };
        s[u"advanced.reannounceWhenAddressChanged"_s] = [session](const QJsonValue &v) { session->setReannounceWhenAddressChangedEnabled(v.toBool()); };
        s[u"advanced.enableEmbeddedTracker"_s] = [session](const QJsonValue &v) { session->setTrackerEnabled(v.toBool()); };
        s[u"advanced.embeddedTrackerPort"_s] = [pref](const QJsonValue &v) { pref->setTrackerPort(toInt(v)); };
        s[u"advanced.embeddedTrackerPortForwarding"_s] = [pref](const QJsonValue &v) { pref->setTrackerPortForwardingEnabled(v.toBool()); };
        s[u"advanced.markOfTheWeb"_s] = [pref](const QJsonValue &v) { pref->setMarkOfTheWebEnabled(v.toBool()); };
        s[u"advanced.ignoreSslErrors"_s] = [pref](const QJsonValue &v) { pref->setIgnoreSSLErrors(v.toBool()); };
        s[u"advanced.pythonExecutablePath"_s] = [pref](const QJsonValue &v) { pref->setPythonExecutablePath(Path(v.toString())); };
        s[u"advanced.startPaused"_s] = [session](const QJsonValue &v) { session->setStartPaused(v.toBool()); };
        s[u"advanced.shutdownTimeout"_s] = [session](const QJsonValue &v) { session->setShutdownTimeout(toInt(v)); };
        s[u"advanced.bdecodeDepthLimit"_s] = [pref](const QJsonValue &v) { pref->setBdecodeDepthLimit(toInt(v)); };
        s[u"advanced.bdecodeTokenLimit"_s] = [pref](const QJsonValue &v) { pref->setBdecodeTokenLimit(toInt(v)); };
        s[u"advanced.asyncIoThreads"_s] = [session](const QJsonValue &v) { session->setAsyncIOThreads(toInt(v)); };
        s[u"advanced.hashingThreads"_s] = [session](const QJsonValue &v) { session->setHashingThreads(toInt(v)); };
        s[u"advanced.filePoolSize"_s] = [session](const QJsonValue &v) { session->setFilePoolSize(toInt(v)); };
        s[u"advanced.checkingMemoryUse"_s] = [session](const QJsonValue &v) { session->setCheckingMemUsage(toInt(v)); };
        s[u"advanced.diskCache"_s] = [session](const QJsonValue &v) { session->setDiskCacheSize(toInt(v)); };
        s[u"advanced.diskCacheTtl"_s] = [session](const QJsonValue &v) { session->setDiskCacheTTL(toInt(v)); };
        s[u"advanced.diskQueueSize"_s] = [session](const QJsonValue &v) { session->setDiskQueueSize(v.toInteger()); };
        s[u"advanced.diskIoType"_s] = [session](const QJsonValue &v) { session->setDiskIOType(DISK_IO_TYPES.value(v.toString())); };
        s[u"advanced.diskIoReadMode"_s] = [session](const QJsonValue &v) { session->setDiskIOReadMode(DISK_IO_READ_MODES.value(v.toString())); };
        s[u"advanced.diskIoWriteMode"_s] = [session](const QJsonValue &v) { session->setDiskIOWriteMode(DISK_IO_WRITE_MODES.value(v.toString())); };
        s[u"advanced.enableCoalesceReadWrite"_s] = [session](const QJsonValue &v) { session->setCoalesceReadWriteEnabled(v.toBool()); };
        s[u"advanced.enablePieceExtentAffinity"_s] = [session](const QJsonValue &v) { session->setPieceExtentAffinity(v.toBool()); };
        s[u"advanced.enableUploadSuggestions"_s] = [session](const QJsonValue &v) { session->setSuggestMode(v.toBool()); };
        s[u"advanced.sendBufferWatermark"_s] = [session](const QJsonValue &v) { session->setSendBufferWatermark(toInt(v)); };
        s[u"advanced.sendBufferLowWatermark"_s] = [session](const QJsonValue &v) { session->setSendBufferLowWatermark(toInt(v)); };
        s[u"advanced.sendBufferWatermarkFactor"_s] = [session](const QJsonValue &v) { session->setSendBufferWatermarkFactor(toInt(v)); };
        s[u"advanced.connectionSpeed"_s] = [session](const QJsonValue &v) { session->setConnectionSpeed(toInt(v)); };
        s[u"advanced.socketSendBufferSize"_s] = [session](const QJsonValue &v) { session->setSocketSendBufferSize(toInt(v)); };
        s[u"advanced.socketReceiveBufferSize"_s] = [session](const QJsonValue &v) { session->setSocketReceiveBufferSize(toInt(v)); };
        s[u"advanced.socketBacklogSize"_s] = [session](const QJsonValue &v) { session->setSocketBacklogSize(toInt(v)); };
        s[u"advanced.outgoingPortsMin"_s] = [session](const QJsonValue &v) { session->setOutgoingPortsMin(toInt(v)); };
        s[u"advanced.outgoingPortsMax"_s] = [session](const QJsonValue &v) { session->setOutgoingPortsMax(toInt(v)); };
        s[u"advanced.upnpLeaseDuration"_s] = [session](const QJsonValue &v) { session->setUPnPLeaseDuration(toInt(v)); };
        s[u"advanced.peerTos"_s] = [session](const QJsonValue &v) { session->setPeerDSCP(toInt(v)); };
        s[u"advanced.utpTcpMixedMode"_s] = [session](const QJsonValue &v) { session->setUtpMixedMode(UTP_MIXED_MODES.value(v.toString())); };
        s[u"advanced.hostnameCacheTtl"_s] = [session](const QJsonValue &v) { session->setHostnameCacheTTL(toInt(v)); };
        s[u"advanced.idnSupportEnabled"_s] = [session](const QJsonValue &v) { session->setIDNSupportEnabled(v.toBool()); };
        s[u"advanced.enableMultiConnectionsFromSameIp"_s] = [session](const QJsonValue &v) { session->setMultiConnectionsPerIpEnabled(v.toBool()); };
        s[u"advanced.validateHttpsTrackerCertificate"_s] = [session](const QJsonValue &v) { session->setValidateHTTPSTrackerCertificate(v.toBool()); };
        s[u"advanced.ssrfMitigation"_s] = [session](const QJsonValue &v) { session->setSSRFMitigationEnabled(v.toBool()); };
        s[u"advanced.blockPeersOnPrivilegedPorts"_s] = [session](const QJsonValue &v) { session->setBlockPeersOnPrivilegedPorts(v.toBool()); };
        s[u"advanced.uploadSlotsBehavior"_s] = [session](const QJsonValue &v) { session->setChokingAlgorithm(CHOKING_ALGORITHMS.value(v.toString())); };
        s[u"advanced.uploadChokingAlgorithm"_s] = [session](const QJsonValue &v) { session->setSeedChokingAlgorithm(SEED_CHOKING_ALGORITHMS.value(v.toString())); };
        s[u"advanced.announceToAllTrackers"_s] = [session](const QJsonValue &v) { session->setAnnounceToAllTrackers(v.toBool()); };
        s[u"advanced.announceToAllTiers"_s] = [session](const QJsonValue &v) { session->setAnnounceToAllTiers(v.toBool()); };
        s[u"advanced.announceIp"_s] = [session](const QJsonValue &v)
        {
            const QHostAddress address {v.toString().trimmed()};
            session->setAnnounceIP(address.isNull() ? QString() : address.toString());
        };
        s[u"advanced.announcePort"_s] = [session](const QJsonValue &v) { session->setAnnouncePort(toInt(v)); };
        s[u"advanced.maxConcurrentHttpAnnounces"_s] = [session](const QJsonValue &v) { session->setMaxConcurrentHTTPAnnounces(toInt(v)); };
        s[u"advanced.stopTrackerTimeout"_s] = [session](const QJsonValue &v) { session->setStopTrackerTimeout(toInt(v)); };
        s[u"advanced.peerTurnover"_s] = [session](const QJsonValue &v) { session->setPeerTurnover(toInt(v)); };
        s[u"advanced.peerTurnoverCutoff"_s] = [session](const QJsonValue &v) { session->setPeerTurnoverCutoff(toInt(v)); };
        s[u"advanced.peerTurnoverInterval"_s] = [session](const QJsonValue &v) { session->setPeerTurnoverInterval(toInt(v)); };
        s[u"advanced.requestQueueSize"_s] = [session](const QJsonValue &v) { session->setRequestQueueSize(toInt(v)); };
        s[u"advanced.dhtBootstrapNodes"_s] = [session](const QJsonValue &v) { session->setDHTBootstrapNodes(v.toString()); };
        return s;
    }

    void applyPreferences(const QJsonObject &incoming)
    {
        const QJsonObject current = preferencesJson();
        const QHash<QString, Setter> setters = buildSetters();
        for (auto group = incoming.begin(); group != incoming.end(); ++group)
        {
            const QJsonObject fields = group.value().toObject();
            const QJsonObject currentFields = current.value(group.key()).toObject();
            for (auto field = fields.begin(); field != fields.end(); ++field)
            {
                if (currentFields.value(field.key()) == field.value())
                    continue;
                const auto setter = setters.constFind(group.key() + u'.' + field.key());
                if (setter != setters.cend())
                    setter.value()(field.value());
            }
        }
        Preferences::instance()->apply();
    }
}

void Neo::registerPreferencesApi(Registry &registry)
{
    registry.add(u"preferences"_s, [](const QJsonObject &)
    {
        return preferencesJson();
    });
    registry.add(u"setPreferences"_s, [](const QJsonObject &args)
    {
        applyPreferences(argObject(args, u"prefs"_s));
        return QJsonValue();
    });
}
