import SwiftUI

/// A speed limit editor in KiB/s (qBittorrent's spin box: 0 shows "∞",
/// a mixed multi-selection value shows "≠" until edited).
///
/// `limit` is in bytes/s: 0 = unlimited, negative = mixed / unchanged.
struct SpeedLimitField: View {
    let title: LocalizedStringKey
    @Binding var limit: Int64
    var showsSlider = false
    /// Slider maximum in KiB/s (grows when a larger value is typed).
    var sliderMaximum = 10_000.0

    @State private var kib: Int?
    @State private var sliderValue = 0.0

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: Design.Spacing.small) {
                if showsSlider {
                    Slider(value: $sliderValue, in: 0...max(sliderMaximum, Double(kib ?? 0)))
                        .frame(minWidth: 120)
                        .accessibilityLabel(Text(title))
                }
                TextField(title, value: $kib, format: .number, prompt: Text(limit < 0 ? "≠" : "∞"))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .frame(width: Design.Size.speedFieldWidth)
                Text(verbatim: UnitFormatter.speedUnitName(.kibibyte))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: load)
        .onChange(of: kib) { _, newValue in
            guard !(limit < 0 && newValue == nil) else { return }
            let bytes = Int64(max(newValue ?? 0, 0)) * 1024
            if bytes != limit { limit = bytes }
            let slider = Double(newValue ?? 0)
            if slider != sliderValue { sliderValue = slider }
        }
        .onChange(of: sliderValue) { _, newValue in
            let value = Int(newValue.rounded())
            if value != (kib ?? 0) { kib = value == 0 ? nil : value }
        }
        .onChange(of: limit) { _, _ in load() }
    }

    private func load() {
        let value = limit > 0 ? Int(limit / 1024) : nil
        if value != kib { kib = value }
        let slider = Double(value ?? 0)
        if slider != sliderValue { sliderValue = slider }
    }
}
