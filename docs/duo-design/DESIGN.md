# Dayvella on iPhone Duo — design proposal

## Baseline inspected

Xcode 27.1 (27A9269), iOS 27.1 simulator, dedicated device `Dayvella Duo Design` (`C86E914A-3E0A-4C9E-AA81-AFC7C28E6142`). Existing source built successfully without feature changes or changes to the selected developer directory. Synthetic screenshot entries only.

The open display currently shows two large card columns. Standard navigation and tab controls move to the trailing vertical system bar when built against 27.1. HomeView limits regular-width content to 840 points and bases its metrics on size classes. Tapping a card currently opens an editor sheet; there is no persistent selected-entry detail view. The custom LiquidGlassTabBackground still assumes a bottom tab bar, so its relationship to the system's vertical bar needs review during implementation.

`current-open.png` and `current-book.png` are real baseline captures, not proposed UI. The closed capture also shows long date labels wrapping heavily and longer entry titles being truncated. Compact cards should give the title more space and reduce secondary date text. Simulator validation is not hardware validation.

## Recommended direction: browse and focus

- Outer display / narrow window: retain the current card feed and system-adaptive tabs; do not force a bottom bar. Selecting a date opens a detail destination with an explicit Edit action; edit sheets remain available. Preserve familiar quick templates and empty states.
- Flat inner display: use a navigation split between compact date cards and a selected-date panel. The detail panel contains a colored countdown, target or start date, repeat and reminder information, and Edit/Share/Pin actions. Let the system manage the trailing navigation/tab bar.
- Book pose: align both panes to system division regions. Keep each date card, number, field and primary action entirely within its region. Do not hard-code a central hinge width or a hinge angle threshold.
- Editor: replace the detail pane with the editor when there is adequate width. Keep the date list visible. Save commits the draft once; Cancel discards only the draft. Do not perform writes merely because the device folds.
- Closing while viewing a detail: carry the selected entry into the narrow navigation stack. Closing while editing: carry the same draft into the narrow editor. Reopening restores the list and current detail/editor. Keep search query, selected tab, scroll anchor, keyboard focus and draft together in scene-level state.
- Portrait inner display or large accessibility text: use the same narrow navigation flow if both panes cannot fit comfortably. Avoid squeezing two columns into the available width.
- Empty collection: use one purposeful empty state. When editing the first entry on the inner screen, put templates/context in the other pane; do not show two unrelated empty messages.

## Alternative: card gallery

Keep a two-column colored card gallery as the expanded home screen. Selecting a card enters the same list-and-editor workspace. This is closer to today's visual identity, but less efficient for inspecting several dates in succession. Recommended default: browse and focus; gallery can remain an optional presentation later.

## Implementation approach

Use `NavigationSplitView` for the list/detail navigation relationship. Use an availability-gated `ArrangementView` only for custom preview/editor arrangements inside a navigation container. Do not nest navigation containers inside ArrangementView. Query `GeometryProxy.reservedRegions(kind: .division)` and `.occlusion` where custom content requires displacement; do not identify layout from the model name. Prefer standard toolbars, tabs, sheets, alerts and popovers.

Keep iOS 26 deployment support with availability checks for 27.1-only APIs. Leave bundle IDs, App Group, widget kind, iCloud identities, JSON schema and submitted 1.3 build unchanged. Implement as the next version after the design is accepted.

## Validation matrix for implementation

Closed, flat open, book, rotated open, short window, keyboard visible, largest Dynamic Type, light/dark, and all 11 supported languages. Check that toolbar backgrounds do not remain underneath content after the system bar changes orientation. Fold/unfold while searching, editing, sharing and displaying a confirmation. Ensure no loss of selected entry, drafts or navigation state. Validate both countdown and cumulative dates, first-entry creation, deletion of selected entries, filters and empty results.

## Sources

- https://developer.apple.com/iphone-duo/prepare/
- https://developer.apple.com/videos/play/tech-talks/111463/
- Local Xcode 27.1 SwiftUICore SDK declarations confirm ArrangementView, ReservedRegion and GeometryProxy.reservedRegions.
