//
//  DetectFromImage.swift
//  Barcoder
//
//  Created by Peter Popovec on 08/02/2025.
//

import SwiftUI
import Vision

enum BarcodeError: Error {
    case invalidImage
    case detectionFailed
    case barcodeNotFound
    case unknownError
}

struct DetectFromImage {
    func detectBarcode(in image: UIImage, handler: @escaping ((String, String)?, Error?) -> Void) {
        guard let cgImage = image.cgImage else {
            print("Invalid image")
            handler(nil , BarcodeError.invalidImage)
            return
        }

        let request = VNDetectBarcodesRequest { request, error in
            if let error = error {
                print("Barcode detection error: \(error)")
                handler(nil, error)
                return
            }

            guard let results = request.results as? [VNBarcodeObservation] else {
                print("No barcodes found")
                handler(nil, BarcodeError.barcodeNotFound)
                return
            }

            for barcode in results {
                if let payload = barcode.payloadStringValue {
                    let type = readableSymbology(barcode.symbology)
                    print("Detected barcode: \(payload), Type: \(type)")
                    handler((payload, type), nil)
                    return
                }
            }

            handler(nil, BarcodeError.barcodeNotFound)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform barcode detection: \(error)")
        }
    }
    
    func readableSymbology(_ symbology: VNBarcodeSymbology) -> String {
        switch symbology {
        case .qr:
            return "qr"
        case .aztec:
            return "aztec"
        case .code128:
            return "code128"
        case .pdf417:
            return "pdf417"
        case .ean8:
            return "ean8"
        case .ean13:
            return "ean13"
        default:
            return symbology.rawValue
        }
    }
}
