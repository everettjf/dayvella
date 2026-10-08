import SwiftUI

struct EntrySummaryRow: View {
    let entry: Entry
    let isSelected: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    if let emoji = entry.iconEmoji { Text(emoji).font(.title2) }
                    Text(entry.title)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if entry.isPinned {
                        Image(systemName: "pin.fill").foregroundStyle(.secondary)
                    }
                }
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(entry.entryType.label).font(.subheadline).foregroundStyle(.secondary)
                        Spacer(minLength: 12)
                        dayCount(at: timeline.date)
                    }
                    VStack(alignment: .leading) {
                        Text(entry.entryType.label).font(.subheadline).foregroundStyle(.secondary)
                        dayCount(at: timeline.date)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: entry.colorHex).opacity(isSelected ? 0.22 : 0.10),
                        in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func dayCount(at date: Date) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(DayCounter.days(for: entry, now: date), format: .number)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
            Text("Days").font(.caption).foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct EntryDetailView: View {
    let entry: Entry
    let onAction: (EntryAction) -> Void

    var body: some View {
        Form {
            Section {
                EntryCardView(snapshot: EntrySnapshot(entry: entry))
                    .accessibilityIdentifier("entry-detail-card")
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
            }
            Section("Details") {
                if let date = entry.startDate, entry.entryType == .countUp {
                    dateRow("Start Date", date: date)
                }
                if let date = DayCounter.effectiveTargetDate(for: EntrySnapshot(entry: entry)), entry.entryType == .countDown {
                    dateRow("Target Date", date: date)
                }
                LabeledContent("Time Zone", value: entry.timezone.displayName)
                if entry.entryType == .countDown {
                    LabeledContent("Repeat", value: entry.repeatRule.label)
                }
                if let start = entry.rangeStart { dateRow("Range Start", date: start) }
                if let end = entry.rangeEnd { dateRow("Range End", date: end) }
                if entry.rangeStart != nil || entry.rangeEnd != nil {
                    LabeledContent("Outside Range", value: entry.outOfRangeBehavior.label)
                }
            }
            if let notes = entry.notes, !notes.isEmpty {
                Section("Notes") { Text(notes).textSelection(.enabled) }
            }
            if entry.entryType == .countDown, !entry.reminderOffsetsDays.isEmpty {
                Section("Reminders") {
                    ForEach(entry.reminderOffsetsDays.sorted(), id: \.self) { days in
                        if days == 0 { Text("On the day") }
                        else { Text("\(days) days before") }
                    }
                }
            }
            Section {
                Button("Edit", systemImage: "pencil") { onAction(.edit) }
                    .accessibilityIdentifier("edit-selected-entry")
                Button("Share Card", systemImage: "square.and.arrow.up") { onAction(.share) }
                if !entry.isArchived {
                    Button(entry.isPinned ? String(localized: "Unpin") : String(localized: "Pin"), systemImage: "pin") { onAction(.togglePin) }
                }
                Button(entry.isArchived ? String(localized: "Unarchive") : String(localized: "Archive"), systemImage: "archivebox") { onAction(.toggleArchive) }
                Button("Duplicate", systemImage: "plus.square.on.square") { onAction(.duplicate) }
                Button("Delete", systemImage: "trash", role: .destructive) { onAction(.delete) }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit", systemImage: "pencil") { onAction(.edit) }
            }
        }
    }

    private func dateRow(_ title: LocalizedStringKey, date: Date) -> some View {
        LabeledContent(title, value: DateFormatters.cardDateFormatter(for: entry.timezone).string(from: date))
    }
}
