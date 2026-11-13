import XCTest

@MainActor final class TowerRushUITests: XCTestCase {
    func shot(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testLandscapeLayout() throws {
        let app = XCUIApplication()
        app.launch()
        if app.buttons["resumeButton"].waitForExistence(timeout: 2) {
            app.buttons["resumeButton"].tap()
        } else {
            app.buttons["Play"].firstMatch.tap()
            app.buttons["buildButton"].tap()
        }
        XCTAssertTrue(app.buttons["placeButton"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: app.buttons["placeButton"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        shot("10-landscape-screen", app)
        app.buttons["pauseButton"].tap()
        XCTAssertTrue(app.buttons["resumeButton"].exists)
        shot("11-landscape-paused", app)
        XCUIDevice.shared.orientation = .portrait
        app.buttons["Finish attempt"].tap()
        app.buttons["Save and finish"].tap()
        app.buttons["Close result"].tap()
    }
    func testFullJourney() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["buildButton"].waitForExistence(timeout: 10))
        shot("01-home", app)
        app.buttons["Locations"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Higher horizons"].exists)
        shot("02-locations", app)
        app.buttons["Collection"].firstMatch.tap()
        app.buttons["Preview Aurora, locked"].tap()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Make 15 perfect placements in a row"].exists)
        shot("03-collection", app)
        app.buttons["Profile"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Keep on climbing"].exists)
        let toggle = app.switches["Reduce motion"]
        if !toggle.isHittable { app.swipeUp() }
        toggle.tap()
        shot("04-profile", app)
        app.buttons["Collection"].firstMatch.tap()
        XCTAssertEqual(app.buttons["Preview Aurora, locked"].value as? String, "Previewing")
        app.buttons["Play"].firstMatch.tap()
        app.buttons["buildButton"].tap()
        XCTAssertTrue(app.buttons["placeButton"].waitForExistence(timeout: 3))
        shot("05-game", app)
        XCUIDevice.shared.orientation = .landscapeLeft
        if app.buttons["resumeButton"].waitForExistence(timeout: 2) { app.buttons["resumeButton"].tap() }
        let hittable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: app.buttons["placeButton"])
        let rotationReady = XCTWaiter.wait(for: [hittable], timeout: 5)
        shot("05b-game-landscape", app)
        XCTAssertEqual(rotationReady, .completed)
        XCUIDevice.shared.orientation = .portrait
        if app.buttons["resumeButton"].waitForExistence(timeout: 2) { app.buttons["resumeButton"].tap() }
        app.buttons["pauseButton"].tap()
        XCTAssertTrue(app.buttons["resumeButton"].exists)
        shot("06-paused", app)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["resumeButton"].waitForExistence(timeout: 5))
        app.buttons["resumeButton"].tap()
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["resumeButton"].waitForExistence(timeout: 3))
        app.buttons["resumeButton"].tap()
        app.buttons["placeButton"].tap()
        if app.buttons["pauseButton"].waitForExistence(timeout: 1) {
            app.buttons["pauseButton"].tap()
            app.buttons["Finish attempt"].tap()
            app.buttons["Save and finish"].tap()
        }
        XCTAssertTrue(app.buttons["reviewButton"].waitForExistence(timeout: 5))
        shot("07-result", app)
        app.buttons["reviewButton"].tap()
        XCTAssertTrue(app.navigationBars["Placement review"].waitForExistence(timeout: 3))
        shot("08-review", app)
        app.buttons["Done"].tap()
        app.buttons["Close result"].tap()
        XCTAssertTrue(app.buttons["dailyButton"].waitForExistence(timeout: 3))
        app.buttons["dailyButton"].tap()
        XCTAssertTrue(app.staticTexts["DAILY CLIMB"].waitForExistence(timeout: 3))
        app.buttons["pauseButton"].tap()
        app.buttons["Finish attempt"].tap()
        app.buttons["Save and finish"].tap()
        app.buttons["Close result"].tap()
        app.buttons["Profile"].firstMatch.tap()
        app.swipeUp()
        shot("09-history", app)
    }
}
