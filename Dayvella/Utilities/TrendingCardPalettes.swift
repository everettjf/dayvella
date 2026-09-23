import Foundation

struct TrendingCardPalette: Identifiable, Equatable {
    let id: String
    let name: String
    let colors: [String]

    var primaryHex: String {
        colors.first ?? "#FFFFFF"
    }

    init(name: String, colors: [String]) {
        self.name = name
        self.colors = colors.map { TrendingCardPalettes.normalize($0) }
        self.id = name.replacingOccurrences(of: " ", with: "-")
    }
}

enum TrendingCardPalettes {
    static let all: [TrendingCardPalette] = [
        TrendingCardPalette(name: "Sage Linen", colors: ["#789184", "#AABCB1", "#D8E0DA", "#F1F3EF"]),
        TrendingCardPalette(name: "Lilac Haze", colors: ["#9B8FB5", "#BDB4CE", "#DDD7E6", "#F3F0F6"]),
        TrendingCardPalette(name: "Rosewood Mist", colors: ["#B77C7A", "#CFA6A2", "#E8CDCA", "#F7EFEC"]),
        TrendingCardPalette(name: "Meadow Cream", colors: ["#A5B08E", "#C3CAA9", "#E1E3C9", "#F5F2E7"]),
        TrendingCardPalette(name: "Soft Graphite", colors: ["#737684", "#A4A6B0", "#D1D2D7", "#F0F0F2"]),
        TrendingCardPalette(name: "Sea Glass", colors: ["#79A8B8", "#A5C4CB", "#D1E0E1", "#EFF5F3"]),
        TrendingCardPalette(name: "Bluebell Air", colors: ["#7185A6", "#A0AEC5", "#CDD5E0", "#EEF1F5"]),
        TrendingCardPalette(name: "Mauve Clay", colors: ["#A47B8D", "#C29EAB", "#DFC7CF", "#F5ECEF"]),
        TrendingCardPalette(name: "Lavender Smoke", colors: ["#A895B8", "#C5B6D0", "#E1D9E7", "#F4F1F6"]),
        TrendingCardPalette(name: "Petal Blush", colors: ["#C98FA3", "#DDB2BF", "#EED5DC", "#FAF1F3"])
    ]

    private static let legacyPrimaryMappings: [String: String] = [
        "#606C38": "#789184",
        "#D9B8FF": "#9B8FB5",
        "#780000": "#B77C7A",
        "#CCD5AE": "#A5B08E",
        "#000000": "#737684",
        "#8ECAE6": "#79A8B8",
        "#03045E": "#7185A6",
        "#5F0F40": "#A47B8D",
        "#E9C1FF": "#A895B8",
        "#FFC3D8": "#C98FA3"
    ]

    static func palette(for hex: String) -> TrendingCardPalette? {
        let normalizedHex = resolvedPrimaryHex(for: hex)
        for palette in all {
            if normalize(palette.primaryHex) == normalizedHex {
                return palette
            }
        }
        return nil
    }

    static func resolvedPrimaryHex(for storedHex: String) -> String {
        let normalizedHex = normalize(storedHex)
        return legacyPrimaryMappings[normalizedHex] ?? normalizedHex
    }

    static var defaultHex: String {
        all.first?.primaryHex ?? "#789184"
    }

    static func randomPrimaryHex() -> String {
        if let randomHex = all.randomElement()?.primaryHex {
            return normalize(randomHex)
        }
        return defaultHex
    }

    static func normalize(_ value: String) -> String {
        var sanitized = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }
        return "#" + sanitized
    }
}
