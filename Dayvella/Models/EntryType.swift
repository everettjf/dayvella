import Foundation

enum EntryType: String, Codable, CaseIterable, Identifiable {
    case countUp, countDown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .countUp: return String(localized: "Cumulative")
        case .countDown: return String(localized: "Countdown")
        }
    }
}
