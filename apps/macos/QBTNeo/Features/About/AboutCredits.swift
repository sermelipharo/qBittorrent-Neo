import Foundation

/// Credit texts, with names taken verbatim from qBittorrent's AUTHORS file
/// (contributors) and its `thanks.html` / `translators.html` resources.
enum AboutCredits {
    static let contributors = [
        "Vladimir Golovnev", "Stefanos Antaris", "Mohammad Dib", "Mirco Chinelli", "Ishan Arora",
        "Arnaud Demaizière", "Grigis Gaëtan", "Christian Kandeler", "Silvan Scherrer", "Nick Tiskov",
    ].formatted(.list(type: .and, width: .standard))

    static let thanks: [(role: String, names: String)] = [
        (String(localized: "Mac OS X packaging"), "Στέφανος Αντάρης, Mirco Chinelli"),
        (String(localized: "Windows port"), "Peter Koeleman, Mohammad Dib"),
        (String(localized: "Graphics"), "Mateusz Toboła"),
        (String(localized: "Hosting"), "sourceforge.net"),
    ]

    static let russianTranslators =
        "Nick Khazov, Alexey Morsov, Nick Tiskov, DmitryKX, kraleksandr"
}
