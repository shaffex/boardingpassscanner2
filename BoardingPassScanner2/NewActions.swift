//
//  NewActions.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 15/05/2025.
//

import Foundation
import MagicUiFramework


struct Action_addNewBoardingPass: SxActionProtocol {
    let node: MagicNode?

    func barcodeType(_ str: String) -> String {
        let type = actionParts(str).first?
            .replacingOccurrences(of: "type:", with: "") ?? ""
        switch type {
        case "org.iso.PDF417": return "pdf417"
        case "org.iso.Aztec": return "aztec"
        default: return "qr"
        }
    }

    func barcodeText(_ str: String) -> String {
        guard actionParts(str).count > 1 else {
            return str
        }

        return actionParts(str)[1]
            .replacingOccurrences(of: "text:", with: "")
    }

    private func actionParts(_ str: String) -> [String] {
        str.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
            .map(String.init)
    }

    func execute(_ actionString: String) {
        let text = barcodeText(actionString)
        let type = barcodeType(actionString)

        Task { @MainActor in
            await addBoardingPass(text: text, type: type)
        }
    }

    @MainActor
    private func addBoardingPass(text: String, type: String) async {
        let store = BoardingPassStore.shared

        if store.contains(text: text) {
            PluginActions.shared.runAction("presentAlert:myAlertBoardingPassAlreadyExists")
            return
        }

        guard (try? BoardingPass(parsing: text)) != nil else {
            PluginActions.shared.runAction("presentAlert:myAlertInvalidBoardingPassCode")
            return
        }

        if store.insertIfMissing(barcodeText: text, barcodeType: type) != nil {
            PluginActions.shared.runAction("showBanner:type:success;text:Boarding pass added successfully.")
        }
    }
}
