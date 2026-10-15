import Foundation

/// Sample torrents covering every state, with categories, tags and trackers.
enum DemoCatalog {
    static let categories: [(name: String, path: String)] = [
        ("Linux ISOs", ""),
        ("Linux ISOs/Debian-based", ""),
        ("Movies", "/Volumes/Media/Movies"),
        ("Movies/Blender Open Movies", ""),
        ("Datasets", "/Volumes/Archive/Datasets"),
        ("Music", ""),
        ("Books", ""),
        ("Software", ""),
    ]

    static let tags = ["4K", "archive", "favorite", "seed-forever", "work"]

    static let seeds: [DemoSeed] = [
        DemoSeed(
            name: "ubuntu-24.04.2-desktop-amd64.iso", gib: 5.9, state: .downloading, progress: 0.624,
            category: "Linux ISOs/Debian-based", tags: ["favorite"], hosts: ["torrent.ubuntu.com"],
            addedDaysAgo: 0.2, comment: "Ubuntu CD releases.ubuntu.com", downKiB: 9_800, upKiB: 640, hybrid: true
        ),
        DemoSeed(
            name: "debian-12.9.0-amd64-DVD-1.iso", gib: 3.7, state: .downloading, progress: 0.318,
            category: "Linux ISOs/Debian-based", hosts: ["bttracker.debian.org"], addedDaysAgo: 0.1,
            comment: "Debian CD from cdimage.debian.org", downKiB: 4_200, upKiB: 210
        ),
        DemoSeed(
            name: "Fedora-Workstation-Live-x86_64-41", gib: 2.2, state: .forcedDownloading, progress: 0.871,
            category: "Linux ISOs", hosts: ["torrent.fedoraproject.org"],
            layout: .files([("Fedora-Workstation-Live-x86_64-41-1.4.iso", 0.998), ("Fedora-Workstation-41-1.4-x86_64-CHECKSUM", 0.002)]),
            addedDaysAgo: 0.05, downKiB: 12_400, upKiB: 1_100
        ),
        DemoSeed(
            name: "Sintel (2010) [4K]", gib: 11.6, state: .downloading, progress: 0.457, category: "Movies/Blender Open Movies",
            tags: ["4K", "favorite"], hosts: ["tracker.opentrackr.org", "tracker.torrent.eu.org"],
            layout: .files([
                ("Sintel.2010.2160p.mkv", 0.93), ("Subtitles/Sintel.en.srt", 0.0004), ("Subtitles/Sintel.de.srt", 0.0004),
                ("Subtitles/Sintel.fr.srt", 0.0004), ("Subtitles/Sintel.es.srt", 0.0004),
                ("Extras/Making of Sintel.mp4", 0.065), ("Extras/poster.jpg", 0.0004), ("README.txt", 0.0001),
            ]),
            addedDaysAgo: 0.4, comment: "Blender Foundation open movie — https://durian.blender.org", downKiB: 6_100, upKiB: 880,
            sequential: true
        ),
        DemoSeed(
            name: "OpenStreetMap planet-250106.osm.pbf", gib: 79.4, state: .downloading, progress: 0.083, category: "Datasets",
            tags: ["work"], hosts: ["tracker.opentrackr.org"], addedDaysAgo: 0.3, downKiB: 21_000, upKiB: 2_400
        ),
        DemoSeed(
            name: "archlinux-2025.01.01-x86_64.iso", gib: 1.2, state: .stalledDownloading, progress: 0.992, category: "Linux ISOs",
            hosts: ["tracker.archlinux.org"], addedDaysAgo: 1.2
        ),
        DemoSeed(
            name: "Wikipedia enwiki-20250101-pages-articles-multistream", gib: 22.3, state: .stalledDownloading, progress: 0.41,
            category: "Datasets", tags: ["archive"], hosts: ["academictorrents.com"],
            layout: .files([("enwiki-20250101-pages-articles-multistream.xml.bz2", 0.92), ("enwiki-20250101-pages-articles-multistream-index.txt.bz2", 0.08)]),
            addedDaysAgo: 2, trackerWarning: true
        ),
        DemoSeed(
            name: "Big Buck Bunny (2008) [1080p]", gib: 0.69, state: .uploading, progress: 1, category: "Movies/Blender Open Movies",
            tags: ["seed-forever"], hosts: ["tracker.opentrackr.org"],
            layout: .files([("Big.Buck.Bunny.2008.1080p.mp4", 0.97), ("Big.Buck.Bunny.poster.jpg", 0.01), ("Credits.txt", 0.02)]),
            ratio: 14.27, addedDaysAgo: 210, upKiB: 1_520
        ),
        DemoSeed(
            name: "linuxmint-22.1-cinnamon-64bit.iso", gib: 2.8, state: .uploading, progress: 1, category: "Linux ISOs/Debian-based",
            hosts: ["tracker.opentrackr.org"], ratio: 3.42, addedDaysAgo: 18, upKiB: 2_870
        ),
        DemoSeed(
            name: "Tears of Steel (2012) [4K]", gib: 6.3, state: .uploading, progress: 1, category: "Movies/Blender Open Movies",
            tags: ["4K"], hosts: ["tracker.opentrackr.org", "open.stealth.si"],
            layout: .files([("Tears.of.Steel.2012.2160p.mov", 0.985), ("Subtitles/tos-en.srt", 0.005), ("Subtitles/tos-nl.srt", 0.005), ("readme.txt", 0.005)]),
            ratio: 2.08, addedDaysAgo: 45, upKiB: 760
        ),
        DemoSeed(
            name: "Project Gutenberg — Top 100 eBooks (EPUB)", gib: 0.31, state: .uploading, progress: 1, category: "Books",
            tags: ["archive"], hosts: ["bt1.archive.org", "bt2.archive.org"],
            layout: .files([
                ("Pride and Prejudice.epub", 0.01), ("Moby Dick.epub", 0.012), ("Frankenstein.epub", 0.008),
                ("Alice's Adventures in Wonderland.epub", 0.006), ("The Adventures of Sherlock Holmes.epub", 0.011),
                ("A Tale of Two Cities.epub", 0.01), ("more/…and 94 other titles.zip", 0.943),
            ]),
            ratio: 0.88, addedDaysAgo: 9, upKiB: 96
        ),
        DemoSeed(
            name: "FreeBSD-14.2-RELEASE-amd64-dvd1.iso", gib: 4.6, state: .forcedUploading, progress: 1, category: "Software",
            hosts: ["tracker.opentrackr.org"], ratio: 1.12, addedDaysAgo: 30, upKiB: 3_300, superSeeding: true
        ),
        DemoSeed(
            name: "Internet Archive — Grateful Dead Live at Cornell 1977-05-08", gib: 1.4, state: .uploading, progress: 1,
            category: "Music", tags: ["favorite", "archive"], hosts: ["bt1.archive.org"],
            layout: .files([
                ("gd77-05-08d1t01 New Minglewood Blues.flac", 0.05), ("gd77-05-08d1t02 Loser.flac", 0.08),
                ("gd77-05-08d1t03 El Paso.flac", 0.05), ("gd77-05-08d2t01 Scarlet Begonias.flac", 0.12),
                ("gd77-05-08d2t02 Fire on the Mountain.flac", 0.16), ("gd77-05-08d3t01 Morning Dew.flac", 0.14),
                ("gd77-05-08.txt", 0.001), ("cover.jpg", 0.399),
            ]),
            ratio: 6.5, addedDaysAgo: 120, upKiB: 410
        ),
        DemoSeed(
            name: "kali-linux-2024.4-installer-amd64.iso", gib: 4.0, state: .stalledUploading, progress: 1, category: "Linux ISOs/Debian-based",
            hosts: ["tracker.opentrackr.org"], ratio: 0.46, addedDaysAgo: 12
        ),
        DemoSeed(
            name: "Cosmos Laundromat (2015) [1080p]", gib: 1.9, state: .stalledUploading, progress: 1, category: "Movies/Blender Open Movies",
            hosts: ["tracker.opentrackr.org"], ratio: 4.01, addedDaysAgo: 80
        ),
        DemoSeed(
            name: "Common Voice Corpus 20.0 (English)", gib: 86.2, state: .stalledUploading, progress: 1, category: "Datasets",
            tags: ["work"], hosts: ["academictorrents.com"], isPrivate: true, ratio: 0.12, addedDaysAgo: 6,
            comment: "Mozilla Common Voice — CC0"
        ),
        DemoSeed(
            name: "NASA Apollo 11 Mission Audio (complete)", gib: 9.8, state: .stalledUploading, progress: 1, category: "Music",
            tags: ["archive"], hosts: ["bt1.archive.org"], ratio: 1.94, addedDaysAgo: 365
        ),
        DemoSeed(
            name: "elementaryos-8.0-stable-amd64.iso", gib: 3.2, state: .stoppedDownloading, progress: 0.27, category: "Linux ISOs",
            hosts: ["tracker.opentrackr.org"], addedDaysAgo: 4
        ),
        DemoSeed(
            name: "NixOS 24.11 GNOME (x86_64)", gib: 2.6, state: .stoppedDownloading, progress: 0, category: "Linux ISOs",
            hosts: ["tracker.opentrackr.org"], addedDaysAgo: 0.6
        ),
        DemoSeed(
            name: "Spring (2019) [4K HDR]", gib: 7.4, state: .stoppedUploading, progress: 1, category: "Movies/Blender Open Movies",
            tags: ["4K", "seed-forever"], hosts: ["tracker.opentrackr.org"], ratio: 2.0, addedDaysAgo: 60
        ),
        DemoSeed(
            name: "Raspberry Pi OS (64-bit) 2024-11-19", gib: 1.1, state: .stoppedUploading, progress: 1, category: "Software",
            hosts: ["tracker.opentrackr.org"], ratio: 1.0, addedDaysAgo: 22
        ),
        DemoSeed(
            name: "Night of the Living Dead (1968)", gib: 1.5, state: .stoppedUploading, progress: 1, category: "Movies",
            tags: ["archive"], hosts: ["bt1.archive.org"], ratio: 3.33, addedDaysAgo: 400
        ),
        DemoSeed(
            name: "openSUSE-Tumbleweed-DVD-x86_64-Current.iso", gib: 4.4, state: .queuedDownloading, progress: 0.12, category: "Linux ISOs",
            hosts: ["tracker.opentrackr.org"], addedDaysAgo: 0.7, queuePosition: 1
        ),
        DemoSeed(
            name: "Manjaro KDE 24.2.1", gib: 4.1, state: .queuedDownloading, progress: 0, category: "Linux ISOs",
            hosts: ["tracker.opentrackr.org"], addedDaysAgo: 0.7, queuePosition: 2
        ),
        DemoSeed(
            name: "Pop!_OS 24.04 (NVIDIA)", gib: 3.0, state: .queuedUploading, progress: 1, category: "Linux ISOs",
            hosts: ["tracker.opentrackr.org"], ratio: 0.31, addedDaysAgo: 5
        ),
        DemoSeed(
            name: "ImageNet ILSVRC2012 validation set", gib: 6.3, state: .checkingDownloading, progress: 0.54, category: "Datasets",
            tags: ["work"], hosts: ["academictorrents.com"], isPrivate: true, addedDaysAgo: 1.5
        ),
        DemoSeed(
            name: "Creative Commons Music Collection 2024", gib: 12.0, state: .moving, progress: 1, category: "Music",
            hosts: ["tracker.opentrackr.org"], ratio: 0.72, addedDaysAgo: 14
        ),
        DemoSeed(
            name: "Tails 6.10 (amd64)", gib: 1.4, state: .downloadingMetadata, progress: 0, category: "Software",
            hosts: ["tracker.torrent.eu.org"], addedDaysAgo: 0.01
        ),
        DemoSeed(
            name: "The Pile (deduplicated) — shard 07", gib: 41.0, state: .error, progress: 0.66, category: "Datasets",
            hosts: ["academictorrents.com"], addedDaysAgo: 3, error: "No space left on device", trackerError: true
        ),
        DemoSeed(
            name: "LibriVox — Collected Short Stories Vol. 3", gib: 0.84, state: .missingFiles, progress: 1, category: "Books",
            hosts: ["bt1.archive.org"], ratio: 0.5, addedDaysAgo: 50
        ),
        DemoSeed(
            name: "Blender 4.3 Demo Files", gib: 2.4, state: .checkingResumeData, progress: 0.75, category: "Software",
            addedDaysAgo: 8
        ),
        DemoSeed(
            name: "Agent 327 — Operation Barbershop (2017)", gib: 0.9, state: .stalledDownloading, progress: 0.05, category: "Movies/Blender Open Movies",
            hosts: ["tracker.opentrackr.org"], addedDaysAgo: 0.9
        ),
    ]

    // MARK: Names for the 2,000-torrent stress data set

    static let largeNamePrefixes = [
        "ubuntu", "debian", "fedora", "archlinux", "linuxmint", "opensuse", "manjaro", "nixos", "alpine", "rocky",
        "almalinux", "gentoo", "void", "slackware", "zorin", "kubuntu", "xubuntu", "lubuntu", "endeavouros", "garuda",
    ]

    static let largeNameKinds = ["desktop-amd64.iso", "server-arm64.iso", "netinst.iso", "live-x86_64.iso", "minimal.iso", "dvd1.iso"]
}
