import AppKit

/// Draws a view into a bitmap for a snapshot file: at the screen's backing
/// scale, or at `--snapshot-scale` pixels per point (vector content such as
/// text and symbols stays sharp at any scale).
@MainActor
enum SnapshotBitmap {
    static func capture(_ view: NSView) -> NSBitmapImageRep? {
        let bounds = view.bounds
        guard let scale = LaunchOptions.current.snapshotScale else {
            guard let rep = view.bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
            view.cacheDisplay(in: bounds, to: rep)
            return rep
        }
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int((bounds.width * scale).rounded()), pixelsHigh: Int((bounds.height * scale).rounded()),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }
        rep.size = bounds.size
        view.cacheDisplay(in: bounds, to: rep)
        return rep.retagging(with: .sRGB) ?? rep
    }
}
