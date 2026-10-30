import XCTest

final class RemoteUITests: XCTestCase {
    @MainActor
    func testRemoteAndConnectionFlow() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tv_ip", "192.0.2.1", "-tv_name", "Sony BRAVIA", "-AppleLanguages", "(zh-Hant)"]
        app.launch()
        XCTAssertTrue(app.buttons["電視連線設定"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["提高電視音量"].exists)
        XCTAssertTrue(app.buttons["降低電視音量"].exists)
        XCTAssertTrue(app.buttons["確認"].exists)
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        capture("iphone-remote", app)

        app.buttons["電視連線設定"].tap()
        XCTAssertTrue(app.textFields["tv-ip"].waitForExistence(timeout: 5))
        capture("iphone-settings", app)
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons["確認"].waitForExistence(timeout: 5))

        app.buttons["播放控制"].tap()
        XCTAssertTrue(app.buttons["暫停"].waitForExistence(timeout: 5))
        capture("iphone-playback", app)
        app.buttons["暫停"].tap()
        if app.buttons["關閉提示"].waitForExistence(timeout: 3) { app.buttons["關閉提示"].tap() }

        app.buttons["更多"].tap()
        XCTAssertTrue(app.staticTexts["更多控制"].waitForExistence(timeout: 5))
        // Lazy rows are only materialized once scrolled into view.
        app.swipeUp()
        // Regression: the original number pad omitted the 1 key.
        XCTAssertTrue(app.buttons["1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["9"].exists)
        capture("iphone-more", app)
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons["確認"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSimplifiedSettings() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-tv_ip", "192.0.2.1", "-AppleLanguages", "(zh-Hant)"]
        app.launch()
        XCTAssertTrue(app.buttons["電視連線設定"].waitForExistence(timeout: 15))
        app.buttons["電視連線設定"].tap()
        let address = app.textFields["tv-ip"]
        XCTAssertTrue(address.waitForExistence(timeout: 5))
        XCTAssertEqual(address.value as? String, "192.0.2.1")
        XCTAssertTrue(app.buttons["連接"].exists)
        XCTAssertTrue(app.buttons["連接"].isEnabled)
        XCTAssertFalse(app.staticTexts["如何連接"].exists)
        XCTAssertFalse(app.buttons["測試首頁按鍵"].exists)
        XCTAssertFalse(app.buttons["測試連線"].exists)
        XCTAssertFalse(app.secureTextFields["tv-psk"].exists)
        capture("iphone-settings", app)
        app.buttons["完成"].tap()
        XCTAssertTrue(app.buttons["確認"].waitForExistence(timeout: 5))
    }

    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
