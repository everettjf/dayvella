import Foundation

@MainActor
struct TimeZoneEntry: Identifiable, Hashable {
    let id: String
    let name: String
    let abbreviations: [String]
    let timeZone: TimeZone

    init?(identifier: String) {
        guard let tz = TimeZone(identifier: identifier) else { return nil }
        id = identifier
        timeZone = tz
        let locale = Locale.current
        let localized = tz.localizedName(for: .shortGeneric, locale: locale) ?? tz.localizedName(for: .standard, locale: locale) ?? identifier
        name = "\(localized) · \(identifier)"
        abbreviations = tz.abbreviation().map { [$0] } ?? []
    }
}

enum TimeZoneCatalog {
    static let featuredIdentifiers: [String] = [
        "Asia/Shanghai",
        "Asia/Tokyo",
        "Asia/Singapore",
        "Asia/Hong_Kong",
        "Europe/London",
        "Europe/Paris",
        "America/New_York",
        "America/Los_Angeles",
        "America/Chicago",
        "Australia/Sydney"
    ]

    @MainActor static let featured: [TimeZoneEntry] = featuredIdentifiers.compactMap(TimeZoneEntry.init)

    @MainActor static var all: [TimeZoneEntry] {
        TimeZone.knownTimeZoneIdentifiers.compactMap(TimeZoneEntry.init)
            .sorted { $0.name < $1.name }
    }

    @MainActor static func search(_ text: String) -> [TimeZoneEntry] {
        guard !text.isEmpty else { return all }
        let lower = text.lowercased()
        return all.filter { entry in
            entry.name.lowercased().contains(lower) || entry.id.lowercased().contains(lower)
        }
    }
}

extension TimeZone {
    var displayName: String {
        if let localized = localizedName(for: .shortGeneric, locale: Locale.current) ?? localizedName(for: .standard, locale: Locale.current) {
            return localized
        }
        return identifier
    }
}
