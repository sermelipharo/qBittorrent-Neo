import SwiftUI

/// "License" tab: GPL for the application, the licenses of qBittorrent and
/// its libraries, and the DB-IP attribution.
struct AboutLicenseTab: View {
    var body: some View {
        Form {
            Section("qBittorrent Neo") {
                Text("""
                This program is free software: you can redistribute it and/or modify it under the terms of the GNU \
                General Public License as published by the Free Software Foundation, either version 3 of the \
                License, or (at your option) any later version.
                """)
                Link("GNU General Public License v3.0", destination: AboutLinks.gpl)
            }
            Section("qBittorrent") {
                Text("""
                The core is qBittorrent 5.2.4, Copyright 2006-2026 The qBittorrent project, licensed under the GNU \
                General Public License version 2 or later. It uses libtorrent (BSD 3-Clause License), Qt (GNU \
                Lesser General Public License version 3), Boost (Boost Software License) and OpenSSL (Apache \
                License 2.0).
                """)
                Link("qBittorrent on GitHub", destination: AboutLinks.qbittorrent)
                Link("libtorrent", destination: AboutLinks.libtorrent)
            }
            Section("Peer countries") {
                Text("""
                The free IP to Country Lite database by DB-IP is used for resolving the countries of peers. The \
                database is licensed under the Creative Commons Attribution 4.0 International License.
                """)
                Link("https://db-ip.com", destination: AboutLinks.dbip)
            }
        }
        .formStyle(.grouped)
    }
}
