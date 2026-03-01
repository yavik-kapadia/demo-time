//
//  CameraPreviewTests.swift
//  Demo TimeTests
//

import XCTest
import AVFoundation
import AppKit
import SwiftUI
@testable import Demo_Time

final class CameraPreviewTests: XCTestCase {

    var session: AVCaptureSession!

    override func setUp() async throws {
        try await super.setUp()
        session = AVCaptureSession()
    }

    override func tearDown() async throws {
        session = nil
        try await super.tearDown()
    }

    func testCameraPreviewCreatesView() {
        let preview = CameraPreview(
            session: session,
            rotationDegrees: 0,
            cropTop: 0,
            cropBottom: 0,
            cropLeft: 0,
            cropRight: 0
        )
        let hosting = NSHostingView(rootView: preview)
        hosting.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
        hosting.layout()
        XCTAssertEqual(hosting.subviews.count, 1)
    }

    func testCameraPreviewNSViewHasPreviewLayer() {
        let view = CameraPreviewNSView(frame: NSRect(x: 0, y: 0, width: 320, height: 240))
        view.layout()
        XCTAssertNotNil(view.previewLayer as? AVCaptureVideoPreviewLayer)
        XCTAssertEqual(view.previewLayer.session, nil)
    }

    func testUpdateRotationDoesNotCrash() {
        let view = CameraPreviewNSView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        view.layout()
        view.updateRotation(0)
        view.updateRotation(90)
        view.updateRotation(180)
        view.updateRotation(270)
    }

    func testUpdateCropDoesNotCrash() {
        let view = CameraPreviewNSView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        view.layout()
        view.updateCrop(top: 0, bottom: 0, left: 0, right: 0)
        view.updateCrop(top: 10, bottom: 10, left: 5, right: 5)
    }

    func testUpdateCropWithZeroBoundsDoesNotCrash() {
        let view = CameraPreviewNSView(frame: .zero)
        view.updateCrop(top: 0, bottom: 0, left: 0, right: 0)
    }
}
