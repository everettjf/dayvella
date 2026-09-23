# Dayvella

Repository: <https://github.com/everettjf/dayvella>

[Website](https://xnu.app/dayvella/) · [App Store](https://apps.apple.com/app/id6753280745)

Previously named CountMyDays. Dayvella is an update to the same app, not a separate installation.

Dayvella is a SwiftUI iOS app for tracking countdowns and cumulative day counts. Create entries for important dates, track progress over time, and keep everything tidy with pinning, archiving, and export/import.


![Screenshot](screenshot.png)

## Features
- Countdown and cumulative (count up) trackers.
- Repeat rules for countdown targets (weekly, monthly, yearly).
- Optional date ranges with out-of-range behavior handling.
- Time zone aware day counting.
- Pin and archive entries for better organization.
- Automatic iCloud sync with local offline storage.
- JSON import/export for backups or migration.
- Local notifications for countdown target days.
- Home Screen and Lock Screen widgets for pinned and upcoming entries.
- Flexible reminders on the day, 1/3/7/30 days before, or a custom number of days.
- Quick-start templates for birthdays, anniversaries, trips, exams, and habit tracking.
- High-resolution card image sharing through the system share sheet.

## Requirements
- Xcode with iOS Simulator support.

## Build
```sh
xcodebuild -project Dayvella.xcodeproj -scheme Dayvella -sdk iphonesimulator build
```

## Run
Open `Dayvella.xcodeproj` in Xcode and select a simulator/device.

## Import/Export
- Exported files are JSON with ISO-8601 dates.
- Import accepts the same JSON schema and validates required fields.

## Data Storage and Migration
- Entries are stored locally for offline access and automatically synchronized through the user's iCloud account.
- Existing local-only data is uploaded to iCloud the first time this version launches.
- Sync uses last-modified timestamps and deletion records so edits and deletions merge safely across devices.

## Project Structure
- `Dayvella/`: main Swift/SwiftUI source.
- `Dayvella/Views/`: UI screens and reusable view components.
- `Dayvella/Models/`: data models (`Entry`, `EntryType`, etc.).
- `Dayvella/Services/`: app services (day counting, import/export, notifications).
- `Dayvella/Store/`: persistence and data store logic.
- `Dayvella/Utilities/`: helpers, formatters, extensions.
- `Dayvella/Assets.xcassets/` and `Dayvella/Resources/`: assets and bundled data.
- `Dayvella.xcodeproj/`: Xcode project metadata.

## Contributing
- Follow the guidelines in `AGENTS.md`.
- Keep changes focused and consistent with existing code style.
- Include screenshots or screen recordings for UI changes.

## Star History
[![Star History Chart](https://api.star-history.com/svg?repos=everettjf/dayvella&type=Date)](https://star-history.com/#everettjf/dayvella&Date)

## Rename compatibility

The Dayvella rename preserves the app identity and existing user data:

- App bundle ID: `com.xnu.countmydays`.
- Widget bundle ID: `com.xnu.countmydays.widget`.
- App Group: `group.com.xnu.countmydays`.
- iCloud key-value store entitlement and all storage/defaults keys remain unchanged.
- Local data continues to use the legacy `CountMyDays` directory.
- Installed widgets retain the `CountMyDaysWidget` kind.
- Exported filenames now start with `Dayvella`; the JSON format is unchanged and older exports remain importable.
- The App Store record remains `6753280745`. Old website routes redirect to `/dayvella/`.

The source folders, Xcode project/scheme, Swift package, app and widget display names now use Dayvella. Do not rename the legacy identifiers above when updating branding.
