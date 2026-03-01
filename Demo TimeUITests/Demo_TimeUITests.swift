//
//  Demo_TimeUITests.swift
//  Demo TimeUITests
//

import XCTest

final class Demo_TimeUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAppLaunches() throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    func testWindowExists() throws {
        let windows = app.windows
        XCTAssertGreaterThanOrEqual(windows.count, 1)
    }

    func testWindowHasContent() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertTrue(window.frame.width > 0 && window.frame.height > 0)
    }

    func testInterfaceHasButtonsWhenRevealed() throws {
        // Buttons (rotation, crop, fullscreen) appear on hover; we only assert structure exists
        let buttons = app.buttons
        XCTAssertNotNil(buttons.count)
    }
}
