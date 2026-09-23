// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DayvellaCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "DayvellaCore", targets: ["DayvellaCore"]),
    ],
    targets: [
        .target(
            name: "DayvellaCore",
            path: "Dayvella",
            exclude: [
                "Assets.xcassets",
                "Dayvella.entitlements",
                "DayvellaApp.swift",
                "Info.plist",
                "Resources",
                "Services/ExportService.swift",
                "Services/ImportService.swift",
                "Services/NotificationService.swift",
                "Services/CardShareService.swift",
                "Services/WidgetSnapshotService.swift",
                "Store",
                "Utilities/AppReviewManager.swift",
                "Utilities/Bundle+AppInfo.swift",
                "Utilities/Color+Hex.swift",
                "Utilities/DateFormatters.swift",
                "Utilities/DynamicTypeSize+Helpers.swift",
                "Utilities/TimeZone+List.swift",
                "Views",
                "Models/EntryTemplate.swift",
            ],
            sources: [
                "Models/Entry.swift",
                "Models/EntryDraft.swift",
                "Models/EntrySnapshot.swift",
                "Models/EntryType.swift",
                "Models/OutOfRangeBehavior.swift",
                "Models/RepeatRule.swift",
                "Models/SyncSnapshot.swift",
                "Services/DayCounter.swift",
                "Utilities/TrendingCardPalettes.swift",
            ]
        ),
        .testTarget(
            name: "DayvellaCoreTests",
            dependencies: ["DayvellaCore"],
            path: "Tests/DayvellaCoreTests"
        ),
    ]
)
