//
//  DetectFromClipboard.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 16/05/2026.
//

import MagicUiFramework
import SwiftUI

struct DetectFromClipboard {
    func detectBarcode(handler: @escaping ((String, String)?, Error?) -> Void) {
        detectBarcode(in: .general, handler: handler)
    }

    func detectBarcode(in pasteboard: UIPasteboard, handler: @escaping ((String, String)?, Error?) -> Void) {
        if let text = pasteboard.string, let barcodeText = validBoardingPassText(from: text) {
            handler((barcodeText, "text"), nil)
            return
        }

        if let image = pasteboard.image {
            DetectFromImage().detectBarcode(in: image) { result, error in
                guard let (barcodeText, barcodeType) = result else {
                    handler(nil, error ?? BarcodeError.barcodeNotFound)
                    return
                }

                guard self.isValidBoardingPass(barcodeText) else {
                    handler(nil, BarcodeError.barcodeNotFound)
                    return
                }

                handler((barcodeText, barcodeType), nil)
            }
            return
        }

        handler(nil, BarcodeError.barcodeNotFound)
    }

    private func validBoardingPassText(from text: String) -> String? {
        let barcodeText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return isValidBoardingPass(barcodeText) ? barcodeText : nil
    }

    private func isValidBoardingPass(_ text: String) -> Bool {
        (try? BoardingPass(parsing: text)) != nil
    }
}

struct Action_detectFromClipboard: SxActionProtocol {
    let node: MagicNode?

    func execute(_ actionString: String) {
        DetectFromClipboard().detectBarcode { result, _ in
            guard let (barcodeText, barcodeType) = result else {
                PluginActions.shared.runAction("presentAlert:myAlertCannotDetectBarcode")
                return
            }

            EventAddNewBarcode.fireNewBarcodeEvent(barcodeText: barcodeText, barcodeType: barcodeType)
        }
    }
}
