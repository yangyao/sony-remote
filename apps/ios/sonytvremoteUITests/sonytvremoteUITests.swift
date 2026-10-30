import XCTest

final class RemoteUITests: XCTestCase {
    @MainActor
    func testRemoteAndConnectionFlow() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tv_ip", "", "-tv_name", "Sony BRAVIA", "-AppleLanguages", "(zh-Hant)"]
        app.launch()
        XCTAssertTrue(app.buttons["電視連線設定"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["提高電視音量"].exists)
        XCTAssertTrue(app.buttons["降低電視音量"].exists)
        XCTAssertTrue(app.buttons["確認"].exists)
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        capture("iphone-remote", app)

        app.buttons["提高電視音量"].tap()
        XCTAssertTrue(app.staticTexts["請點上方電視名稱，設定電視 IP 與連線金鑰。"].waitForExistence(timeout: 5))
        app.buttons["關閉提示"].tap()

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

    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
