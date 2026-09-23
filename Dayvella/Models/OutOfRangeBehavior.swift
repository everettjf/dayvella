import Foundation

enum OutOfRangeBehavior: String, Codable, CaseIterable, Identifiable {
    case zero
    case freeze

    var id: String { rawValue }

    var label: String {
        switch self {
        case .zero: return "Zero"
        case .freeze: return "Freeze"
        }
    }
}
