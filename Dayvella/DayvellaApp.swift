import SwiftUI

@main
struct DayvellaApp: App {
    @StateObject private var entryStore: EntryStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let store = EntryStore()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-SeedStoreScreenshots"), store.allItems().isEmpty {
            let entries = EntryTemplate.allCases.map { $0.draft().makeEntry(existing: nil) }
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
