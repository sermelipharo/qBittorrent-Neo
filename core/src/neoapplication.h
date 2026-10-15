/*
 * qBittorrent Neo — the Qt application object of the in-process core.
 *
 * This is qBittorrent's src/app/application.{h,cpp} reduced to what a
 * GUI-less host needs: profile, settings, translation, file logger, the
 * application components created at startup (session, RSS, search, WebUI,
 * watched folders ...), external programs and e-mail notifications. It runs
 * on the core thread, which is the Qt "main" thread of this QCoreApplication.
 *
 * Based on qBittorrent's application.cpp:
 * Copyright (C) 2015-2024 Vladimir Golovnev <glassez@yandex.ru>
 * Copyright (C) 2006 Christophe Dumez
 * Modifications Copyright (C) 2026 Lex Fradski
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <QCoreApplication>
#include <QPointer>
#include <QTranslator>

#include "base/interfaces/iapplication.h"
#include "base/path.h"
#include "base/settingvalue.h"

class AddTorrentManager;
class FileLogger;

namespace BitTorrent
{
    class Torrent;
}

#ifndef DISABLE_WEBUI
class WebUI;
#endif

namespace Neo
{
    struct StartupConfig
    {
        Path profileDir;          // empty: the app's default profile folder
        int webUIPortOverride = 0;
        QString frontEnd;
    };

    class NeoApplication final : public QCoreApplication, public IApplication
    {
        Q_OBJECT
        Q_DISABLE_COPY_MOVE(NeoApplication)

    public:
        NeoApplication(int &argc, char **argv, const StartupConfig &config);
        ~NeoApplication() override;

        // Creates the session and, once it has restored its torrents, the
        // remaining components (like Application::exec() before the loop).
        void startComponents();
        void cleanup();

        bool isComponentsReady() const;
        const StartupConfig &config() const;
        Path defaultProfileRoot() const;

        // IApplication
        QString instanceName() const override;
        void setInstanceName(const QString &name) override;
        qint64 launchTimeSecsSinceEpoch() const override;
        bool isFileLoggerEnabled() const override;
        void setFileLoggerEnabled(bool value) override;
        Path fileLoggerPath() const override;
        void setFileLoggerPath(const Path &path) override;
        bool isFileLoggerBackup() const override;
        void setFileLoggerBackup(bool value) override;
        bool isFileLoggerDeleteOld() const override;
        void setFileLoggerDeleteOld(bool value) override;
        int fileLoggerMaxSize() const override;
        void setFileLoggerMaxSize(int bytes) override;
        int fileLoggerAge() const override;
        void setFileLoggerAge(int value) override;
        int fileLoggerAgeType() const override;
        void setFileLoggerAgeType(int value) override;
        int memoryWorkingSetLimit() const override;
        void setMemoryWorkingSetLimit(int size) override;
        void sendTestEmail() const override;
        AddTorrentManager *addTorrentManager() const override;
#ifndef DISABLE_WEBUI
        WebUI *webUI() const override;
        QString webUITemporaryPassword() const;
#endif

    signals:
        // Session restored and every component created.
        void componentsReady();

    private:
        void initializeTranslation();
        void torrentAdded(const BitTorrent::Torrent *torrent) const;
        void torrentFinished(const BitTorrent::Torrent *torrent);
        void sendNotificationEmail(const BitTorrent::Torrent *torrent);
        void runExternalProgram(const QString &programTemplate, const BitTorrent::Torrent *torrent) const;

        StartupConfig m_config;
        bool m_componentsReady = false;
        bool m_isCleanupRun = false;
        qint64 m_launchTimeSecsSinceEpoch = 0;

        QTranslator m_qtTranslator;
        QTranslator m_translator;

        FileLogger *m_fileLogger = nullptr;
        AddTorrentManager *m_addTorrentManager = nullptr;
#ifndef DISABLE_WEBUI
        WebUI *m_webui = nullptr;
        QString m_webUITemporaryPassword;
#endif

        SettingValue<QString> m_storeInstanceName;
        SettingValue<bool> m_storeFileLoggerEnabled;
        SettingValue<bool> m_storeFileLoggerBackup;
        SettingValue<bool> m_storeFileLoggerDeleteOld;
        SettingValue<int> m_storeFileLoggerMaxSize;
        SettingValue<int> m_storeFileLoggerAge;
        SettingValue<int> m_storeFileLoggerAgeType;
        SettingValue<Path> m_storeFileLoggerPath;
        SettingValue<int> m_storeMemoryWorkingSetLimit;
    };
}
