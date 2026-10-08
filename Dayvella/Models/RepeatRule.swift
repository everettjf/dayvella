import Foundation

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case none
    case yearly
    case monthly
    case weekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return String(localized: "None")
        case .yearly: return String(localized: "Yearly")
        case .monthly: return String(localized: "Monthly")
        case .weekly: return String(localized: "Weekly")
        }
    }
}
