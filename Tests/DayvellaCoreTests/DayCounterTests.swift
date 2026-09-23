import Foundation
import Testing
@testable import DayvellaCore

struct DayCounterTests {
    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    @Test("Spring DST transition counts calendar days, not 24-hour blocks")
    func springDSTBoundary() {
        let start = date(2026, 3, 7, 12, in: losAngeles)
        let now = date(2026, 3, 9, 12, in: losAngeles)
        let entry = snapshot(type: .countUp, start: start, target: nil, timeZone: losAngeles)

        #expect(DayCounter.days(for: entry, now: now) == 2)
    }

    @Test("Fall DST transition counts calendar days, not 24-hour blocks")
    func fallDSTBoundary() {
        let target = date(2026, 10, 31, 12, in: losAngeles)
        let now = date(2026, 11, 2, 12, in: losAngeles)
        let entry = snapshot(type: .countDown, start: nil, target: target, timeZone: losAngeles)

        #expect(DayCounter.days(for: entry, now: now) == -2)
    }

    @Test("The same instant respects each entry's time zone")
    func crossTimeZoneBoundary() {
        let instant = isoDate("2026-01-01T07:30:00Z")
        let target = isoDate("2026-01-01T08:00:00Z")
        let laEntry = snapshot(type: .countDown, start: nil, target: target, timeZone: losAngeles)
        let tokyoEntry = snapshot(type: .countDown, start: nil, target: target, timeZone: tokyo)

        #expect(DayCounter.days(for: laEntry, now: instant) == 1)
        #expect(DayCounter.days(for: tokyoEntry, now: instant) == 0)
    }

    @Test("Leap day participates in Gregorian day counting")
    func leapYearBoundary() {
        let start = date(2024, 2, 28, 8, in: losAngeles)
        let now = date(2024, 3, 1, 8, in: losAngeles)
        let entry = snapshot(type: .countUp, start: start, target: nil, timeZone: losAngeles)

        #expect(DayCounter.days(for: entry, now: now) == 2)
    }

    @Test("A yearly leap-day target clamps to February 28 in non-leap years")
    func yearlyLeapDayRepeat() {
        let target = date(2024, 2, 29, 10, in: losAngeles)
        let now = date(2025, 2, 27, 23, in: losAngeles)
        let entry = snapshot(
            type: .countDown,
            start: nil,
            target: target,
            timeZone: losAngeles,
            repeatRule: .yearly
        )

        #expect(DayCounter.days(for: entry, now: now) == 1)
        #expect(DayCounter.effectiveTargetDate(for: entry, now: now) == date(2025, 2, 28, 0, in: losAngeles))
    }

    @Test("Times within the same local day resolve to zero")
    func sameDayBoundary() {
        let target = date(2026, 8, 4, 0, in: losAngeles)
        let now = date(2026, 8, 4, 23, 59, in: losAngeles)
        let entry = snapshot(type: .countDown, start: nil, target: target, timeZone: losAngeles)

        #expect(DayCounter.days(for: entry, now: now) == 0)
    }

    private func snapshot(
        type: EntryType,
        start: Date?,
        target: Date?,
        timeZone: TimeZone,
        repeatRule: RepeatRule = .none
    ) -> EntrySnapshot {
        EntrySnapshot(
            id: UUID(),
            title: "Test",
            entryType: type,
            startDate: start,
            targetDate: target,
            rangeStart: nil,
            rangeEnd: nil,
            outOfRangeBehavior: .zero,
            repeatRule: repeatRule,
            timezone: timeZone,
            colorHex: "#336699",
            iconEmoji: nil,
            notes: nil,
            isPinned: false,
            isArchived: false
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0, in timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func isoDate(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
