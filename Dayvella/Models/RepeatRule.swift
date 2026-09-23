import Foundation

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
    case none
    case yearly
    case monthly
    case weekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .yearly: return "Yearly"
        case .monthly: return "Monthly"
        case .weekly: return "Weekly"
        }
    }
}
