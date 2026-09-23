import SwiftUI

struct EntryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: EntryDraft
    var isNew: Bool
    var onSave: (EntryDraft) -> Void
    var onDelete: (() -> Void)?

    @State private var showingTimeZonePicker = false
    @FocusState private var focusedField: FocusedField?
    @State private var showDeleteConfirmation = false
    @State private var customReminderDays = 14

    private let presetReminderDays = [0, 1, 3, 7, 30]

    private let colorPalette: [TrendingCardPalette] = TrendingCardPalettes.all
    private var layout: EditLayout {
        EditLayout(horizontalSizeClass: horizontalSizeClass, dynamicTypeSize: dynamicTypeSize)
    }
    private var colorGridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(36), spacing: layout.colorGridSpacing), count: layout.colorColumnCount)
    }

    init(draft: EntryDraft, isNew: Bool, onSave: @escaping (EntryDraft) -> Void, onDelete: (() -> Void)? = nil) {
        _draft = State(initialValue: draft)
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $draft.title)
                        .font(.system(.body, design: .rounded))
                        .focused($focusedField, equals: .title)
                    Picker("Type", selection: $draft.entryType) {
                        ForEach(EntryType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(draft.entryType == .countUp ? "Start" : "Target") {
                    if draft.entryType == .countUp {
                        DatePicker("Start Date", selection: Binding($draft.startDate, replacingNilWith: Date()), displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                    } else {
                        DatePicker("Target Date", selection: Binding($draft.targetDate, replacingNilWith: Date()), displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                    }

                    Button {
                        showingTimeZonePicker = true
                    } label: {
                        HStack {
                            Text("Time Zone")
                            Spacer()
                            Text(draft.timezone.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Advanced") {
                    Toggle("Use Date Range", isOn: rangeEnabled)

                    if rangeEnabled.wrappedValue {
                        DatePicker("Range Start", selection: rangeStartBinding, displayedComponents: [.date])
                        DatePicker("Range End", selection: rangeEndBinding, displayedComponents: [.date])

                        Picker("Outside Range", selection: $draft.outOfRangeBehavior) {
                            ForEach(OutOfRangeBehavior.allCases) { behavior in
                                Text(behavior.label).tag(behavior)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if draft.entryType == .countDown {
                        Picker("Repeat", selection: $draft.repeatRule) {
                            ForEach(RepeatRule.allCases) { rule in
                                Text(rule.label).tag(rule)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: colorGridColumns, spacing: layout.colorGridSpacing) {
                            ForEach(colorPalette) { palette in
                                Button {
                                    draft.colorHex = palette.primaryHex
                                } label: {
                                    Circle()
                                        .fill(LinearGradient(
                                            colors: palette.colors.map { Color(hex: $0) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    Color.white.opacity(isSelected(palette) ? 0.9 : 0.2),
                                                    lineWidth: isSelected(palette) ? 3 : 1
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(palette.name)
                                .accessibilityValue(isSelected(palette) ? "Selected" : "Not selected")
                            }
                        }

                        Text("Notes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                        TextEditor(text: Binding($draft.notes, replacingNilWith: ""))
                            .frame(minHeight: 80)
                            .focused($focusedField, equals: .notes)
                    }
                    .padding(.vertical, 4)
                }

                if draft.entryType == .countDown {
                    Section {
                        ForEach(presetReminderDays, id: \.self) { days in
                            Toggle(reminderLabel(for: days), isOn: reminderBinding(days: days))
                        }
                        HStack {
                            Stepper("Custom: \(customReminderDays) days before",
                                    value: $customReminderDays, in: 1...3650)
                            Button("Add") {
                                draft.reminderOffsetsDays = Array(Set(draft.reminderOffsetsDays + [customReminderDays])).sorted()
                            }
                            .buttonStyle(.bordered)
                        }
                        ForEach(customReminderOffsets, id: \.self) { days in
                            HStack {
                                Text("\(days) days before")
                                Spacer()
                                Button("Remove", systemImage: "minus.circle", role: .destructive) {
                                    draft.reminderOffsetsDays.removeAll { $0 == days }
                                }
                                .labelStyle(.iconOnly)
                            }
                        }
                    } header: {
                        Text("Reminders")
                    } footer: {
                        Text("Notifications are delivered at 8:00 AM in the entry's time zone.")
                    }
                }

                Section("Preview") {
                    EntryCardView(snapshot: EntrySnapshot(draft: draft))
                        .padding(.vertical, 8)
                }

                if !isNew, onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .modifier(CenteredFormModifier(layout: layout))
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    hideKeyboard()
                }
            )
            .navigationTitle(isNew ? "New Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingTimeZonePicker) {
                TimeZonePickerView { selection in
                    draft.timezone = selection
                }
            }
        }
        .onAppear {
            focusedField = isNew ? .title : nil
        }

        .alert("Delete Entry?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .onChange(of: draft.entryType) { _, newValue in
            switch newValue {
            case .countUp:
                if draft.startDate == nil { draft.startDate = Date() }
                draft.targetDate = nil
                draft.repeatRule = .none
            case .countDown:
                if draft.targetDate == nil { draft.targetDate = Date().addingTimeInterval(86_400) }
                draft.startDate = nil
            }
        }
    }

    private func isSelected(_ palette: TrendingCardPalette) -> Bool {
        TrendingCardPalettes.resolvedPrimaryHex(for: draft.colorHex) == palette.primaryHex
    }

    private var isFormValid: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && dateIsValid
    }

    private var dateIsValid: Bool {
        switch draft.entryType {
        case .countUp:
            return draft.startDate != nil
        case .countDown:
            return draft.targetDate != nil
        }
    }

    private var rangeEnabled: Binding<Bool> {
        Binding(get: {
            draft.rangeStart != nil || draft.rangeEnd != nil
        }, set: { enabled in
            if enabled {
                if draft.rangeStart == nil {
                    draft.rangeStart = draft.entryType == .countUp ? (draft.startDate ?? Date()) : Date()
                }
                if draft.rangeEnd == nil {
                    if draft.entryType == .countDown, let target = draft.targetDate {
                        draft.rangeEnd = target
                    } else {
                        draft.rangeEnd = Date().addingTimeInterval(86_400 * 7)
                    }
                }
            } else {
                draft.rangeStart = nil
                draft.rangeEnd = nil
            }
        })
    }

    private var customReminderOffsets: [Int] {
        draft.reminderOffsetsDays.filter { !presetReminderDays.contains($0) }.sorted()
    }

    private func reminderBinding(days: Int) -> Binding<Bool> {
        Binding {
            draft.reminderOffsetsDays.contains(days)
        } set: { isEnabled in
            if isEnabled {
                draft.reminderOffsetsDays = Array(Set(draft.reminderOffsetsDays + [days])).sorted()
            } else {
                draft.reminderOffsetsDays.removeAll { $0 == days }
            }
        }
    }

    private func reminderLabel(for days: Int) -> String {
        days == 0 ? "On the day" : "\(days) days before"
    }

    private var rangeStartBinding: Binding<Date> {
        Binding($draft.rangeStart, replacingNilWith: Date())
    }

    private var rangeEndBinding: Binding<Date> {
        Binding($draft.rangeEnd, replacingNilWith: Date())
    }

    private func save() {
        onSave(draft)
        dismiss()
    }

    private func hideKeyboard() {
        focusedField = nil
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

private enum FocusedField {
    case title
    case notes
}

private extension Binding where Value == Date {
    init(_ source: Binding<Date?>, replacingNilWith fallback: Date) {
        self.init(get: {
            source.wrappedValue ?? fallback
        }, set: { newValue in
            source.wrappedValue = newValue
        })
    }
}

private extension Binding where Value == String {
    init(_ source: Binding<String?>, replacingNilWith fallback: String) {
        self.init(get: {
            source.wrappedValue ?? fallback
        }, set: { newValue in
            source.wrappedValue = newValue.isEmpty ? nil : newValue
        })
    }
}

private struct EditLayout {
    let contentWidth: CGFloat?
    let horizontalPadding: CGFloat
    let colorColumnCount: Int
    let colorGridSpacing: CGFloat

    init(horizontalSizeClass: UserInterfaceSizeClass?, dynamicTypeSize: DynamicTypeSize) {
        let useWideLayout = horizontalSizeClass == .regular && !dynamicTypeSize.isAccessibilitySize
        contentWidth = useWideLayout ? 900 : nil
        horizontalPadding = useWideLayout ? 40 : 0
        colorColumnCount = useWideLayout ? 8 : 5
        colorGridSpacing = useWideLayout ? 16 : 12
    }
}

private struct CenteredFormModifier: ViewModifier {
    let layout: EditLayout

    func body(content: Content) -> some View {
        Group {
            if let width = layout.contentWidth {
                content
                    .frame(maxWidth: width)
                    .padding(.horizontal, layout.horizontalPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                content
            }
        }
    }
}
