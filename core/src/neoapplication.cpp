/*
 * qBittorrent Neo — the Qt application object of the in-process core.
 *
 * Based on qBittorrent's src/app/application.cpp:
 * Copyright (C) 2015-2024 Vladimir Golovnev <glassez@yandex.ru>
 * Copyright (C) 2006 Christophe Dumez
 * Modifications Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "neoapplication.h"

#include <algorithm>

#include <QDateTime>
#include <QLibraryInfo>
#include <QProcess>
#include <QStandardPaths>

#include "base/bittorrent/infohash.h"
#include "base/bittorrent/session.h"
#include "base/bittorrent/torrent.h"
#include "base/exceptions.h"
#include "base/global.h"
#include "base/logger.h"
#include "base/net/downloadmanager.h"
#include "base/net/geoipmanager.h"
#include "base/net/proxyconfigurationmanager.h"
#include "base/net/reverseresolution.h"
#include "base/net/smtp.h"
#include "base/preferences.h"
#include "base/profile.h"
#include "base/rss/rss_autodownloader.h"
#include "base/rss/rss_session.h"
#include "base/search/searchpluginmanager.h"
#include "base/settingsstorage.h"
#include "base/torrentfileswatcher.h"
#include "base/utils/fs.h"
#include "base/utils/misc.h"
#include "base/utils/password.h"
#include "base/utils/string.h"
#include "base/version.h"
#include "addmanager.h"
#include "filelogger.h"
#include "upgrade.h"

#ifndef DISABLE_WEBUI
#include "webui/webui.h"
#endif

namespace
{
#define SETTINGS_KEY(name) u"Application/" name
#define FILELOGGER_SETTINGS_KEY(name) (SETTINGS_KEY(u"FileLogger/") name)

    const QString LOG_FOLDER = u"logs"_s;

    const int MIN_FILELOG_SIZE = 1024; // 1KiB
    const int MAX_FILELOG_SIZE = 1000 * 1024 * 1024; // 1000MiB
    const int DEFAULT_FILELOG_SIZE = 65 * 1024; // 65KiB

    // Default profile root of the app (a CustomProfile, so qBittorrent's own
    // profile of a regular installation is never touched).
    const QString DEFAULT_PROFILE_FOLDER = u"mk.lex.qbittorrentneo"_s;
}

// RSS::Session and RSS::AutoDownloader may only be created by a class named
// ::Application (qBittorrent's application object, which this library does
// not link). This helper takes that role so the vendored sources stay
// unmodified.
class Application
{
public:
    static void createRss(IApplication *app)
    {
        new RSS::Session; // create RSS::Session singleton
        new RSS::AutoDownloader(app); // create RSS::AutoDownloader singleton
    }

    static void deleteRss()
    {
        delete RSS::AutoDownloader::instance();
        delete RSS::Session::instance();
    }
};

namespace Neo
{
    NeoApplication::NeoApplication(int &argc, char **argv, const StartupConfig &config)
        : QCoreApplication(argc, argv)
        , m_config {config}
        , m_storeInstanceName(SETTINGS_KEY(u"InstanceName"_s))
        , m_storeFileLoggerEnabled(FILELOGGER_SETTINGS_KEY(u"Enabled"_s))
        , m_storeFileLoggerBackup(FILELOGGER_SETTINGS_KEY(u"Backup"_s))
        , m_storeFileLoggerDeleteOld(FILELOGGER_SETTINGS_KEY(u"DeleteOld"_s))
        , m_storeFileLoggerMaxSize(FILELOGGER_SETTINGS_KEY(u"MaxSizeBytes"_s))
        , m_storeFileLoggerAge(FILELOGGER_SETTINGS_KEY(u"Age"_s))
        , m_storeFileLoggerAgeType(FILELOGGER_SETTINGS_KEY(u"AgeType"_s))
        , m_storeFileLoggerPath(FILELOGGER_SETTINGS_KEY(u"Path"_s))
        , m_storeMemoryWorkingSetLimit(SETTINGS_KEY(u"MemoryWorkingSetLimit"_s))
    {
        qRegisterMetaType<Log::Msg>("Log::Msg");
        qRegisterMetaType<Log::Peer>("Log::Peer");

        setApplicationName(u"qBittorrent"_s);
        setOrganizationDomain(u"qbittorrent.org"_s);

        m_launchTimeSecsSinceEpoch = QDateTime::currentSecsSinceEpoch();

        Logger::initInstance();

        const bool isDefaultProfile = m_config.profileDir.isEmpty();
        if (isDefaultProfile)
            m_config.profileDir = defaultProfileRoot();
        Profile::initInstance(m_config.profileDir, {}, false);

        SettingsStorage::initInstance();
        Preferences::initInstance();

        const bool firstTimeUser = SettingsStorage::instance()->isEmpty();
        if (firstTimeUser)
        {
            setCurrentMigrationVersion();
            handleChangedDefaults(DefaultPreferencesMode::Current);

            // With a custom profile qBittorrent defaults the save path to
            // "<profile>/downloads"; the app's own profile uses the user's
            // Downloads folder like a regular installation.
            if (isDefaultProfile)
            {
                const Path downloads {QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)};
                SettingValue<Path>(u"BitTorrent/Session/DefaultSavePath"_s) = downloads;
                SettingValue<Path>(u"BitTorrent/Session/TempPath"_s) = (downloads / Path(u"temp"_s));
            }
        }
        else
        {
            if (!upgrade())
                throw RuntimeError(u"Failed migration of old settings"_s);
            handleChangedDefaults(DefaultPreferencesMode::Legacy);
        }

        initializeTranslation();

        connect(this, &QCoreApplication::aboutToQuit, this, &NeoApplication::cleanup);

        LogMsg(tr("qBittorrent %1 started. Process ID: %2", "qBittorrent v3.2.0alpha started")
            .arg(QStringLiteral(QBT_VERSION), QString::number(QCoreApplication::applicationPid())));
        LogMsg(tr("Using config directory: %1").arg(Profile::instance()->location(SpecialFolder::Config).toString()));

        if (isFileLoggerEnabled())
        {
            m_fileLogger = new FileLogger(fileLoggerPath(), isFileLoggerBackup(), fileLoggerMaxSize()
                    , isFileLoggerDeleteOld(), fileLoggerAge(), static_cast<FileLogger::FileLogAgeType>(fileLoggerAgeType()));
        }

        if (m_config.webUIPortOverride > 0)
            Preferences::instance()->setWebUIPort(m_config.webUIPortOverride);
    }

    NeoApplication::~NeoApplication()
    {
        cleanup();
    }

    Path NeoApplication::defaultProfileRoot() const
    {
        return Path(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)) / Path(DEFAULT_PROFILE_FOLDER);
    }

    const StartupConfig &NeoApplication::config() const
    {
        return m_config;
    }

    bool NeoApplication::isComponentsReady() const
    {
        return m_componentsReady;
    }

    void NeoApplication::startComponents()
    {
        Net::ProxyConfigurationManager::initInstance();
        Net::DownloadManager::initInstance();

        BitTorrent::Session::initInstance();
        auto *btSession = BitTorrent::Session::instance();

        connect(btSession, &BitTorrent::Session::restored, this, [this, btSession]
        {
            connect(btSession, &BitTorrent::Session::torrentAdded, this, &NeoApplication::torrentAdded);
            connect(btSession, &BitTorrent::Session::torrentFinished, this, &NeoApplication::torrentFinished);

            m_addTorrentManager = new NeoAddTorrentManager(this, btSession, this);

            Net::GeoIPManager::initInstance();
            Net::ReverseResolution::initInstance();
            TorrentFilesWatcher::initInstance();

            ::Application::createRss(this);

#ifndef DISABLE_WEBUI
            // As in the GUI build: no temporary password, the WebUI stays
            // disabled until a password is set in the preferences.
            m_webui = new WebUI(this);
            connect(m_webui, &WebUI::error, this, [](const QString &message)
            {
                LogMsg(tr("WebUI configuration failed. Reason: %1").arg(message), Log::WARNING);
            });
#endif

            m_componentsReady = true;
            emit componentsReady();
        });
    }

    void NeoApplication::cleanup()
    {
        if (m_isCleanupRun)
            return;
        m_isCleanupRun = true;

        LogMsg(tr("qBittorrent termination initiated"));

#ifndef DISABLE_WEBUI
        delete m_webui;
        m_webui = nullptr;
#endif

        ::Application::deleteRss();

        TorrentFilesWatcher::freeInstance();
        delete m_addTorrentManager;
        m_addTorrentManager = nullptr;
        BitTorrent::Session::freeInstance();
        Net::ReverseResolution::freeInstance();
        Net::GeoIPManager::freeInstance();
        Net::DownloadManager::freeInstance();
        Net::ProxyConfigurationManager::freeInstance();
        Preferences::freeInstance();
        SettingsStorage::freeInstance();
        SearchPluginManager::freeInstance();
        Utils::Fs::removeDirRecursively(Utils::Fs::tempPath());

        LogMsg(tr("qBittorrent is now ready to exit"));
        Logger::freeInstance();
        delete m_fileLogger;
        m_fileLogger = nullptr;

        Profile::freeInstance();
    }

    void NeoApplication::initializeTranslation()
    {
        const QString localeStr = Preferences::instance()->getLocale();

        if (m_qtTranslator.load((u"qtbase_" + localeStr), QLibraryInfo::path(QLibraryInfo::TranslationsPath))
            || m_qtTranslator.load((u"qt_" + localeStr), QLibraryInfo::path(QLibraryInfo::TranslationsPath)))
        {
            installTranslator(&m_qtTranslator);
        }

        if (m_translator.load(u":/lang/qbittorrent_" + localeStr))
            installTranslator(&m_translator);
    }

    QString NeoApplication::instanceName() const
    {
        return m_storeInstanceName;
    }

    void NeoApplication::setInstanceName(const QString &name)
    {
        m_storeInstanceName = name;
    }

    qint64 NeoApplication::launchTimeSecsSinceEpoch() const
    {
        return m_launchTimeSecsSinceEpoch;
    }

    bool NeoApplication::isFileLoggerEnabled() const
    {
        return m_storeFileLoggerEnabled.get(true);
    }

    void NeoApplication::setFileLoggerEnabled(const bool value)
    {
        if (value && !m_fileLogger)
        {
            m_fileLogger = new FileLogger(fileLoggerPath(), isFileLoggerBackup(), fileLoggerMaxSize()
                    , isFileLoggerDeleteOld(), fileLoggerAge(), static_cast<FileLogger::FileLogAgeType>(fileLoggerAgeType()));
        }
        else if (!value)
        {
            delete m_fileLogger;
            m_fileLogger = nullptr;
        }
        m_storeFileLoggerEnabled = value;
    }

    Path NeoApplication::fileLoggerPath() const
    {
        return m_storeFileLoggerPath.get(specialFolderLocation(SpecialFolder::Data) / Path(LOG_FOLDER));
    }

    void NeoApplication::setFileLoggerPath(const Path &path)
    {
        if (m_fileLogger)
            m_fileLogger->changePath(path);
        m_storeFileLoggerPath = path;
    }

    bool NeoApplication::isFileLoggerBackup() const
    {
        return m_storeFileLoggerBackup.get(true);
    }

    void NeoApplication::setFileLoggerBackup(const bool value)
    {
        if (m_fileLogger)
            m_fileLogger->setBackup(value);
        m_storeFileLoggerBackup = value;
    }

    bool NeoApplication::isFileLoggerDeleteOld() const
    {
        return m_storeFileLoggerDeleteOld.get(true);
    }

    void NeoApplication::setFileLoggerDeleteOld(const bool value)
    {
        if (value && m_fileLogger)
            m_fileLogger->deleteOld(fileLoggerAge(), static_cast<FileLogger::FileLogAgeType>(fileLoggerAgeType()));
        m_storeFileLoggerDeleteOld = value;
    }

    int NeoApplication::fileLoggerMaxSize() const
    {
        const int val = m_storeFileLoggerMaxSize.get(DEFAULT_FILELOG_SIZE);
        return std::clamp(val, MIN_FILELOG_SIZE, MAX_FILELOG_SIZE);
    }

    void NeoApplication::setFileLoggerMaxSize(const int bytes)
    {
        const int clampedValue = std::clamp(bytes, MIN_FILELOG_SIZE, MAX_FILELOG_SIZE);
        if (m_fileLogger)
            m_fileLogger->setMaxSize(clampedValue);
        m_storeFileLoggerMaxSize = clampedValue;
    }

    int NeoApplication::fileLoggerAge() const
    {
        const int val = m_storeFileLoggerAge.get(1);
        return std::clamp(val, 1, 365);
    }

    void NeoApplication::setFileLoggerAge(const int value)
    {
        m_storeFileLoggerAge = std::clamp(value, 1, 365);
    }

    int NeoApplication::fileLoggerAgeType() const
    {
        const int val = m_storeFileLoggerAgeType.get(1);
        return ((val < 0) || (val > 2)) ? 1 : val;
    }

    void NeoApplication::setFileLoggerAgeType(const int value)
    {
        m_storeFileLoggerAgeType = ((value < 0) || (value > 2)) ? 1 : value;
    }

    int NeoApplication::memoryWorkingSetLimit() const
    {
        return m_storeMemoryWorkingSetLimit.get(512);
    }

    void NeoApplication::setMemoryWorkingSetLimit(const int size)
    {
        // Not applied on macOS (same as qBittorrent).
        m_storeMemoryWorkingSetLimit = size;
    }

    AddTorrentManager *NeoApplication::addTorrentManager() const
    {
        return m_addTorrentManager;
    }

#ifndef DISABLE_WEBUI
    WebUI *NeoApplication::webUI() const
    {
        return m_webui;
    }

    QString NeoApplication::webUITemporaryPassword() const
    {
        return m_webUITemporaryPassword;
    }
#endif

    void NeoApplication::sendTestEmail() const
    {
        const Preferences *pref = Preferences::instance();
        if (!pref->isMailNotificationEnabled())
            return;

        const QString content = tr("This is a test email.") + u'\n'
            + tr("Thank you for using qBittorrent.") + u'\n';

        auto *smtp = new Net::Smtp();
        smtp->sendMail(pref->getMailNotificationSender(), pref->getMailNotificationEmail()
                , tr("Test email"), content);
    }

    void NeoApplication::sendNotificationEmail(const BitTorrent::Torrent *torrent)
    {
        const QString content = tr("Torrent name: %1").arg(torrent->name()) + u'\n'
            + tr("Torrent size: %1").arg(Utils::Misc::friendlyUnit(torrent->wantedSize())) + u'\n'
            + tr("Save path: %1").arg(torrent->savePath().toString()) + u"\n\n"
            + tr("The torrent was downloaded in %1.", "The torrent was downloaded in 1 hour and 20 seconds")
                .arg(Utils::Misc::userFriendlyDuration(torrent->activeTime())) + u"\n\n\n"
            + tr("Thank you for using qBittorrent.") + u'\n';

        const Preferences *pref = Preferences::instance();
        auto *smtp = new Net::Smtp(this);
        smtp->sendMail(pref->getMailNotificationSender(), pref->getMailNotificationEmail()
                , tr("Torrent \"%1\" has finished downloading").arg(torrent->name()), content);
    }

    void NeoApplication::torrentAdded(const BitTorrent::Torrent *torrent) const
    {
        const Preferences *pref = Preferences::instance();
        if (pref->isAutoRunOnTorrentAddedEnabled())
            runExternalProgram(pref->getAutoRunOnTorrentAddedProgram().trimmed(), torrent);
    }

    void NeoApplication::torrentFinished(const BitTorrent::Torrent *torrent)
    {
        const Preferences *pref = Preferences::instance();
        if (pref->isAutoRunOnTorrentFinishedEnabled())
            runExternalProgram(pref->getAutoRunOnTorrentFinishedProgram().trimmed(), torrent);

        if (pref->isMailNotificationEnabled())
        {
            LogMsg(tr("Torrent: %1, sending mail notification").arg(torrent->name()));
            sendNotificationEmail(torrent);
        }
    }

    void NeoApplication::runExternalProgram(const QString &programTemplate, const BitTorrent::Torrent *torrent) const
    {
        // Same as Application::runExternalProgram(): no shell, arguments are
        // split first and placeholders substituted per argument, so torrent
        // names cannot inject commands.
        const auto replaceVariables = [torrent](QString str) -> QString
        {
            for (qsizetype i = (str.length() - 2); i >= 0; --i)
            {
                if (str[i] != u'%')
                    continue;

                const ushort specifier = str[i + 1].unicode();
                switch (specifier)
                {
                case u'C':
                    str.replace(i, 2, QString::number(torrent->filesCount()));
                    break;
                case u'D':
                    str.replace(i, 2, torrent->savePath().toString());
                    break;
                case u'F':
                    str.replace(i, 2, torrent->contentPath().toString());
                    break;
                case u'G':
                    str.replace(i, 2, Utils::String::joinIntoString(torrent->tags(), u","_s));
                    break;
                case u'I':
                    str.replace(i, 2, (torrent->infoHash().v1().isValid() ? torrent->infoHash().v1().toString() : u"-"_s));
                    break;
                case u'J':
                    str.replace(i, 2, (torrent->infoHash().v2().isValid() ? torrent->infoHash().v2().toString() : u"-"_s));
                    break;
                case u'K':
                    str.replace(i, 2, torrent->id().toString());
                    break;
                case u'L':
                    str.replace(i, 2, torrent->category());
                    break;
                case u'M':
                    str.replace(i, 2, torrent->comment());
                    break;
                case u'N':
                    str.replace(i, 2, torrent->name());
                    break;
                case u'R':
                    str.replace(i, 2, torrent->rootPath().toString());
                    break;
                case u'T':
                    str.replace(i, 2, torrent->currentTracker());
                    break;
                case u'Z':
                    str.replace(i, 2, QString::number(torrent->totalSize()));
                    break;
                default:
                    break;
                }

                --i;
            }

            return str;
        };

        const QString logMsg = tr("Running external program. Torrent: \"%1\". Command: `%2`");
        const QString logMsgError = tr("Failed to run external program. Torrent: \"%1\". Command: `%2`");

        QStringList args = Utils::String::splitCommand(programTemplate);
        if (args.isEmpty())
            return;

        for (QString &arg : args)
        {
            if (arg.startsWith(u'"') && arg.endsWith(u'"'))
                arg.slice(1, (arg.size() - 2));
            arg = replaceVariables(arg);
        }

        const QString command = args.takeFirst();
        QProcess proc;
        proc.setProgram(command);
        proc.setArguments(args);
        proc.setUnixProcessParameters(QProcess::UnixProcessFlag::CloseFileDescriptors);

        if (proc.startDetached())
            LogMsg(logMsg.arg(torrent->name(), replaceVariables(programTemplate)));
        else
            LogMsg(logMsgError.arg(torrent->name(), replaceVariables(programTemplate)));
    }
}
