import Foundation

final class ImportService {
    struct RowStatus: Identifiable {
        enum State { case success, skipped(String) }
        let id = UUID()
        let title: String
        let state: State
    }

    struct Summary {
        let statuses: [RowStatus]
        var importedCount: Int { statuses.filter { if case .success = $0.state { return true } else { return false } }.count }
        var skippedCount: Int { statuses.count - importedCount }
    }

    private unowned let store: EntryStore

    init(store: EntryStore) {
        self.store = store
    }

    func importEntries(from url: URL) -> Summary {
        var rows: [RowStatus] = []
        var imported: [Entry] = []

        do {
            let data = try loadData(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let dtos: [ImportEntryDTO]
            if let direct = try? decoder.decode([ImportEntryDTO].self, from: data) {
                dtos = direct
            } else {
                let payload = try decoder.decode(ImportPayload.self, from: data)
                guard payload.version == 1 else {
                    rows.append(RowStatus(title: "Invalid Version", state: .skipped("Unsupported import version \(payload.version)")))
                    return Summary(statuses: rows)
                }
                dtos = payload.entries
            }

            for dto in dtos {
                let displayTitle = (dto.title ?? "Untitled").trimmingCharacters(in: .whitespacesAndNewlines)
                do {
                    let entry = try process(dto)
                    imported.append(entry)
                    rows.append(RowStatus(title: displayTitle.isEmpty ? "Untitled" : displayTitle, state: .success))
                } catch let error as ImportError {
                    rows.append(RowStatus(title: displayTitle.isEmpty ? "Untitled" : displayTitle, state: .skipped(error.message)))
                } catch {
                    rows.append(RowStatus(title: displayTitle.isEmpty ? "Untitled" : displayTitle, state: .skipped(error.localizedDescription)))
                }
            }

            if !imported.isEmpty {
                store.importEntries(imported)
            }
        } catch {
            rows.append(RowStatus(title: "Import Failed", state: .skipped(error.localizedDescription)))
        }

        return Summary(statuses: rows)
    }
}

private extension ImportService {
    /// Loads JSON data while handling security-scoped URLs returned by the file importer.
    func loadData(from url: URL) throws -> Data {
        let shouldStop = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStop {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            var coordinationError: NSError?
            var result: Data?
            let coordinator = NSFileCoordinator(filePresenter: nil)
            coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { coordinatedURL in
                result = try? Data(contentsOf: coordinatedURL)
            }

            if let data = result {
                return data
            }

            if let coordinationError {
                throw coordinationError
            }

            throw error
        }
    }

    func process(_ dto: ImportEntryDTO) throws -> Entry {
        let title = (dto.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw ImportError.validation("Title is required") }
        guard let type = dto.type.flatMap(EntryType.init(rawValue:)) else { throw ImportError.validation("Unsupported type") }

        let timezoneID = dto.timezone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? TimeZone.current.identifier
        guard let timezone = TimeZone(identifier: timezoneID) else { throw ImportError.validation("Invalid timezone identifier") }

        let identifier = dto.id ?? UUID()
        if store.entry(with: identifier) != nil {
            throw ImportError.duplicate("Entry already exists – skipped")
        }

        var entry = Entry(id: identifier, title: title, entryType: type, timezoneID: timezoneID)
        if let providedColor = dto.color, !providedColor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            entry.colorHex = sanitize(color: providedColor, fallback: entry.colorHex)
        } else {
            entry.colorHex = TrendingCardPalettes.randomPrimaryHex()
        }
        entry.iconEmoji = dto.iconEmoji?.isEmpty == true ? nil : dto.iconEmoji
        entry.notes = dto.notes
        entry.reminderOffsetsDays = Array(Set((dto.reminderOffsetsDays ?? [0]).filter { $0 >= 0 && $0 <= 3650 })).sorted()
        entry.isArchived = dto.isArchived ?? false
        entry.isPinned = (dto.isPinned ?? false) && !entry.isArchived

        switch type {
        case .countUp:
            guard let start = dto.start else { throw ImportError.validation("start is required for countUp") }
            entry.startDate = DayCounter.startOfDay(start, in: timezone)
            entry.targetDate = nil
        case .countDown:
            guard let target = dto.target else { throw ImportError.validation("target is required for countDown") }
            entry.targetDate = DayCounter.startOfDay(target, in: timezone)
            entry.startDate = nil
        }

        entry.rangeStart = dto.rangeStart.map { DayCounter.startOfDay($0, in: timezone) }
        entry.rangeEnd = dto.rangeEnd.map { DayCounter.startOfDay($0, in: timezone) }
        if let start = entry.rangeStart, let end = entry.rangeEnd, start > end {
            entry.rangeStart = end
            entry.rangeEnd = start
        }

        if let behavior = dto.outOfRangeBehavior?.lowercased(),
           let parsed = OutOfRangeBehavior(rawValue: behavior) {
            entry.outOfRangeBehavior = parsed
        }

        if type == .countDown, let rule = dto.repeatRule?.lowercased(),
           let parsed = RepeatRule(rawValue: rule) {
            entry.repeatRule = parsed
        }

        entry.stampTimestamps(asNew: true)
        return entry
    }

    func sanitize(color: String?, fallback: String) -> String {
        guard let value = color, !value.isEmpty else { return fallback }
        var hex = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        let valid = Set("0123456789ABCDEF")
        guard hex.count == 6, hex.allSatisfy({ valid.contains($0) }) else { return fallback }
        return "#" + hex
    }
}

private enum ImportError: Error {
    case validation(String)
    case duplicate(String)

    var message: String {
        switch self {
        case .validation(let reason):
            return reason
        case .duplicate(let reason):
            return reason
        }
    }
}

private struct ImportPayload: Decodable {
    let version: Int
    let entries: [ImportEntryDTO]
}

private struct ImportEntryDTO: Decodable {
    let id: UUID?
    let title: String?
    let type: String?
    let start: Date?
    let target: Date?
    let rangeStart: Date?
    let rangeEnd: Date?
    let outOfRangeBehavior: String?
    let repeatRule: String?
    let timezone: String?
    let color: String?
    let iconEmoji: String?
    let notes: String?
    let reminderOffsetsDays: [Int]?
    let isPinned: Bool?
    let isArchived: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case type
        case start
        case target
        case startDate
        case targetDate
        case rangeStart
        case rangeEnd
        case outOfRangeBehavior
        case rangeBehavior
        case repeatRule
        case `repeat`
        case timezone
        case color
        case colorHex
        case iconEmoji
        case icon
        case notes
        case reminderOffsetsDays
        case isPinned
        case isArchived
        case pinned
        case archived
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        start = try container.decodeIfPresent(Date.self, forKey: .start) ?? container.decodeIfPresent(Date.self, forKey: .startDate)
        target = try container.decodeIfPresent(Date.self, forKey: .target) ?? container.decodeIfPresent(Date.self, forKey: .targetDate)
        rangeStart = try container.decodeIfPresent(Date.self, forKey: .rangeStart)
        rangeEnd = try container.decodeIfPresent(Date.self, forKey: .rangeEnd)
        outOfRangeBehavior = try container.decodeIfPresent(String.self, forKey: .outOfRangeBehavior) ?? container.decodeIfPresent(String.self, forKey: .rangeBehavior)
        repeatRule = try container.decodeIfPresent(String.self, forKey: .repeatRule) ?? container.decodeIfPresent(String.self, forKey: .repeat)
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? container.decodeIfPresent(String.self, forKey: .colorHex)
        iconEmoji = try container.decodeIfPresent(String.self, forKey: .iconEmoji) ?? container.decodeIfPresent(String.self, forKey: .icon)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reminderOffsetsDays = try container.decodeIfPresent([Int].self, forKey: .reminderOffsetsDays)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .pinned) ?? container.decodeIfPresent(Bool.self, forKey: .isPinned)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .archived) ?? container.decodeIfPresent(Bool.self, forKey: .isArchived)
    }
}
