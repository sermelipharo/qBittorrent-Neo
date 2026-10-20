import SwiftUI

/// "Credits" tab. The upper area, "Based on qBittorrent", names the original
/// author, the maintainer, the contributors and the translators exactly as
/// qBittorrent's own About dialog and AUTHORS file do. The sections below it
/// credit the libraries qBittorrent is built on, and the last one names the
/// author of this application, so the two are never confused.
struct AboutCreditsTab: View {
    var body: some View {
        Form {
            Section {
                AboutCreditsBanner(appName: "qBittorrent Neo")
            }
            Section {
                AboutPersonRow(role: "Original author", name: "Christophe Dumez", email: "chris@qbittorrent.org")
                AboutPersonRow(
                    role: "Current maintainer", name: "Sledgehammer999", email: "sledgehammer999@qbittorrent.org")
            }
            Section("Contributors") {
                Text(AboutCredits.contributors)
                Link("qBittorrent contributors on GitHub", destination: AboutLinks.contributors)
            }
            Section("Special Thanks") {
                ForEach(AboutCredits.thanks, id: \.role) { entry in
                    LabeledContent(entry.role, value: entry.names)
                }
            }
            Section("Translators") {
                Text("""
                The translations of this application are taken from qBittorrent. Thanks to the people who \
                volunteered to translate qBittorrent, most of them through Transifex.
                """)
                Link("qBittorrent on Transifex", destination: AboutLinks.transifex)
                LabeledContent("Russian:", value: AboutCredits.russianTranslators)
            }
            Section("Core and libraries") {
                AboutComponentRow(
                    name: "qBittorrent",
                    author: "The qBittorrent project",
                    license: "GPL-2.0-or-later, OpenSSL exception",
                    url: AboutLinks.qbittorrent)
                AboutComponentRow(
                    name: "libtorrent-rasterbar",
                    author: "Arvid Norberg and contributors",
                    license: "BSD-3-Clause",
                    url: AboutLinks.libtorrent)
                AboutComponentRow(
                    name: "Qt",
                    author: "The Qt Company and contributors",
                    license: "LGPL-3.0",
                    url: AboutLinks.qt)
                AboutComponentRow(
                    name: "Boost",
                    author: "The Boost community",
                    license: "BSL-1.0",
                    url: AboutLinks.boost)
                AboutComponentRow(
                    name: "OpenSSL",
                    author: "The OpenSSL Project authors",
                    license: "Apache-2.0",
                    url: AboutLinks.openssl)
                AboutComponentRow(
                    name: "zlib",
                    author: "Jean-loup Gailly and Mark Adler",
                    license: "zlib",
                    url: AboutLinks.zlib)
                AboutComponentRow(
                    name: "DB-IP IP to Country Lite",
                    author: "DB-IP.com",
                    license: "CC BY 4.0",
                    url: AboutLinks.dbip)
                AboutComponentRow(
                    name: "Lucide (Web UI icons)",
                    author: "Lucide contributors",
                    license: "ISC",
                    url: AboutLinks.lucide)
            }
            Section("qBittorrent Neo") {
                AboutPersonRow(role: "Author", name: "Lex Fradski")
            }
        }
        .formStyle(.grouped)
        .textSelection(.enabled)
    }
}
