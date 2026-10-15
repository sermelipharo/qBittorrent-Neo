import SwiftUI

/// Downloaded-pieces bar (piece states: 0 missing, 1 downloading, 2 have) or
/// availability bar (peer counts normalized by the maximum). Pieces are
/// resampled to the pixel width with fractional coverage and drawn with
/// Canvas, merging runs of equal shade into one rectangle.
struct PiecesBar: View {
    enum Content: Equatable {
        case states([UInt8])
        case availability([UInt32])
    }

    let content: Content
    var pieceColor: Color = .accentColor
    var partialColor: Color = .green

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .color(.secondary.opacity(0.12)))
            let columns = max(Int(size.width), 1)
            let shades = Self.resample(content, columns: columns)
            let columnWidth = size.width / Double(columns)
            var start = 0
            while start < columns {
                var end = start + 1
                while end < columns, shades[end] == shades[start] { end += 1 }
                let shade = shades[start]
                let band = CGRect(x: Double(start) * columnWidth, y: 0, width: Double(end - start) * columnWidth, height: size.height)
                if shade.have > 0 {
                    context.fill(Path(band), with: .color(pieceColor.opacity(Double(shade.have) / 16)))
                }
                if shade.partial > 0 {
                    context.fill(Path(band), with: .color(partialColor.opacity(Double(shade.partial) / 16)))
                }
                start = end
            }
            context.stroke(Path(rect.insetBy(dx: 0.5, dy: 0.5)), with: .color(.secondary.opacity(0.35)), lineWidth: 1)
        }
        .frame(height: Design.Size.pieceBarHeight)
        .clipShape(.rect(cornerRadius: Design.Radius.small))
    }

    /// Per pixel column: the fraction (in sixteenths) of covered pieces that
    /// are complete and that are partially downloaded.
    struct Shade: Equatable {
        var have: UInt8
        var partial: UInt8
    }

    static func resample(_ content: Content, columns: Int) -> [Shade] {
        let count: Int
        let value: (Int) -> (Double, Double)
        switch content {
        case .states(let states):
            count = states.count
            value = { index in (states[index] == 2 ? 1 : 0, states[index] == 1 ? 1 : 0) }
        case .availability(let peers):
            count = peers.count
            let maximum = Double(peers.max() ?? 0)
            value = { index in (maximum > 0 ? Double(peers[index]) / maximum : 0, 0) }
        }
        guard count > 0 else { return [Shade](repeating: Shade(have: 0, partial: 0), count: columns) }
        let step = Double(count) / Double(columns)
        return (0..<columns).map { column in
            let lower = Double(column) * step
            let upper = lower + step
            var have = 0.0
            var partial = 0.0
            var index = Int(lower)
            while Double(index) < upper, index < count {
                let overlap = min(upper, Double(index + 1)) - max(lower, Double(index))
                let (pieceHave, piecePartial) = value(index)
                have += pieceHave * overlap
                partial += piecePartial * overlap
                index += 1
            }
            return Shade(have: UInt8((have / step * 16).rounded()), partial: UInt8((partial / step * 16).rounded()))
        }
    }
}
