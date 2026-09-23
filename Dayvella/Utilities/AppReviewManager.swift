import Foundation
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

enum AppReviewManager {
    private static let launchCountKey = "AppReviewManager.launchCount"
    private static let saveCountKey = "AppReviewManager.saveCount"
    private static let lastPromptDateKey = "AppReviewManager.lastPromptDate"

    static func registerAppLaunch() {
        incrementCounter(forKey: launchCountKey)
        scheduleEvaluation()
    }

    static func registerSuccessfulSave() {
        incrementCounter(forKey: saveCountKey)
        scheduleEvaluation()
    }

    private static func incrementCounter(forKey key: String) {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: key)
        defaults.set(count + 1, forKey: key)
    }

    private static func scheduleEvaluation() {
        Task { await evaluateIfNeeded() }
    }

    @MainActor
    private static func evaluateIfNeeded() async {
        let defaults = UserDefaults.standard
        let launchCount = defaults.integer(forKey: launchCountKey)
        let saveCount = defaults.integer(forKey: saveCountKey)

        guard launchCount >= 3, saveCount >= 3 else { return }

        if let lastPrompt = defaults.object(forKey: lastPromptDateKey) as? Date,
           Calendar.current.isDate(lastPrompt, inSameDayAs: Date()) {
            return
        }

        await requestReview()
        defaults.set(Date(), forKey: lastPromptDateKey)
    }

    @MainActor
    private static func requestReview() async {
#if canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }
        try? await AppStore.requestReview(in: scene)
#endif
    }
}
