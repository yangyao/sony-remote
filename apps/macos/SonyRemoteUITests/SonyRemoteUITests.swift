import XCTest

final class SonyRemoteUITests: XCTestCase {
    func testRemoteAndConnection() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        // Disable network work instead of overriding persistent connection settings.
        app.launchArguments = ["--ui-testing"]
        app.launch()
        let window = app.windows["Sony Remote"]
        XCTAssertTrue(window.waitForExistence(timeout: 10))
        if app.buttons["Done"].exists { app.buttons["Done"].click() }
        for label in ["Connection settings", "Power", "Back", "Home", "Playback", "Mute", "Volume up", "Volume down"] {
            XCTAssertTrue(window.buttons[label].exists, "Missing \(label)")
        }
        window.buttons["Playback"].click()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Pause"].exists)
        app.typeKey(.escape, modifierFlags: [])
        window.buttons["Connection settings"].click()
        let address = app.textFields["tv-ip"]
        XCTAssertTrue(address.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Connect"].exists)
        XCTAssertFalse(app.textFields["tv-pin"].exists)
        app.buttons["Done"].click()
        XCTAssertTrue(window.buttons["Home"].exists)
        window.buttons[XCUIIdentifierCloseWindow].click()
        XCTAssertFalse(window.exists)
        app.typeKey("0", modifierFlags: .command)
        XCTAssertTrue(window.waitForExistence(timeout: 3))
        XCTAssertTrue(window.buttons["Home"].exists)
        app.terminate()
    }
}
