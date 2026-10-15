import AppKit
import ImageIO
import Observation

/// Tracker favicons for the Trackers filter (features.md §1.5.4, "Download
/// tracker's favicon"). Each host is requested at most once per session;
/// the core downloads the bytes (proxy settings, http/https only, 64 KiB cap,
/// timeout) and this store decodes them defensively with ImageIO into a small
/// bitmap kept in a bounded in-memory cache. Nothing is written to disk.
@Observable @MainActor
final class TrackerFaviconStore {
    /// Cached icons are tiny; the bound only guards against tracker lists
    /// with thousands of hosts.
    nonisolated static let maxIcons = 256
    /// Distinct hosts tried in one session.
    nonisolated static let maxAttemptedHosts = 2_048
    nonisolated static let maxConcurrentFetches = 3
    /// Images with more pixels per side than this are rejected before decoding
    /// (a small PNG can claim a gigantic canvas).
    nonisolated static let maxSourceDimension = 512
    nonisolated static let iconPixels = 32
    nonisolated static let iconPoints: CGFloat = 16
    nonisolated private static let allowedTypes: Set<String> = [
        "public.png", "com.microsoft.ico", "public.jpeg", "com.compuserve.gif", "com.microsoft.bmp",
    ]

    private(set) var icons: [String: NSImage] = [:]

    @ObservationIgnored var clientProvider: @MainActor () -> (any AppInfoClient)? = { nil }
    @ObservationIgnored private var attempted: Set<String> = []
    @ObservationIgnored private var insertionOrder: [String] = []
    @ObservationIgnored private var pending: [(host: String, url: String)] = []
    @ObservationIgnored private var inFlight = 0

    func icon(for host: String) -> NSImage? { icons[host] }

    func hasRequested(_ host: String) -> Bool { attempted.contains(host) }

    /// Queues the download for `host` unless it was already tried this session.
    func request(host: String, trackerURL: String) {
        guard !host.isEmpty, attempted.count < Self.maxAttemptedHosts, attempted.insert(host).inserted else { return }
        pending.append((host, trackerURL))
        pump()
    }

    private func pump() {
        while inFlight < Self.maxConcurrentFetches, !pending.isEmpty, let client = clientProvider() {
            let job = pending.removeFirst()
            inFlight += 1
            Task {
                let data = try? await client.fetchTrackerFavicon(trackerUrl: job.url)
                if let data, let image = Self.decode(data) { store(image, for: job.host) }
                inFlight -= 1
                pump()
            }
        }
    }

    private func store(_ image: NSImage, for host: String) {
        if icons[host] == nil { insertionOrder.append(host) }
        icons[host] = image
        while insertionOrder.count > Self.maxIcons {
            icons[insertionOrder.removeFirst()] = nil
        }
    }

    /// Decodes untrusted image bytes: only common raster formats, bounded
    /// dimensions, one bitmap re-rendered at icon size. Returns nil otherwise.
    nonisolated static func decode(_ data: Data) -> NSImage? {
        guard !data.isEmpty, data.count <= 64 * 1024 else { return nil }
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options),
              let type = CGImageSourceGetType(source) as String?, allowedTypes.contains(type)
        else { return nil }
        // ICO files hold several sizes; take the largest acceptable one.
        var best: (index: Int, side: Int)?
        for index in 0..<min(CGImageSourceGetCount(source), 16) {
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? Int,
                  let height = properties[kCGImagePropertyPixelHeight] as? Int,
                  width > 0, height > 0, width <= maxSourceDimension, height <= maxSourceDimension
            else { continue }
            let side = max(width, height)
            if side > (best?.side ?? 0) { best = (index, side) }
        }
        guard let best else { return nil }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: iconPixels,
        ] as CFDictionary
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, best.index, thumbnailOptions) else { return nil }
        return NSImage(cgImage: thumbnail, size: NSSize(width: iconPoints, height: iconPoints))
    }
}
