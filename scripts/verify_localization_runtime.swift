// Run after building: swift scripts/verify_localization_runtime.swift /tmp/dayvella-i18n
import Foundation

let buildDirectory = CommandLine.arguments.dropFirst().first ?? "/tmp/dayvella-i18n"
let appPath = "\(buildDirectory)/Build/Products/Debug-iphonesimulator/Dayvella.app"
let expectedDays: [String: [String]] = [
    "en": ["1 day", "2 days", "5 days"],
    "zh-Hans": ["1 天", "2 天", "5 天"],
    "ja": ["1日", "2日", "5日"],
    "ko": ["1일", "2일", "5일"],
    "de": ["1 Tag", "2 Tage", "5 Tage"],
    "fr": ["1 jour", "2 jours", "5 jours"],
    "es": ["1 día", "2 días", "5 días"],
    "it": ["1 giorno", "2 giorni", "5 giorni"],
    "pt-BR": ["1 dia", "2 dias", "5 dias"],
    "ru": ["1 день", "2 дня", "5 дней"],
    "vi": ["1 ngày", "2 ngày", "5 ngày"]
]
for (language, expected) in expectedDays.sorted(by: { $0.key < $1.key }) {
    guard let appBundle = Bundle(path: "\(appPath)/\(language).lproj"),
          let widgetBundle = Bundle(path: "\(appPath)/PlugIns/DayvellaWidget.appex/\(language).lproj") else {
        fatalError("Missing compiled resources: \(language)")
    }
    let locale = Locale(identifier: language)
    for (index, count) in [1, 2, 5].enumerated() {
        let actual = String(localized: "\(count) days", bundle: appBundle, locale: locale)
        precondition(actual == expected[index], "Wrong plural: \(language): \(actual)")
    }
    for count in [0, 1, 2, 5, 11, 21, 22, 101] {
        let reminder = String(localized: "\(count) days to go", bundle: appBundle, locale: locale)
        let before = String(localized: "\(count) days before", bundle: appBundle, locale: locale)
        let custom = String(localized: "Custom: \(count) days before", bundle: appBundle, locale: locale)
        let entries = String(localized: "You currently have \(count) entries.", bundle: appBundle, locale: locale)
        for text in [reminder, before, custom, entries] {
            precondition(!text.contains("%") && !text.contains("#@"), "Unresolved formatting: \(language): \(text)")
        }
        if language == "ru" {
            let expected = [0: "Осталось 0 дней", 1: "Остался 1 день", 2: "Осталось 2 дня", 5: "Осталось 5 дней", 11: "Осталось 11 дней", 21: "Остался 21 день", 22: "Осталось 22 дня", 101: "Остался 101 день"]
            precondition(reminder == expected[count], "Wrong Russian plural: \(reminder)")
        }
        let icon = "✈️"
        let title = "東京 %@ 100%"
        let widgetLine = String(localized: "\(icon) \(title): \(count) days", bundle: widgetBundle, locale: locale)
        precondition(widgetLine.contains("\(icon) \(title)") && !widgetLine.contains("#@"), "Widget interpolation changed user text: \(language)")
        let copy = String(localized: "\(title) (Copy)", bundle: appBundle, locale: locale)
        precondition(copy.contains(title), "Copy interpolation changed user text: \(language)")
    }
    print("\(language): app, reminders, copy titles, and widget formatting passed")
}
