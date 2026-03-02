//
//  CameraPreview.swift
//  Demo Time
//
//  Created by Yavik on 3/1/26.
//

import AVFoundation
import AppKit
import SwiftUI

struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession
    var rotationDegrees: Double
    var cropTop: Double
    var cropBottom: Double
    var cropLeft: Double
    var cropRight: Double

    func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView()
        view.session = session
        return view
    }

    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.session = session
        nsView.rotationDegrees = rotationDegrees
        nsView.cropValues = (cropTop, cropBottom, cropLeft, cropRight)
        nsView.applySettings()
    }
}

final class CameraPreviewNSView: NSView {
    private let previewLayer = AVCaptureVideoPreviewLayer()
    var session: AVCaptureSession? {
        didSet { previewLayer.session = session }
    }
    var rotationDegrees: Double = 0
    var cropValues: (top: Double, bottom: Double, left: Double, right: Double) = (0, 0, 0, 0)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        previewLayer.backgroundColor = .clear
        layer?.addSublayer(previewLayer)
        previewLayer.videoGravity = .resizeAspect
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
    }

    override func layout() {
        super.layout()
        applySettings()
    }

    func applySettings() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        applyRotation()
        applyCrop()

        CATransaction.commit()
    }

    private func applyRotation() {
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        if let connection = previewLayer.connection,
           connection.isVideoRotationAngleSupported(CGFloat(rotationDegrees)) {
            connection.videoRotationAngle = CGFloat(rotationDegrees)
            previewLayer.frame = bounds
        } else {
            previewLayer.frame = bounds
            previewLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            previewLayer.position = CGPoint(x: w / 2, y: h / 2)

            let radians = CGFloat(rotationDegrees * .pi / 180)
            var transform = CATransform3DIdentity
            transform = CATransform3DRotate(transform, radians, 0, 0, 1)

            if rotationDegrees == 90 || rotationDegrees == 270 {
                let scale = max(w, h) / min(w, h)
                transform = CATransform3DScale(transform, scale, scale, 1)
            }

            previewLayer.transform = transform
        }
    }

    private func applyCrop() {
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        let (top, bottom, left, right) = cropValues
        if top == 0, bottom == 0, left == 0, right == 0 {
            previewLayer.mask = nil
            return
        }

        let leftInset = w * CGFloat(left / 100)
        let rightInset = w * CGFloat(right / 100)
        let topInset = h * CGFloat(top / 100)
        let bottomInset = h * CGFloat(bottom / 100)

        let cropRect = CGRect(
            x: leftInset,
            y: bottomInset,
            width: max(0, w - leftInset - rightInset),
            height: max(0, h - topInset - bottomInset)
        )

        let maskLayer = CAShapeLayer()
        maskLayer.path = CGPath(rect: cropRect, transform: nil)
        maskLayer.frame = CGRect(origin: .zero, size: bounds.size)
        previewLayer.mask = maskLayer
    }
}
