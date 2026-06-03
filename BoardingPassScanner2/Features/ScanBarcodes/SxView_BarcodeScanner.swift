//
//  SxView_BarcodeScanner.swift
//  MagicUiFramework
//
//  Created by Peter Popovec on 26/03/2024.
//

import SwiftUI
import AVFoundation
import MagicUiFramework

#if os(iOS)
struct BarcodeScannerView: UIViewControllerRepresentable {
    let key: String
    let rectColor: String
    let rectWidth: Double
    let batch: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return viewController }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return viewController
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return viewController
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .code128, .aztec, .codabar]
        } else {
            return viewController
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer
        context.coordinator.key = key
        context.coordinator.rectColor = UIColor(Color(hex: rectColor))
        context.coordinator.rectWidth = rectWidth
        context.coordinator.captureSession = captureSession
        context.coordinator.batchMode = batch

        DispatchQueue.global(qos: .userInitiated).async {
            // this must be called from background thread to prevent blocking of UI
            captureSession.startRunning()
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the controller if needed.
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var previewLayer: AVCaptureVideoPreviewLayer!
        var key: String = ""
        var rectColor = UIColor.red
        var rectWidth = 2.0
        var captureSession: AVCaptureSession?

        // Batch scanning: keep the camera running and add every detected pass
        // until the user dismisses the sheet.
        var batchMode = false
        private var isCoolingDown = false
        private var lastHandledText: String?
        private var addedCount = 0

        private func remapBarCodeType(_ type: String) -> String {
            switch type {
            case "org.iso.QRCode": return "qr"
            case "org.iso.Aztec": return "aztec"
            case "org.iso.PDF417": return "pdf417"
            case "org.iso.Code128": return "code128"
            case "org.gs1.EAN-8": return "ean8"
            case "org.gs1.EAN-13": return "ean13"
            default:
                return "qr"
            }
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first,
                  let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else { return }

            let barcodeText: String = stringValue
            let barcodeType: String = readableObject.type.rawValue

            print("Barcode Text: \(barcodeText)")
            print("Barcode Type: \(barcodeType)")

            if batchMode {
                handleBatchDetection(metadataObject, barcodeText: barcodeText, barcodeType: barcodeType)
                return
            }

            SxMagicVariables.shared.setValue(barcodeText, forKey: self.key + ".text")
            SxMagicVariables.shared.setValue(remapBarCodeType(barcodeType), forKey: self.key + ".type")

            drawBoundingBox(for: metadataObject)

            captureSession?.stopRunning()

            //SxEventManager.shared.fireEvent(eventType: SxEventManager.EventType.onBarcodeDetected.rawValue)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                PluginActions.shared.runAction("dismissSheet:item:sheetItem")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    EventAddNewBarcode.fireNewBarcodeEvent(barcodeText: barcodeText, barcodeType: barcodeType)
                }
            }
        }

        /// Adds the detected pass and keeps the camera running so the user can scan
        /// the next pass. The same code is ignored while the rectangle is shown and
        /// until a different barcode appears, so a pass left in frame isn't re-added.
        /// Feedback is shown inside the sheet (the global banner is hidden behind it).
        private func handleBatchDetection(_ metadataObject: AVMetadataObject, barcodeText: String, barcodeType: String) {
            guard !isCoolingDown, barcodeText != lastHandledText else { return }

            lastHandledText = barcodeText
            isCoolingDown = true

            drawBoundingBox(for: metadataObject)

            let type = remapBarCodeType(barcodeType)
            Task { @MainActor in
                switch BoardingPassAdder.add(text: barcodeText, type: type) {
                case .added:
                    self.addedCount += 1
                    SxMagicVariables.shared.setValue("✓ \(self.addedCount) added", forKey: "batchScanCountLabel")
                    SxMagicVariables.shared.setValue("", forKey: "batchScanMessage")
                    PluginActions.shared.runAction("playSystemSound:4095")
                case .duplicate:
                    SxMagicVariables.shared.setValue("Already in your passes", forKey: "batchScanMessage")
                case .invalid:
                    SxMagicVariables.shared.setValue("Not a boarding pass", forKey: "batchScanMessage")
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.clearBoundingBoxes()
                self?.isCoolingDown = false
            }
        }

        private func drawBoundingBox(for metadataObject: AVMetadataObject) {
            DispatchQueue.main.async {
                self.clearBoundingBoxes()

                guard let transformed = self.previewLayer.transformedMetadataObject(for: metadataObject) else { return }

                let shapeLayer = CAShapeLayer()
                shapeLayer.strokeColor = self.rectColor.cgColor
                shapeLayer.fillColor = UIColor.clear.cgColor
                shapeLayer.lineWidth = self.rectWidth
                shapeLayer.path = UIBezierPath(rect: transformed.bounds).cgPath

                self.previewLayer.addSublayer(shapeLayer)
            }
        }

        private func clearBoundingBoxes() {
            previewLayer.sublayers?.filter { $0 is CAShapeLayer }.forEach { $0.removeFromSuperlayer() }
        }
    }
}

struct SxView_BarcodeScanner: SxViewProtocol {
    @DynamicNode var node: MagicNode

    var body: some View {
        if let key = node.getAttribute("key") {
            BarcodeScannerView(key: key, rectColor: node.getAttribute("rectColor") ?? "red", rectWidth: node.getAttribute("rectWidth")?.convertToDouble() ?? 2.0, batch: node.getAttribute("batch") == "true")
                .onAppear() {
                    SxMagicVariables.shared.setValue("", forKey: key + ".text")
                    SxMagicVariables.shared.setValue("", forKey: key + ".type")
                    SxMagicVariables.shared.setValue("", forKey: "batchScanCountLabel")
                    SxMagicVariables.shared.setValue("", forKey: "batchScanMessage")
                }
        } else {
            Text("Please provide key for barcode scanner")
                .foregroundStyle(.red)
                .padding()
        }
    }
}
#endif
