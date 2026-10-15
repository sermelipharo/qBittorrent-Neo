import Foundation

// qBittorrent's default preferences. Used by `DemoClient` and SwiftUI
// previews; the real core always returns its own persisted values.
extension Preferences {
    static let qbtDefaults = Preferences(
        behavior: .qbtDefaults,
        downloads: .qbtDefaults,
        connection: .qbtDefaults,
        speed: .qbtDefaults,
        bittorrent: .qbtDefaults,
        rss: .qbtDefaults,
        webui: .qbtDefaults,
        advanced: .qbtDefaults
    )
}

extension BehaviorPrefs {
    static let qbtDefaults = BehaviorPrefs(
        locale: "", performanceWarning: false, statusBarExternalIp: false, confirmTorrentDeletion: true,
        fileLogEnabled: true, fileLogPath: "", fileLogBackupEnabled: true, fileLogMaxSize: 65,
        fileLogDeleteOld: true, fileLogAge: 1, fileLogAgeType: .months, deleteTorrentContentFiles: false
    )
}

extension DownloadsPrefs {
    static let qbtDefaults = DownloadsPrefs(
        torrentContentLayout: .original, addToTopOfQueue: false, addStoppedEnabled: false,
        torrentStopCondition: .none, mergeTrackers: false, autoDeleteMode: .never, preallocateAll: false,
        incompleteFilesExt: false, useUnwantedFolder: false, autoTmmEnabled: false,
        torrentChangedTmmEnabled: true, savePathChangedTmmEnabled: false, categoryChangedTmmEnabled: false,
        useSubcategories: false, savePath: "", tempPathEnabled: false, tempPath: "",
        useCategoryPathsInManualMode: false, exportDir: "", exportDirFin: "", watchedFolders: [],
        excludedFileNamesEnabled: false, excludedFileNames: [], mailNotificationEnabled: false,
        mailNotificationSender: "qBittorrent_notification@example.com", mailNotificationEmail: "",
        mailNotificationSmtp: "smtp.changeme.com", mailNotificationSslEnabled: false,
        mailNotificationAuthEnabled: false, mailNotificationUsername: "", mailNotificationPassword: "",
        autorunOnTorrentAddedEnabled: false, autorunOnTorrentAddedProgram: "", autorunEnabled: false,
        autorunProgram: ""
    )
}

extension ConnectionPrefs {
    static let qbtDefaults = ConnectionPrefs(
        bittorrentProtocol: .both, listenPort: -1, sslEnabled: false, sslListenPort: -1, upnp: true,
        maxConnec: 500, maxConnecPerTorrent: 100, maxUploads: 20, maxUploadsPerTorrent: 4,
        i2pEnabled: false, i2pAddress: "127.0.0.1", i2pPort: 7656, i2pMixedMode: false,
        i2pInboundQuantity: 3, i2pOutboundQuantity: 3, i2pInboundLength: 3, i2pOutboundLength: 3,
        proxyType: .none, proxyIp: "", proxyPort: 8080, proxyAuthEnabled: false, proxyUsername: "",
        proxyPassword: "", proxyHostnameLookup: true, proxyBittorrent: false, proxyPeerConnections: false,
        proxyRss: false, proxyMisc: false, ipFilterEnabled: false, ipFilterPath: "", ipFilterTrackers: false,
        bannedIps: []
    )
}

extension SpeedPrefs {
    static let qbtDefaults = SpeedPrefs(
        dlLimit: 0, upLimit: 0, altDlLimit: 10240, altUpLimit: 10240, limitUtpRate: true,
        limitTcpOverhead: false, limitLanPeers: true, schedulerEnabled: false, scheduleFromHour: 8,
        scheduleFromMin: 0, scheduleToHour: 20, scheduleToMin: 0, schedulerDays: .everyDay
    )
}

extension BitTorrentPrefs {
    static let qbtDefaults = BitTorrentPrefs(
        dht: true, pex: true, lsd: true, encryption: .allow, anonymousMode: false,
        maxActiveCheckingTorrents: 1, queueingEnabled: false, maxActiveDownloads: 3, maxActiveTorrents: 5,
        maxActiveUploads: 3, dontCountSlowTorrents: false, slowTorrentDlRateThreshold: 2,
        slowTorrentUlRateThreshold: 2, slowTorrentInactiveTimer: 60, maxRatio: -1, maxSeedingTime: -1,
        maxInactiveSeedingTime: -1, maxRatioAct: .stop, addTrackersEnabled: false, addTrackers: "",
        addTrackersFromUrlEnabled: false, addTrackersUrl: "", addTrackersUrlList: ""
    )
}

extension RssPrefs {
    static let qbtDefaults = RssPrefs(
        rssRefreshInterval: 30, rssFetchDelay: 2, rssMaxArticlesPerFeed: 50, rssProcessingEnabled: false,
        rssAutoDownloadingEnabled: false, rssDownloadRepackProperEpisodes: true,
        rssSmartEpisodeFilters: [
            #"s(\d+)e(\d+)"#, #"(\d+)x(\d+)"#,
            #"(\d{4}[.\-]\d{1,2}[.\-]\d{1,2})"#, #"(\d{1,2}[.\-]\d{1,2}[.\-]\d{4})"#,
        ]
    )
}

extension WebUiPrefs {
    static let qbtDefaults = WebUiPrefs(
        webUiEnabled: false, webUiDomainList: "*", webUiAddress: "*", webUiPort: 8080, webUiUpnp: false,
        useHttps: false, webUiHttpsCertPath: "", webUiHttpsKeyPath: "", webUiUsername: "admin",
        webUiPasswordPbkdf2: "", webUiApiKey: "", bypassLocalAuth: false,
        bypassAuthSubnetWhitelistEnabled: false, bypassAuthSubnetWhitelist: [], webUiMaxAuthFailCount: 5,
        webUiBanDuration: 3600, webUiSessionTimeout: 3600, alternativeWebuiEnabled: false,
        alternativeWebuiPath: "", webUiClickjackingProtectionEnabled: true, webUiCsrfProtectionEnabled: true,
        webUiSecureCookieEnabled: true, webUiHostHeaderValidationEnabled: true,
        webUiUseCustomHttpHeadersEnabled: false, webUiCustomHttpHeaders: "", webUiReverseProxyEnabled: false,
        webUiReverseProxiesList: "", dyndnsEnabled: false, dyndnsService: .dynDns, dyndnsUsername: "",
        dyndnsPassword: "", dyndnsDomain: "changeme.dyndns.org"
    )
}

extension AdvancedPrefs {
    static let qbtDefaults = AdvancedPrefs(
        resumeDataStorageType: .legacy, torrentContentRemoveOption: .delete, memoryWorkingSetLimit: 512,
        currentNetworkInterface: "", currentInterfaceName: "", currentInterfaceAddress: "",
        saveResumeDataInterval: 60, saveStatisticsInterval: 15, torrentFileSizeLimit: 100 * 1024 * 1024,
        confirmTorrentRecheck: true, recheckCompletedTorrents: false, appInstanceName: "", refreshInterval: 1500,
        resolvePeerHostNames: false, resolvePeerCountries: true, reannounceWhenAddressChanged: false,
        enableEmbeddedTracker: false, embeddedTrackerPort: 9000, embeddedTrackerPortForwarding: false,
        markOfTheWeb: true, ignoreSslErrors: false, pythonExecutablePath: "", startPaused: false,
        shutdownTimeout: -1, bdecodeDepthLimit: 100, bdecodeTokenLimit: 10_000_000, asyncIoThreads: 10,
        hashingThreads: 1, filePoolSize: 100, checkingMemoryUse: 32, diskCache: -1, diskCacheTtl: 60,
        diskQueueSize: 1024 * 1024, diskIoType: .default, diskIoReadMode: .enableOsCache,
        diskIoWriteMode: .enableOsCache, enableCoalesceReadWrite: false, enablePieceExtentAffinity: false,
        enableUploadSuggestions: false, sendBufferWatermark: 500, sendBufferLowWatermark: 10,
        sendBufferWatermarkFactor: 50, connectionSpeed: 30, socketSendBufferSize: 0, socketReceiveBufferSize: 0,
        socketBacklogSize: 30, outgoingPortsMin: 0, outgoingPortsMax: 0, upnpLeaseDuration: 0, peerTos: 1,
        utpTcpMixedMode: .preferTcp, hostnameCacheTtl: 1200, idnSupportEnabled: false,
        enableMultiConnectionsFromSameIp: false, validateHttpsTrackerCertificate: true, ssrfMitigation: true,
        blockPeersOnPrivilegedPorts: false, uploadSlotsBehavior: .fixedSlots,
        uploadChokingAlgorithm: .fastestUpload, announceToAllTrackers: false, announceToAllTiers: true,
        announceIp: "", announcePort: 0, maxConcurrentHttpAnnounces: 50, stopTrackerTimeout: 2,
        peerTurnover: 4, peerTurnoverCutoff: 90, peerTurnoverInterval: 300, requestQueueSize: 500,
        dhtBootstrapNodes: "dht.libtorrent.org:25401, dht.transmissionbt.com:6881, router.bittorrent.com:6881"
    )
}
