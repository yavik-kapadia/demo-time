//
//  AppLifecycleTests.swift
//  Demo TimeTests
//

import XCTest
@testable import Demo_Time

final class AppLifecycleTests: XCTestCase {

    func testAppStructExists() {
        // Demo_TimeApp is the @main entry; we can reference the type
        let appType = Demo_TimeApp.self
        XCTAssertNotNil(appType)
    }

    func testBundleIdentifier() {
        // When running unit tests, main bundle is the test bundle
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        XCTAssertTrue(bundleId.contains("Demo") || bundleId.contains("demo") || bundleId.contains("Tests"))
    }
}
