import SwiftUI

enum EntryAction {
    case edit
    case togglePin
    case duplicate
    case share
    case toggleArchive
    case delete
}

struct EntryListItemView: View {
    let entry: Entry
    var onAction: (Entry, EntryAction) -> Void

    var body: some View {
        Button {
            onAction(entry, .edit)
        } label: {
            EntryCardView(snapshot: EntrySnapshot(entry: entry))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(entry.isPinned ? "Unpin" : "Pin") {
                onAction(entry, .togglePin)
            }
            Button(entry.isArchived ? "Unarchive" : "Archive") {
                onAction(entry, .toggleArchive)
            }
            Button("Duplicate") {
                onAction(entry, .duplicate)
            }
            Button("Share Card", systemImage: "square.and.arrow.up") {
                onAction(entry, .share)
            }
            Divider()
            Button("Edit") {
                onAction(entry, .edit)
            }
            Button(role: .destructive) {
                onAction(entry, .delete)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to edit entry")
    }

    private var accessibilityLabel: String {
        let days = DayCounter.days(for: entry)
        let formatter = DateFormatters.accessibilityFormatter
        let daysString = formatter.string(from: DateComponents(day: abs(days))) ?? "\(abs(days)) days"
        switch entry.entryType {
        case .countUp:
            if days >= 0 {
                return "\(entry.title), \(daysString) since start"
            } else {
                return "\(entry.title), starts in \(daysString)"
            }
        case .countDown:
            if days >= 0 {
                return "\(entry.title), \(daysString) remaining"
            } else {
                return "\(entry.title), target passed \(daysString) ago"
            }
        }
    }
}
