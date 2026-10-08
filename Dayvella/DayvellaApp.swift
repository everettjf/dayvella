import SwiftUI

@main
struct DayvellaApp: App {
    @StateObject private var entryStore: EntryStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let store = EntryStore()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-SeedStoreScreenshots"), store.allItems().isEmpty {
            let calendar = Calendar.current
            let today = DayCounter.startOfDay(.now, in: .current)
            let samples: [EntryDraft] = [
                EntryDraft(title: String(localized: "Weekend getaway"), entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 42, to: today), iconEmoji: "🏕️"),
                EntryDraft(title: String(localized: "Project launch"), entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 90, to: today), iconEmoji: "🚀"),
                EntryDraft(title: String(localized: "Birthday"), entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 120, to: today),
                           repeatRule: .yearly, iconEmoji: "🎂"),
                EntryDraft(title: String(localized: "Anniversary"), entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 65, to: today),
                           repeatRule: .yearly, iconEmoji: "❤️"),
                EntryDraft(title: String(localized: "Next milestone"), entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 96, to: today), iconEmoji: "🎯"),
                EntryDraft(title: String(localized: "Learn something every day"), entryType: .countUp,
                           startDate: calendar.date(byAdding: .day, value: -269, to: today), iconEmoji: "📚"),
                EntryDraft(title: String(localized: "Tokyo adventure"), entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 80, to: today), iconEmoji: "✈️"),
                EntryDraft(title: String(localized: "A new beginning"), entryType: .countUp,
                           startDate: calendar.date(byAdding: .day, value: -366, to: today), iconEmoji: "🌱")
            ]
            let entries = samples.enumerated().map { index, sample in
                var draft = sample
                draft.colorHex = TrendingCardPalettes.all[index % TrendingCardPalettes.all.count].primaryHex
                return draft.makeEntry(existing: nil)
            }
            store.importEntries(entries)
        }
        #endif
        _entryStore = StateObject(wrappedValue: store)
    }

    @ViewBuilder
    private var screenshotContent: some View {
        #if DEBUG
        AppTabView()
            .sheet(isPresented: .constant(ProcessInfo.processInfo.arguments.contains("-StoreScreenshotEditor"))) {
                EntryEditView(draft: EntryDraft(title: String(localized: "Tokyo adventure"),
                    entryType: .countDown,
                    targetDate: Calendar.current.date(byAdding: .day, value: 80, to: .now),
                    iconEmoji: "✈️"), isNew: true, onSave: { _ in })
            }
        #else
        AppTabView()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            screenshotContent
                .environmentObject(entryStore)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                AppReviewManager.registerAppLaunch()
                entryStore.refresh()
                if !ProcessInfo.processInfo.arguments.contains("-SeedStoreScreenshots") {
                    NotificationService.shared.rescheduleAll(entryStore.allItems())
                }
            }
        }
    }
}
