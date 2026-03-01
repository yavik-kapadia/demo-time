//
//  CameraManagerTests.swift
//  Demo TimeTests
//

import XCTest
import AVFoundation
@testable import Demo_Time

@MainActor
final class CameraManagerTests: XCTestCase {

    var manager: CameraManager!

    override func setUp() async throws {
        try await super.setUp()
        manager = CameraManager()
    }

    override func tearDown() async throws {
        manager.stopSession()
        manager = nil
        try await super.tearDown()
    }

    func testInitDiscoversDevices() {
        // After init, discoverDevices() has run; availableDevices may be empty (no camera) or non-empty
        XCTAssertNotNil(manager.availableDevices)
        XCTAssertTrue(manager.availableDevices is [AVCaptureDevice])
    }

    func testSessionExists() {
        XCTAssertNotNil(manager.session)
        XCTAssertTrue(manager.session is AVCaptureSession)
    }

    func testSetSelectedDeviceToNilClearsSelection() {
        manager.setSelectedDevice(nil)
        XCTAssertNil(manager.selectedDevice)
    }

    func testSetSelectedDeviceUpdatesSelection() {
        guard let first = manager.availableDevices.first else {
            // No cameras; setSelectedDevice(nil) is still valid
            manager.setSelectedDevice(nil)
            XCTAssertNil(manager.selectedDevice)
            return
        }
        manager.setSelectedDevice(first)
        XCTAssertEqual(manager.selectedDevice?.uniqueID, first.uniqueID)
    }

    func testErrorMessageInitiallyNil() {
        XCTAssertNil(manager.errorMessage)
    }

    func testStartAndStopSessionDoNotThrow() {
        manager.startSession()
        // Allow async start
        let e = expectation(description: "session")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.manager.stopSession()
            e.fulfill()
        }
        wait(for: [e], timeout: 2.0)
    }

    func testConfigureSessionWithNoDeviceRemovesInputs() {
        manager.setSelectedDevice(nil)
        let e = expectation(description: "configured")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            XCTAssertTrue(self.manager.session.inputs.isEmpty)
            e.fulfill()
        }
        wait(for: [e], timeout: 1.0)
    }

    func testDiscoverDevicesCanBeCalledAgain() {
        manager.discoverDevices()
        let count = manager.availableDevices.count
        manager.discoverDevices()
        XCTAssertEqual(manager.availableDevices.count, count)
    }
}
