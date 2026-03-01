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
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspect
        view.previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        return view
    }

    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.previewLayer.session = session
        nsView.updateRotation(rotationDegrees)
        nsView.updateCrop(top: cropTop, bottom: cropBottom, left: cropLeft, right: cropRight)
    }
}

final class CameraPreviewNSView: NSView {
    override func makeBackingLayer() -> CALayer {
        AVCaptureVideoPreviewLayer()
    }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private var currentRotation: Double = 0
    private var cropTop: Double = 0, cropBottom: Double = 0, cropLeft: Double = 0, cropRight: Double = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func layout() {
        super.layout()
        // Keep layer centered for rotation; updateRotation sets bounds, position, and transform
        previewLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        previewLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        previewLayer.bounds = CGRect(origin: .zero, size: bounds.size)
        updateRotation(currentRotation)
        updateCrop(top: cropTop, bottom: cropBottom, left: cropLeft, right: cropRight)
    }

    func updateRotation(_ degrees: Double) {
        currentRotation = degrees
        let radians = CGFloat(degrees * .pi / 180)
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else {
            previewLayer.setAffineTransform(CGAffineTransform(rotationAngle: radians))
            return
        }
        // For 90° and 270°, scale the layer so that after rotation it still fills the view.
        // Otherwise the rotated layer extends outside the bounds and the preview looks empty.
        let scale: CGFloat
        if degrees == 90 || degrees == 270 {
            scale = max(w, h) / min(w, h)
        } else {
            scale = 1
        }
        let transform = CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(rotationAngle: radians))
        previewLayer.setAffineTransform(transform)
    }

    func updateCrop(top: Double, bottom: Double, left: Double, right: Double) {
        cropTop = top
        cropBottom = bottom
        cropLeft = left
        cropRight = right

        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

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
        let path = CGPath(rect: cropRect, transform: nil)
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.frame = bounds
        previewLayer.mask = maskLayer
    }
}
