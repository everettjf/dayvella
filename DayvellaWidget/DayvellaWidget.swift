import SwiftUI
import WidgetKit

private let appGroupID = "group.com.xnu.countmydays"
private let entriesKey = "widget.entries.v1"

private struct WidgetItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let entryType: String
    let startDate: Date?
    let targetDate: Date?
    let repeatRule: String
    let timezoneID: String
    let colorHex: String
    let iconEmoji: String?
    let isPinned: Bool

    var date: Date? { entryType == "countUp" ? startDate : effectiveTarget }

    var effectiveTarget: Date? {
        guard let targetDate, repeatRule != "none" else { return targetDate }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezoneID) ?? .current
        let today = calendar.startOfDay(for: .now)
        let components = calendar.dateComponents([.month, .day, .weekday], from: targetDate)
        switch repeatRule {
        case "weekly":
            return calendar.nextDate(after: today.addingTimeInterval(-1),
                                     matching: DateComponents(weekday: components.weekday),
                                     matchingPolicy: .nextTimePreservingSmallerComponents)
        case "monthly":
            guard let day = components.day else { return targetDate }
            let current = clampedDate(year: calendar.component(.year, from: today),
                                      month: calendar.component(.month, from: today), day: day, calendar: calendar)
            guard let current else { return targetDate }
            if current >= today { return current }
            let next = calendar.date(byAdding: .month, value: 1, to: current) ?? current
            return clampedDate(year: calendar.component(.year, from: next),
                               month: calendar.component(.month, from: next), day: day, calendar: calendar)
        case "yearly":
            guard let month = components.month, let day = components.day else { return targetDate }
            let year = calendar.component(.year, from: today)
            let current = clampedDate(year: year, month: month, day: day, calendar: calendar)
            return (current ?? targetDate) >= today ? current : clampedDate(year: year + 1, month: month, day: day, calendar: calendar)
        default:
            return targetDate
        }
    }

    var days: Int {
        guard let date else { return 0 }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezoneID) ?? .current
        let today = calendar.startOfDay(for: .now)
        let value = calendar.dateComponents([.day], from: entryType == "countUp" ? date : today,
                                            to: entryType == "countUp" ? today : date).day ?? 0
        return value
    }

    private func clampedDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: first) else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: min(day, range.count)))
    }
}

private struct CountEntry: TimelineEntry {
    let date: Date
    let items: [WidgetItem]
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CountEntry { CountEntry(date: .now, items: [.preview]) }

    func getSnapshot(in context: Context, completion: @escaping (CountEntry) -> Void) {
        completion(CountEntry(date: .now, items: loadItems()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountEntry>) -> Void) {
        let entry = CountEntry(date: .now, items: loadItems())
        let nextMidnight = Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 0, minute: 1),
                                                     matchingPolicy: .nextTime) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func loadItems() -> [WidgetItem] {
        guard let data = UserDefaults(suiteName: appGroupID)?.data(forKey: entriesKey),
              let items = try? JSONDecoder().decode([WidgetItem].self, from: data), !items.isEmpty else {
            return [.preview]
        }
        return items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            if lhs.entryType != rhs.entryType { return lhs.entryType == "countDown" }
            return abs(lhs.days) < abs(rhs.days)
        }
    }
}

private extension WidgetItem {
    static let preview = WidgetItem(id: UUID(), title: "Summer Trip", entryType: "countDown",
                                    startDate: nil, targetDate: .now.addingTimeInterval(86400 * 18),
                                    repeatRule: "none", timezoneID: TimeZone.current.identifier,
                                    colorHex: "#5B7CFA", iconEmoji: "✈️", isPinned: true)
}

private struct DayvellaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountEntry

    var body: some View {
        if let item = entry.items.first {
            switch family {
            case .systemMedium:
                VStack(spacing: 10) {
                    ForEach(Array(entry.items.prefix(3))) { row in
                        HStack {
                            Text(row.iconEmoji ?? "📅")
                            Text(row.title).font(.headline).lineLimit(1)
                            Spacer()
                            Text("\(row.days)").font(.title3.monospacedDigit().bold())
                        }
                    }
                }
                .containerBackground(.fill.tertiary, for: .widget)
            case .accessoryInline:
                Text("\(item.iconEmoji ?? "📅") \(item.title): \(item.days) days")
                    .containerBackground(.fill.tertiary, for: .widget)
            case .accessoryCircular:
                VStack(spacing: 0) {
                    Text(item.iconEmoji ?? "📅")
                    Text("\(item.days)").font(.headline.monospacedDigit())
                }
                .containerBackground(.fill.tertiary, for: .widget)
            default:
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.iconEmoji ?? "📅").font(.title2)
                    Text(item.title).font(.headline).lineLimit(2)
                    Spacer()
                    Text("\(item.days)").font(.system(.largeTitle, design: .rounded).bold()).monospacedDigit()
                    Text(item.entryType == "countUp" ? "days since" : "days to go").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .containerBackground(.fill.tertiary, for: .widget)
            }
        }
    }
}

@main
struct DayvellaWidget: Widget {
    // WidgetKit identifies already-installed widgets by this stable legacy kind.
    let kind = "CountMyDaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DayvellaWidgetView(entry: entry)
        }
        .configurationDisplayName("Dayvella")
        .description("See your pinned or nearest day counter at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}
