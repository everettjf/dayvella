import Foundation

enum DateFormatters {
    static func cardDateFormatter(for timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale.current
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMd")
        return formatter
    }

    static let accessibilityFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .full
        return formatter
    }()
}
