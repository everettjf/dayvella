import XCTest

final class EntryWorkspaceTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-SeedStoreScreenshots", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    private func openEditor() {
        let entry = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'entry-'")).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 15))
        entry.tap()
        let edit = app.buttons["edit-selected-entry"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        XCTAssertTrue(app.textFields["Title"].waitForExistence(timeout: 5))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSaveUpdatesSelectedDetail() {
        openEditor()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText(" saved edit")
        let edited = title.value as? String
        capture("workspace-editor")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["edit-selected-entry"].waitForExistence(timeout: 5))
        app.buttons["edit-selected-entry"].tap()
        XCTAssertEqual(app.textFields["Title"].value as? String, edited)
        app.buttons["Cancel"].tap()
        capture("workspace-detail")
    }

    func testCancelKeepsOriginalTitle() {
        openEditor()
        let title = app.textFields["Title"]
        let original = title.value as? String
        title.tap()
        title.press(forDuration: 1)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) { app.menuItems["Select All"].tap() }
        title.typeText(" unsaved")
        app.buttons["Cancel"].tap()
        app.buttons["edit-selected-entry"].tap()
        XCTAssertEqual(app.textFields["Title"].value as? String, original)
    }

    func testDraftSurvivesRotation() {
        openEditor()
        let title = app.textFields["Title"]
        title.tap()
        title.typeText(" rotation draft")
        let draftTitle = title.value as? String
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.textFields["Title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["Title"].value as? String, draftTitle)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertEqual(app.textFields["Title"].value as? String, draftTitle)
        app.buttons["Cancel"].tap()
    }
}
