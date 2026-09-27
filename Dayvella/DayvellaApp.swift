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
                EntryDraft(title: "Weekend getaway", entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 42, to: today), iconEmoji: "🏕️"),
                EntryDraft(title: "Project launch", entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 90, to: today), iconEmoji: "🚀"),
                EntryDraft(title: "Birthday", entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 120, to: today),
                           repeatRule: .yearly, iconEmoji: "🎂"),
                EntryDraft(title: "Anniversary", entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 65, to: today),
                           repeatRule: .yearly, iconEmoji: "❤️"),
                EntryDraft(title: "Next milestone", entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 96, to: today), iconEmoji: "🎯"),
                EntryDraft(title: "Learn something every day", entryType: .countUp,
                           startDate: calendar.date(byAdding: .day, value: -269, to: today), iconEmoji: "📚"),
                EntryDraft(title: "Tokyo adventure", entryType: .countDown,
                           targetDate: calendar.date(byAdding: .day, value: 80, to: today), iconEmoji: "✈️"),
                EntryDraft(title: "A new beginning", entryType: .countUp,
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

    var body: some Scene {
        WindowGroup {
            AppTabView()
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
