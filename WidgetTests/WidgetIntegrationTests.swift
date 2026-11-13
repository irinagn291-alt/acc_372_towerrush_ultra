import XCTest

final class WidgetIntegrationTests: XCTestCase {
    @MainActor func testGallerySizesSharedDataAndDeepLink() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-WidgetQA"]
        app.launch()
        app.open(URL(string: "towerrush://widget/play?qa=1")!)
        XCTAssertTrue(app.wait(for:.runningForeground,timeout:10))
        attach("app-widget-destination",app)
        XCUIDevice.shared.press(.home)
        let board = XCUIApplication(bundleIdentifier:"com.apple.springboard")
        board.coordinate(withNormalizedOffset:CGVector(dx:0.78,dy:0.76)).press(forDuration:1.6)
        if board.buttons["Edit Home Screen"].waitForExistence(timeout:2) { board.buttons["Edit Home Screen"].tap() }
        let edit = board.buttons["Edit"]
        XCTAssertTrue(edit.waitForExistence(timeout:5),board.debugDescription);edit.tap()
        let addWidget = board.descendants(matching:.any).matching(NSPredicate(format:"label ==[c] 'Add Widget'")).firstMatch
        XCTAssertTrue(addWidget.waitForExistence(timeout:5),board.debugDescription);addWidget.tap()
        let search = board.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout:5),board.debugDescription);search.tap();search.typeText("Tower Rush")
        let result = board.cells["Tower Rush"]
        XCTAssertTrue(result.waitForExistence(timeout:10),board.debugDescription);result.tap()
        XCTAssertTrue(board.staticTexts["Your skyline"].waitForExistence(timeout:10),board.debugDescription)
        attach("widget-small",board)
        board.buttons.matching(NSPredicate(format:"label == %@ AND value CONTAINS 'Widget'", "Tower Rush, Your skyline")).firstMatch.swipeLeft()
        attach("widget-medium",board)
        let insert = board.buttons.matching(NSPredicate(format:"label CONTAINS[c] 'Add Widget'")).firstMatch
        XCTAssertTrue(insert.waitForExistence(timeout:5),board.debugDescription);insert.tap()
        if board.buttons["Done"].waitForExistence(timeout:5) { board.buttons["Done"].tap() }
        attach("widget-installed",board)
        let installed = board.icons.matching(NSPredicate(format:"label == %@ AND value CONTAINS 'Widget'", "Tower Rush")).firstMatch
        XCTAssertTrue(installed.waitForExistence(timeout:10),board.debugDescription)
        installed.tap()
        XCTAssertTrue(app.wait(for:.runningForeground,timeout:10))
        attach("widget-opened-app",app)
        app.open(URL(string:"towerrush://widget/play?qa=2")!)
        XCTAssertTrue(app.wait(for:.runningForeground,timeout:10))
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(installed.staticTexts["4"] .waitForExistence(timeout:45),board.debugDescription)
        attach("widget-updated",board)
    }
    @MainActor private func attach(_ name:String,_ app:XCUIApplication) {
        let attachment = XCTAttachment(screenshot:app.screenshot());attachment.name=name;attachment.lifetime = .keepAlways;add(attachment)
        let tree = XCTAttachment(string:app.debugDescription);tree.name=name+"-accessibility";tree.lifetime = .keepAlways;add(tree)
    }
}
