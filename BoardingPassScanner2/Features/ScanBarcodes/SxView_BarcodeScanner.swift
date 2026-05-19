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
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                let barcodeText: String = stringValue
                let barcodeType: String = readableObject.type.rawValue
                
                print("Barcode Text: \(barcodeText)")
                print("Barcode Type: \(barcodeType)")
                
                SxMagicVariables.shared.setValue(barcodeText, forKey: self.key + ".text")
                SxMagicVariables.shared.setValue(remapBarCodeType(barcodeType), forKey: self.key + ".type")

                // Draw rectangle over detected bar code
                DispatchQueue.main.async {
                    // Remove any existing layers.
                    self.previewLayer.sublayers?.filter({ $0 is CAShapeLayer }).forEach({ $0.removeFromSuperlayer() })

                    // Create a new layer for the bounding box.
                    let shapeLayer = CAShapeLayer()
                    shapeLayer.strokeColor = self.rectColor.cgColor
                    shapeLayer.fillColor = UIColor.clear.cgColor
                    shapeLayer.lineWidth = self.rectWidth

                    // Convert the bounding box to the preview layer's coordinate system.
                    let transformedMetadataObject = self.previewLayer.transformedMetadataObject(for: metadataObject)
                    shapeLayer.path = UIBezierPath(rect: transformedMetadataObject!.bounds).cgPath

                    // Add the bounding box to the preview layer.
                    self.previewLayer.addSublayer(shapeLayer)
                }
                
                captureSession?.stopRunning()
                
                //SxEventManager.shared.fireEvent(eventType: SxEventManager.EventType.onBarcodeDetected.rawValue)
                
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    PluginActions.shared.runAction("dismissSheet:item:sheetItem")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        EventAddNewBarcode.fireNewBarcodeEvent(barcodeText: barcodeText, barcodeType: barcodeType)
                    }
                }
            }
        }
    }
}

struct SxView_BarcodeScanner: SxViewProtocol {
    @DynamicNode var node: MagicNode
    
    var body: some View {
        if let key = node.getAttribute("key") {
            BarcodeScannerView(key: key, rectColor: node.getAttribute("rectColor") ?? "red", rectWidth: node.getAttribute("rectWidth")?.convertToDouble() ?? 2.0)
                .onAppear() {
                    SxMagicVariables.shared.setValue("", forKey: key + ".text")
                    SxMagicVariables.shared.setValue("", forKey: key + ".type")
                }
        } else {
            Text("Please provide key for barcode scanner")
                .foregroundStyle(.red)
                .padding()
        }
    }
}
#endif
