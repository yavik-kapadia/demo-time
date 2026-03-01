//
//  CameraManager.swift
//  Demo Time
//
//  Created by Yavik on 3/1/26.
//

import AVFoundation
import Combine
import SwiftUI

@MainActor
final class CameraManager: ObservableObject {
    @Published var availableDevices: [AVCaptureDevice] = []
    @Published var selectedDevice: AVCaptureDevice?
    @Published var session = AVCaptureSession()
    @Published var errorMessage: String?

    private let sessionQueue = DispatchQueue(label: "com.yavik.Demo-Time.capture-session")

    init() {
        discoverDevices()
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
                    Task { @MainActor in self.errorMessage = "Cannot add this camera." }
                }
            } catch {
                Task { @MainActor in self.errorMessage = error.localizedDescription }
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
