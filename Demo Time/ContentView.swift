//
//  ContentView.swift
//  Demo Time
//
//  Created by Yavik on 3/1/26.
//

import SwiftUI
import AVFoundation
import AppKit

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var rotationDegrees: Double = 0
    @State private var cropTop: Double = 0
    @State private var cropBottom: Double = 0
    @State private var cropLeft: Double = 0
    @State private var cropRight: Double = 0
    @State private var isHovering = false
    @State private var showCropSliders = false
    @State private var isFullScreen = false

    var body: some View {
        ZStack(alignment: .bottom) {
            switch cameraManager.authStatus {
            case .notDetermined:
                permissionRequestView
            case .denied, .restricted:
                permissionDeniedView
            case .authorized:
                cameraView
            }
        }
        .onAppear {
            if cameraManager.authStatus == .authorized {
                cameraManager.configureSession()
                cameraManager.startSession()
            }
            observeFullscreen()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            cameraManager.checkAuthorizationStatus()
            if cameraManager.authStatus == .authorized {
                cameraManager.configureSession()
                cameraManager.startSession()
            }
        }
    }

    private var permissionRequestView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Camera Access Required")
                .font(.title2.weight(.medium))
            Text("Demo Time needs access to your camera or capture card to display video.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button("Allow Camera Access") {
                cameraManager.requestAccess()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Camera Access Denied")
                .font(.title2.weight(.medium))
            Text("Open System Settings to grant camera access to Demo Time.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var cameraView: some View {
        ZStack(alignment: .bottom) {
            CameraPreview(
                session: cameraManager.session,
                rotationDegrees: rotationDegrees,
                cropTop: cropTop,
                cropBottom: cropBottom,
                cropLeft: cropLeft,
                cropRight: cropRight
            )
            .ignoresSafeArea()

            if let message = cameraManager.errorMessage {
                VStack(spacing: 12) {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .frame(maxWidth: 400)
                        .background(.black.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack(spacing: 12) {
                        Button("Retry") {
                            cameraManager.discoverDevices()
                            cameraManager.configureSession()
                            cameraManager.startSession()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Open System Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                }
                .padding(.top, 40)
            }

            if isHovering {
                controlsOverlay
            }
        }
        .onHover { isHovering = $0 }
    }

    private var controlsOverlay: some View {
        VStack(spacing: 0) {
            if showCropSliders {
                cropSliders
            }

            HStack(spacing: 16) {
                cameraPicker
                rotationControls
                cropToggle
                fullscreenButton
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    private var cameraPicker: some View {
        Picker("Camera", selection: Binding(
            get: { cameraManager.selectedDevice },
            set: { cameraManager.setSelectedDevice($0) }
        )) {
            Text("No camera").tag(nil as AVCaptureDevice?)
            ForEach(Array(cameraManager.availableDevices.enumerated()), id: \.offset) { _, device in
                Text(device.localizedName).tag(Optional(device))
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: 200)
        .labelsHidden()
    }

    private var rotationControls: some View {
        HStack(spacing: 4) {
            ForEach([0.0, 90.0, 180.0, 270.0], id: \.self) { degrees in
                Button {
                    rotationDegrees = degrees
                } label: {
                    Text("\(Int(degrees))°")
                        .font(.system(.caption, design: .monospaced))
                        .frame(width: 32, height: 24)
                        .background(rotationDegrees == degrees ? Color.accentColor : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var cropToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCropSliders.toggle()
            }
        } label: {
            Image(systemName: "crop")
        }
        .buttonStyle(.plain)
        .help("Crop")
    }

    private var cropSliders: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                cropSlider(label: "L", value: $cropLeft)
                cropSlider(label: "R", value: $cropRight)
            }
            HStack(spacing: 12) {
                cropSlider(label: "T", value: $cropTop)
                cropSlider(label: "B", value: $cropBottom)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func cropSlider(label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .frame(width: 12, alignment: .leading)
            Slider(value: value, in: 0...50, step: 1)
                .frame(maxWidth: 120)
            Text("\(Int(value.wrappedValue))%")
                .font(.system(.caption2, design: .monospaced))
                .frame(width: 28, alignment: .trailing)
        }
    }

    private var fullscreenButton: some View {
        Button {
            toggleFullscreen()
        } label: {
            Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
        }
        .buttonStyle(.plain)
        .help(isFullScreen ? "Exit fullscreen" : "Enter fullscreen")
    }

    private func observeFullscreen() {
        let center = NotificationCenter.default
        center.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: nil, queue: .main) { _ in
            isFullScreen = true
        }
        center.addObserver(forName: NSWindow.didExitFullScreenNotification, object: nil, queue: .main) { _ in
            isFullScreen = false
        }
    }

    private func toggleFullscreen() {
        guard let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        window.toggleFullScreen(nil)
    }
}

#Preview {
    ContentView()
        .frame(width: 640, height: 480)
}
