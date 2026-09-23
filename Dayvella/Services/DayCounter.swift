import Foundation

struct DayCounter {
    private static func calendar(for timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func startOfDay(_ date: Date, in timeZone: TimeZone) -> Date {
        calendar(for: timeZone).startOfDay(for: date)
    }

    static func days(for entry: Entry, now: Date = .now) -> Int {
        days(for: EntrySnapshot(entry: entry), now: now)
    }

    static func days(for snapshot: EntrySnapshot, now: Date = .now) -> Int {
        switch snapshot.entryType {
        case .countUp:
            return countUpDays(for: snapshot, now: now)
        case .countDown:
            return countDownDays(for: snapshot, now: now)
        }
    }

    static func effectiveTargetDate(for snapshot: EntrySnapshot, now: Date = .now) -> Date? {
        guard snapshot.entryType == .countDown, let target = snapshot.targetDate else { return nil }
        let calendar = calendar(for: snapshot.timezone)
        let normalizedTarget = calendar.startOfDay(for: target)
        let nextTarget = nextRepeatedTarget(from: normalizedTarget,
                                            rule: snapshot.repeatRule,
                                            now: now,
                                            in: snapshot.timezone)
        return nextTarget
    }
}

private extension DayCounter {
    static func countUpDays(for snapshot: EntrySnapshot, now: Date) -> Int {
        guard let start = snapshot.startDate else { return 0 }
        let range = normalizedRange(start: snapshot.rangeStart, end: snapshot.rangeEnd, in: snapshot.timezone)
        guard let effectiveNow = effectiveNow(for: now, range: range, behavior: snapshot.outOfRangeBehavior, in: snapshot.timezone) else {
            return 0
        }

        var effectiveStart = startOfDay(start, in: snapshot.timezone)
        if let rangeStart = range.start, effectiveStart < rangeStart {
            effectiveStart = rangeStart
        }
        if let rangeEnd = range.end, effectiveStart > rangeEnd {
            return 0
        }

        let calendar = calendar(for: snapshot.timezone)
        let components = calendar.dateComponents([.day], from: effectiveStart, to: effectiveNow)
        return components.day ?? 0
    }

    static func countDownDays(for snapshot: EntrySnapshot, now: Date) -> Int {
        guard let target = snapshot.targetDate else { return 0 }
        let calendar = calendar(for: snapshot.timezone)
        let normalizedTarget = calendar.startOfDay(for: target)
        let repeatedTarget = nextRepeatedTarget(from: normalizedTarget,
                                                rule: snapshot.repeatRule,
                                                now: now,
                                                in: snapshot.timezone)
        let range = normalizedRange(start: snapshot.rangeStart, end: snapshot.rangeEnd, in: snapshot.timezone)
        guard let effectiveNow = effectiveNow(for: now, range: range, behavior: snapshot.outOfRangeBehavior, in: snapshot.timezone) else {
            return 0
        }

        var effectiveTarget = repeatedTarget
        if let rangeStart = range.start, effectiveTarget < rangeStart {
            if snapshot.outOfRangeBehavior == .zero { return 0 }
            effectiveTarget = rangeStart
        }
        if let rangeEnd = range.end, effectiveTarget > rangeEnd {
            if snapshot.outOfRangeBehavior == .zero { return 0 }
            effectiveTarget = rangeEnd
        }

        let components = calendar.dateComponents([.day], from: effectiveNow, to: effectiveTarget)
        let dayDifference = components.day ?? 0
        return effectiveNow >= effectiveTarget ? min(0, dayDifference) : max(0, dayDifference)
    }

    static func normalizedRange(start: Date?, end: Date?, in timeZone: TimeZone) -> (start: Date?, end: Date?) {
        let calendar = calendar(for: timeZone)
        let normalizedStart = start.map { calendar.startOfDay(for: $0) }
        let normalizedEnd = end.map { calendar.startOfDay(for: $0) }
        if let normalizedStart, let normalizedEnd, normalizedStart > normalizedEnd {
            return (start: normalizedEnd, end: normalizedStart)
        }
        return (start: normalizedStart, end: normalizedEnd)
    }

    static func effectiveNow(for now: Date,
                             range: (start: Date?, end: Date?),
                             behavior: OutOfRangeBehavior,
                             in timeZone: TimeZone) -> Date? {
        let calendar = calendar(for: timeZone)
        let today = calendar.startOfDay(for: now)

        if let rangeStart = range.start, today < rangeStart {
            return behavior == .zero ? nil : rangeStart
        }
        if let rangeEnd = range.end, today > rangeEnd {
            return behavior == .zero ? nil : rangeEnd
        }
        return today
    }

    static func nextRepeatedTarget(from target: Date, rule: RepeatRule, now: Date, in timeZone: TimeZone) -> Date {
        guard rule != .none else { return target }
        let calendar = calendar(for: timeZone)
        let today = calendar.startOfDay(for: now)
        let targetComponents = calendar.dateComponents([.month, .day, .weekday], from: target)

        switch rule {
        case .none:
            return target
        case .yearly:
            guard let month = targetComponents.month, let day = targetComponents.day else { return target }
            let year = calendar.component(.year, from: today)
            let candidate = monthlyDate(year: year, month: month, day: day, calendar: calendar) ?? target
            if candidate < today {
                return monthlyDate(year: year + 1, month: month, day: day, calendar: calendar) ?? target
            }
            return candidate
        case .monthly:
            let year = calendar.component(.year, from: today)
            let month = calendar.component(.month, from: today)
            guard let day = targetComponents.day else { return target }
            let candidate = monthlyDate(year: year, month: month, day: day, calendar: calendar) ?? target
            if candidate < today {
                let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: candidate) ?? candidate
                let nextYear = calendar.component(.year, from: nextMonthDate)
                let nextMonth = calendar.component(.month, from: nextMonthDate)
                return monthlyDate(year: nextYear, month: nextMonth, day: day, calendar: calendar) ?? nextMonthDate
            }
            return candidate
        case .weekly:
            guard let weekday = targetComponents.weekday else { return target }
            let anchor = today.addingTimeInterval(-1)
            let match = calendar.nextDate(after: anchor,
                                          matching: DateComponents(weekday: weekday),
                                          matchingPolicy: .nextTimePreservingSmallerComponents,
                                          direction: .forward) ?? target
            return calendar.startOfDay(for: match)
        }
    }

    static func monthlyDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        guard let base = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: base) else { return nil }
        let clampedDay = min(day, range.count)
        return calendar.date(from: DateComponents(year: year, month: month, day: clampedDay))
    }
}
