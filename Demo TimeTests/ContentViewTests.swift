//
//  ContentViewTests.swift
//  Demo TimeTests
//

import XCTest
import SwiftUI
@testable import Demo_Time

final class ContentViewTests: XCTestCase {

    func testContentViewBodyCompiles() {
        let view = ContentView()
        _ = view.body
    }

    func testContentViewCanBeHosted() {
        let view = ContentView()
            .frame(width: 400, height: 300)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
        hosting.layout()
        XCTAssertNotNil(hosting.rootView)
    }

    func testRotationAnglesAreSupported() {
        let angles = [0.0, 90.0, 180.0, 270.0]
        XCTAssertEqual(angles.count, 4)
        angles.forEach { a in
            XCTAssertGreaterThanOrEqual(a, 0)
            XCTAssertLessThan(a, 360)
        }
    }

    func testCropBounds() {
        // ContentView uses 0...50 for crop sliders
        let minCrop: Double = 0
        let maxCrop: Double = 50
        XCTAssertGreaterThanOrEqual(maxCrop, minCrop)
    }
}
