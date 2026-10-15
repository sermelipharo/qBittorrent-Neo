import Foundation

/// Sample RSS folders, feeds, articles and download rules for the demo session.
enum DemoRSSCatalog {
    static let ubuntuURL = "https://releases.ubuntu.com/releases.rss"
    static let fedoraURL = "https://torrent.fedoraproject.org/rss20.xml"
    static let debianURL = "https://cdimage.debian.org/debian-cd/current/feed.xml"
    static let blenderURL = "https://studio.blender.org/rss/weekly.xml"
    static let radioURL = "https://archive.org/services/collection-rss.php?collection=oldtimeradio"
    static let academicURL = "https://academictorrents.com/rss.xml"

    static let folders = ["Linux Distributions", "Podcasts & Video"]

    static var feeds: [DemoRSSState.Feed] {
        let built = Date.now.addingTimeInterval(-1_800).formatted(.iso8601)
        return [
            DemoRSSState.Feed(
                uid: "{6c0d3f1e-ubuntu}", url: ubuntuURL, path: "Linux Distributions\\Ubuntu Releases", title: "Ubuntu Releases",
                lastBuildDate: built, articles: ubuntuArticles
            ),
            DemoRSSState.Feed(
                uid: "{6c0d3f1e-fedora}", url: fedoraURL, path: "Linux Distributions\\Fedora Torrents",
                title: "Fedora Project Torrents", lastBuildDate: built, refreshInterval: 3_600, articles: fedoraArticles
            ),
            DemoRSSState.Feed(
                uid: "{6c0d3f1e-debian}", url: debianURL, path: "Linux Distributions\\Debian CD Images", title: "Debian CD Images",
                lastBuildDate: "", hasError: true, articles: []
            ),
            DemoRSSState.Feed(
                uid: "{6c0d3f1e-blender}", url: blenderURL, path: "Podcasts & Video\\Blender Studio", title: "Blender Studio Weekly",
                lastBuildDate: built, articles: blenderArticles
            ),
            DemoRSSState.Feed(
                uid: "{6c0d3f1e-radio}", url: radioURL, path: "Podcasts & Video\\Old Time Radio", title: "Internet Archive: Old Time Radio",
                lastBuildDate: built, articles: radioArticles
            ),
            DemoRSSState.Feed(
                uid: "{6c0d3f1e-academic}", url: academicURL, path: "Academic Torrents", title: "Academic Torrents — New Datasets",
                lastBuildDate: built, isLoading: true, articles: academicArticles
            ),
        ]
    }

    static var rules: [RssAutoDownloadRule] {
        var ubuntuParams = TorrentParamsTemplate.defaults
        ubuntuParams.category = "Linux ISOs/Debian-based"
        ubuntuParams.tags = ["favorite"]
        var blenderParams = TorrentParamsTemplate.defaults
        blenderParams.savePath = "/Volumes/Media/Blender Studio"
        blenderParams.autoTmm = false
        blenderParams.contentLayout = .subfolder
        var fedoraParams = TorrentParamsTemplate.defaults
        fedoraParams.stopped = true
        return [
            RssAutoDownloadRule(
                name: "Ubuntu LTS desktop", enabled: true, priority: 0, useRegex: false, mustContain: "ubuntu lts desktop",
                mustNotContain: "beta|rc", episodeFilter: "", affectedFeeds: [ubuntuURL], lastMatch: rfc2822(daysAgo: 3),
                ignoreDays: 0, smartFilter: false, previouslyMatchedEpisodes: [], torrentParams: ubuntuParams
            ),
            RssAutoDownloadRule(
                name: "Blender Studio Weekly", enabled: true, priority: 1, useRegex: false, mustContain: "Blender Studio Weekly 1080p",
                mustNotContain: "", episodeFilter: "2x10-;", affectedFeeds: [blenderURL], lastMatch: rfc2822(daysAgo: 6),
                ignoreDays: 2, smartFilter: true, previouslyMatchedEpisodes: ["S02E12", "S02E13"], torrentParams: blenderParams
            ),
            RssAutoDownloadRule(
                name: "Fedora KDE and Xfce spins", enabled: false, priority: 2, useRegex: true,
                mustContain: #"Fedora-(KDE|Xfce)-Live-x86_64-4[1-9]"#, mustNotContain: "", episodeFilter: "",
                affectedFeeds: [fedoraURL], lastMatch: "", ignoreDays: 0, smartFilter: false, previouslyMatchedEpisodes: [],
                torrentParams: fedoraParams
            ),
        ]
    }

    static func rfc2822(daysAgo: Double) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter.string(from: Date.now.addingTimeInterval(-daysAgo * 86_400))
    }

    // MARK: Articles

    private static func article(
        _ feed: String, _ index: Int, _ title: String, hoursAgo: Double, read: Bool = false,
        author: String = "", description: String, torrent: String = "", link: String = ""
    ) -> RssArticle {
        RssArticle(
            id: "\(feed)-\(index)", date: Int64(Date.now.timeIntervalSince1970 - hoursAgo * 3_600), title: title,
            author: author, description: description, torrentUrl: torrent, link: link, isRead: read
        )
    }

    private static var ubuntuArticles: [RssArticle] {
        let notes = "https://discourse.ubuntu.com/t/noble-numbat-release-notes/39890"
        func release(_ index: Int, _ version: String, _ flavor: String, hoursAgo: Double, read: Bool) -> RssArticle {
            let file = "ubuntu-\(version)-\(flavor)-amd64.iso"
            return article(
                "ubuntu", index, "Ubuntu \(version) LTS \(flavor) amd64", hoursAgo: hoursAgo, read: read, author: "Ubuntu Release Team",
                description: """
                <p><b>Ubuntu \(version) LTS</b> (Noble Numbat) \(flavor) image for 64-bit PC (AMD64) computers.</p>
                <ul><li>Long-term support until 2029</li><li>Linux kernel 6.8 with hardware enablement stack</li>\
                <li>GNOME 46, Firefox, LibreOffice and Thunderbird preinstalled</li></ul>
                <p>Verify the download with <code>SHA256SUMS</code> before installing. \
                See the <a href="\(notes)">release notes</a> for known issues.</p>
                """,
                torrent: "https://releases.ubuntu.com/\(version)/\(file).torrent", link: "https://releases.ubuntu.com/\(version)/"
            )
        }
        return [
            release(1, "24.04.3", "desktop", hoursAgo: 5, read: false),
            release(2, "24.04.3", "live-server", hoursAgo: 5.2, read: false),
            article("ubuntu", 3, "Ubuntu 25.10 beta desktop amd64", hoursAgo: 40, author: "Ubuntu Release Team",
                    description: "<p>Beta images are for testing only and should not be used in production.</p>",
                    torrent: "https://cdimage.ubuntu.com/releases/25.10/beta/ubuntu-25.10-beta-desktop-amd64.iso.torrent",
                    link: "https://cdimage.ubuntu.com/releases/25.10/beta/"),
            release(4, "24.04.2", "desktop", hoursAgo: 24 * 32, read: true),
            release(5, "24.04.2", "live-server", hoursAgo: 24 * 32.1, read: true),
            release(6, "22.04.5", "desktop", hoursAgo: 24 * 70, read: true),
        ]
    }

    private static var fedoraArticles: [RssArticle] {
        let spins = ["Workstation", "KDE", "Xfce", "Server", "Everything"]
        return spins.enumerated().map { index, spin in
            let name = "Fedora-\(spin)-Live-x86_64-42-1.1"
            return article(
                "fedora", index, name, hoursAgo: Double(index) * 3 + 20, read: index > 2, author: "Fedora Project",
                description: "\(name).iso — official Fedora 42 \(spin) image. Checksums are signed with the Fedora 42 key.",
                torrent: "https://torrent.fedoraproject.org/torrents/\(name).torrent", link: "https://fedoraproject.org/"
            )
        }
    }

    private static var blenderArticles: [RssArticle] {
        (8...15).reversed().enumerated().map { offset, episode in
            let hours = Double(offset) * 24 * 7 + 30
            let title = "Blender Studio Weekly S02E\(episode < 10 ? "0" : "")\(episode) 1080p"
            return article(
                "blender", episode, title, hoursAgo: hours, read: offset > 1, author: "Blender Studio",
                description: """
                <h3>Episode \(episode)</h3><p>This week the team shows the lighting pass of the new open movie, \
                answers community questions and previews the <i>Geometry Nodes</i> hair system.</p>\
                <p><img src="https://studio.blender.org/media/weekly/\(episode).jpg" alt="Thumbnail"></p>
                """,
                torrent: "magnet:?xt=urn:btih:\(DemoRandom.hex(title, length: 40))&dn=\(title.replacing(" ", with: "+"))",
                link: "https://studio.blender.org/weekly/s02e\(episode)/"
            )
        }
    }

    private static var radioArticles: [RssArticle] {
        let shows = [
            ("Dragnet 52-03-13 The Big Cast", "Jack Webb"), ("The Shadow 38-01-09 The Phantom Voice", "Orson Welles"),
            ("Suspense 43-12-02 Sorry, Wrong Number", "Agnes Moorehead"), ("X Minus One 55-05-08 Mars Is Heaven", "NBC"),
            ("Gunsmoke 53-04-25 Cain", "William Conrad"),
        ]
        return shows.enumerated().map { index, show in
            article(
                "radio", index, show.0, hoursAgo: Double(index + 1) * 11, read: index == 4, author: show.1,
                description: "[b]\(show.0)[/b]\nOriginal network broadcast, [i]public domain[/i].\n[url=https://archive.org/details/oldtimeradio]Collection page[/url]",
                torrent: "https://archive.org/download/otr-\(index)/otr-\(index)_archive.torrent",
                link: "https://archive.org/details/otr-\(index)"
            )
        }
    }

    private static var academicArticles: [RssArticle] {
        [
            article("academic", 1, "ImageNet LSVRC 2012 Validation Set (Object Detection)", hoursAgo: 2, author: "Stanford Vision Lab",
                    description: "<p>50,000 validation images with bounding boxes. <b>6.74 GB</b>.</p>",
                    torrent: "https://academictorrents.com/download/5d6d0df7ed81efd49ca99ea4737e0ae5e3a5f2e5.torrent",
                    link: "https://academictorrents.com/details/5d6d0df7ed81efd49ca99ea4737e0ae5e3a5f2e5"),
            article("academic", 2, "MIT 6.006 Introduction to Algorithms, Spring 2020 (lecture videos)", hoursAgo: 9, read: true,
                    author: "MIT OpenCourseWare", description: "Lecture videos and notes, CC BY-NC-SA 4.0.",
                    torrent: "https://academictorrents.com/download/mit-6006-2020.torrent",
                    link: "https://academictorrents.com/details/mit-6006-2020"),
        ]
    }

    static func genericArticles(feedTitle: String) -> [RssArticle] {
        (1...3).map { index in
            article(feedTitle, index, "\(feedTitle) — item \(index)", hoursAgo: Double(index), description: "New item from \(feedTitle).")
        }
    }
}
