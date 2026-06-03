//
//  NewActions.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 15/05/2025.
//

import Foundation
import MagicUiFramework
import SwiftUI


struct Action_addNewBoardingPass: SxActionProtocol {
    let node: MagicNode?

    func barcodeType(_ str: String) -> String {
        let type = actionParts(str).first?
            .replacingOccurrences(of: "type:", with: "") ?? ""
        if type == "org.iso.PDF417" { return "pdf417" }
        if type == "org.iso.Aztec" { return "aztec" }
        if type == "org.iso.QRCode" { return "qr" }
        return type
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

    private func bannerMessage(for record: BoardingPassRecord) -> String {
        var parts: [String] = []

        let flight = [record.operatingCarrier, record.flightNumber]
            .filter { !$0.isEmpty }.joined(separator: " ")
        if !flight.isEmpty { parts.append(flight) }

        let route = [record.fromAirport, record.toAirport]
            .filter { !$0.isEmpty }.joined(separator: " → ")
        if !route.isEmpty { parts.append(route) }

        let date = record.flightDate.formatted(.dateTime.day().month(.abbreviated))
        parts.append(date)

        return parts.joined(separator: " · ")
    }

    @MainActor
    private func addBoardingPass(text: String, type: String) async {
        switch BoardingPassAdder.add(text: text, type: type) {
        case .duplicate:
            PluginActions.shared.runAction("presentAlert:myAlertBoardingPassAlreadyExists")
        case .invalid:
            PluginActions.shared.runAction("presentAlert:myAlertInvalidBoardingPassCode")
        case .added(let record):
            let title = record.name.isEmpty ? "Boarding pass added" : record.name
            let message = bannerMessage(for: record)
            BannerPresenter.shared.show(style: .success, title: title, message: message)
        }
    }
}
