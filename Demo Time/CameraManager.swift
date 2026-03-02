//
//  CameraManager.swift
//  Demo Time
//
//  Created by Yavik on 3/1/26.
//

import AVFoundation
import Combine
import SwiftUI

enum CameraAuthStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
}

@MainActor
final class CameraManager: ObservableObject {
    @Published var availableDevices: [AVCaptureDevice] = []
    @Published var selectedDevice: AVCaptureDevice?
    @Published var session = AVCaptureSession()
    @Published var errorMessage: String?
    @Published var authStatus: CameraAuthStatus = .notDetermined

    private let sessionQueue = DispatchQueue(label: "com.yavik.Demo-Time.capture-session")

    init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authStatus = .authorized
            discoverDevices()
        case .notDetermined:
            authStatus = .notDetermined
        case .denied:
            authStatus = .denied
        case .restricted:
            authStatus = .restricted
        @unknown default:
            authStatus = .denied
        }
    }

    func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                if granted {
                    self.authStatus = .authorized
                    self.discoverDevices()
                    self.configureSession()
                    self.startSession()
                } else {
                    self.authStatus = .denied
                }
            }
        }
    }

    func discoverDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )
        availableDevices = discoverySession.devices
        if selectedDevice == nil, let first = availableDevices.first {
            selectedDevice = first
        }
    }

    func setSelectedDevice(_ device: AVCaptureDevice?) {
        selectedDevice = device
        configureSession()
    }

    func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }

            guard let device = self.selectedDevice else {
                self.session.commitConfiguration()
                Task { @MainActor in self.errorMessage = nil }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    Task { @MainActor in self.errorMessage = nil }
                } else {
                    Task { @MainActor in
                        self.errorMessage = "Cannot use \(device.localizedName). It may be in use by another app. Close other apps using the camera and try again."
                    }
                }
            } catch {
                let deviceName = device.localizedName
                let msg = "Cannot use \(deviceName). It may be in use by another app, or try a different camera."
                Task { @MainActor in self.errorMessage = msg }
            }

            self.session.commitConfiguration()
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}
