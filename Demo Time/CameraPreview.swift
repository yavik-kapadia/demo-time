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
    let previewLayer = AVCaptureVideoPreviewLayer()
    var session: AVCaptureSession? {
        didSet { previewLayer.session = session }
    }
    var rotationDegrees: Double = 0
    var cropValues: (top: Double, bottom: Double, left: Double, right: Double) = (0, 0, 0, 0)
    private var rotationTransform = CATransform3DIdentity

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
        layer?.masksToBounds = true
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

    func updateRotation(_ degrees: Double) {
        rotationDegrees = degrees
        applySettings()
    }

    func updateCrop(top: Double, bottom: Double, left: Double, right: Double) {
        cropValues = (top, bottom, left, right)
        applySettings()
    }

    private func applyRotation() {
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        // Reset the transform before touching `frame` — setting `frame` while a
        // non-identity transform is live yields undefined bounds. The final
        // transform (rotation composed with crop-zoom) is set in applyCrop().
        previewLayer.transform = CATransform3DIdentity
        previewLayer.frame = bounds
        previewLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        previewLayer.position = CGPoint(x: w / 2, y: h / 2)

        if let connection = previewLayer.connection,
           connection.isVideoRotationAngleSupported(CGFloat(rotationDegrees)) {
            // Preferred path: rotate the video at the connection (higher quality),
            // leaving the layer transform free for the crop-zoom.
            connection.videoRotationAngle = CGFloat(rotationDegrees)
            rotationTransform = CATransform3DIdentity
        } else {
            // Fallback: rotate via a layer transform when the connection can't.
            let radians = CGFloat(rotationDegrees * .pi / 180)
            var transform = CATransform3DRotate(CATransform3DIdentity, radians, 0, 0, 1)
            if rotationDegrees == 90 || rotationDegrees == 270 {
                let scale = max(w, h) / min(w, h)
                transform = CATransform3DScale(transform, scale, scale, 1)
            }
            rotationTransform = transform
        }
    }

    private func applyCrop() {
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        // Crop-to-fill (digital zoom): scale the kept region up to fill the view,
        // centered. Clipping of the overflow is handled by host layer.masksToBounds.
        previewLayer.mask = nil

        let (top, bottom, left, right) = cropValues
        let cropTransform: CATransform3D

        if top == 0, bottom == 0, left == 0, right == 0 {
            cropTransform = CATransform3DIdentity
        } else {
            let leftInset = w * CGFloat(left / 100)
            let rightInset = w * CGFloat(right / 100)
            let topInset = h * CGFloat(top / 100)
            let bottomInset = h * CGFloat(bottom / 100)

            // max(1, …) keeps the dimension non-zero at the 50/50 extreme.
            let cropW = max(1, w - leftInset - rightInset)
            let cropH = max(1, h - topInset - bottomInset)

            // y-up backing layer (no isFlipped) → bottom-origin for the vertical inset.
            let cropCenterX = leftInset + cropW / 2
            let cropCenterY = bottomInset + cropH / 2

            // Aspect-fit the kept region into the full view, then re-center it.
            // (Switch the outer `min` to `max` for edge-to-edge fill that clips overshoot.)
            let scale = min(max(min(w / cropW, h / cropH), 1), 8)

            var transform = CATransform3DMakeScale(scale, scale, 1)
            transform.m41 = -scale * (cropCenterX - w / 2)
            transform.m42 = -scale * (cropCenterY - h / 2)
            cropTransform = transform
        }

        // Apply rotation first, then the crop-zoom in the (rotated) view space.
        previewLayer.transform = CATransform3DConcat(rotationTransform, cropTransform)
    }
}
