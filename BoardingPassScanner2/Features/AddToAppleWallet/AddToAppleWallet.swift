//
//  AddToAppleWallet.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 08/05/2026.
//

import SwiftUI
internal import PassKit
import MagicUiFramework

struct AddToWalletButton: UIViewRepresentable {
    let addPassButtonStyle: PKAddPassButtonStyle
    var isEnabled: Bool = true
    var onTap: (() -> Void)? = nil

    func makeUIView(context: Context) -> PKAddPassButton {
        let button = PKAddPassButton(addPassButtonStyle: addPassButtonStyle)
        button.addAction(UIAction { _ in
            context.coordinator.onTap?()
        }, for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKAddPassButton, context: Context) {
        uiView.isEnabled = isEnabled
        context.coordinator.onTap = onTap
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    final class Coordinator {
        var onTap: (() -> Void)?
        init(onTap: (() -> Void)?) { self.onTap = onTap }
    }
}

struct ButtonAddToAppleWallet: SxViewProtocol {
    @DynamicNode var node: MagicNode
    
    var addPassButtonStyle: PKAddPassButtonStyle {
        if node.getAttribute("addPassButtonStyle") == "blackOutline" {
            return .blackOutline
        } else {
            return .black
        }
    }
    
    var body: some View {
        AddToWalletButton(addPassButtonStyle: addPassButtonStyle)

            //.frame(width: 160, height: 44)
    }
}

struct AddPassView: UIViewControllerRepresentable {

    let pass: PKPass

    func makeUIViewController(context: Context) -> PKAddPassesViewController {

        PKAddPassesViewController(pass: pass)!

    }

    func updateUIViewController(

        _ uiViewController: PKAddPassesViewController,

        context: Context

    ) { }

}

struct Action_addPass: SxActionProtocol {
    let node: MagicUiFramework.MagicNode?

    static let debugFlag = "0"
    static let walletEndpointURLString = "https://shaffex.com/api/boardingpass2/generateBoardingPass.php"
    static let customWalletEndpointURLString = "https://shaffex.com/api/boardingpass2/generateCustomBoardingPass.php"

    // Merges the calendar date from `record.flightDate` with the clock time from `departureTime`.
    // When `departureTime` is nil the record's stored time is used unchanged.
    private static func resolvedFlightDateString(
        record: BoardingPassRecord,
        departureTime: Date?
    ) -> String {
        let formatter = ISO8601DateFormatter()
        guard let override = departureTime, record.flightDate != .distantPast else {
            return formatter.string(from: record.flightDate)
        }
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: record.flightDate)
        let timeComps = calendar.dateComponents([.hour, .minute], from: override)
        comps.hour = timeComps.hour
        comps.minute = timeComps.minute
        comps.second = 0
        comps.nanosecond = 0
        return formatter.string(from: calendar.date(from: comps) ?? record.flightDate)
    }

    static func presentCustomForRecord(
        _ record: BoardingPassRecord,
        departureTime: Date? = nil,
        foregroundColor: String,
        backgroundColor: String,
        labelColor: String,
        semantics: Bool,
        logoText: String,
        fieldsJSON: String
    ) async {
        let flightDateString = resolvedFlightDateString(record: record, departureTime: departureTime)
        await Action_addPass(node: nil).presentWallet(
            barcodeText: record.text,
            barcodeType: record.type,
            flightDate: flightDateString,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            labelColor: labelColor,
            semantics: semantics,
            logoText: logoText,
            fieldsJSON: fieldsJSON,
            endpointURL: URL(string: customWalletEndpointURLString)
        )
    }

    static func presentForRecord(
        _ record: BoardingPassRecord,
        departureTime: Date? = nil,
        foregroundColor: String,
        backgroundColor: String,
        labelColor: String,
        semantics: Bool,
        logoText: String,
        fieldsJSON: String
    ) async {
        let flightDateString = resolvedFlightDateString(record: record, departureTime: departureTime)
        await Action_addPass(node: nil).presentWallet(
            barcodeText: record.text,
            barcodeType: record.type,
            flightDate: flightDateString,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            labelColor: labelColor,
            semantics: semantics,
            logoText: logoText,
            fieldsJSON: fieldsJSON
        )
    }

    static func requestDebugDescription(
        for record: BoardingPassRecord,
        departureTime: Date? = nil,
        foregroundColor: String,
        backgroundColor: String,
        labelColor: String,
        semantics: Bool,
        logoText: String,
        fieldsJSON: String
    ) -> String {
        let flightDateString = resolvedFlightDateString(record: record, departureTime: departureTime)
        let fields = requestFields(
            barcodeText: record.text,
            barcodeType: record.type,
            flightDate: flightDateString,
            debug: Self.debugFlag,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            labelColor: labelColor,
            semantics: semantics,
            logoText: logoText,
            fieldsJSON: fieldsJSON
        )
        let body = formBodyString(fields) ?? ""

        return """
        POST \(walletEndpointURLString)
        Content-Type: application/x-www-form-urlencoded

        barcodeText=\(fields["barcodeText"] ?? "")
        barcodeType=\(fields["barcodeType"] ?? "")
        flightDate=\(fields["flightDate"] ?? "")
        debug=\(fields["debug"] ?? "")
        foregroundColor=\(fields["foregroundColor"] ?? "")
        backgroundColor=\(fields["backgroundColor"] ?? "")
        labelColor=\(fields["labelColor"] ?? "")
        semantics=\(fields["semantics"] ?? "")
        logoText=\(fields["logoText"] ?? "")
        fieldsConfig=\(fields["fieldsConfig"] ?? "")

        Body:
        \(body)
        """
    }

    func execute(_ actionString: String) {
        Task {
            await presentWallet(
                barcodeText: SxMagicVariables.shared.value(forKey: "selectedCode.text") as? String ?? "",
                barcodeType: SxMagicVariables.shared.value(forKey: "selectedCode.type") as? String ?? "",
                flightDate: SxMagicVariables.shared.value(forKey: "selectedCode.flightDate") as? String ?? "",
                foregroundColor: "rgb(255,255,255)",
                backgroundColor: "rgb(26,56,115)",
                labelColor: "rgb(217,224,242)",
                semantics: false,
                logoText: "",
                fieldsJSON: "{}"
            )
        }
    }

//    func addPass() async {
//        do {
//            // URL to your .pkpass file
//            let url = URL(string: "https://shaffex.com/passkit/GeneratedPasses/2026-05-08-194441.pkpass")!
//
//            // Download pass
//            let (data, _) = try await URLSession.shared.data(from: url)
//
//            // Create PKPass
//            let pkPass = try PKPass(data: data)
//
//            // Show Wallet sheet
//            await MainActor.run {
//                //self.pass = pkPass
//                //self.showWalletSheet = true
//            }
//
//        } catch {
//            print("Error:", error)
//        }
//    }
    
    func presentWallet(
        barcodeText: String,
        barcodeType: String,
        flightDate: String,
        foregroundColor: String,
        backgroundColor: String,
        labelColor: String,
        semantics: Bool,
        logoText: String,
        fieldsJSON: String,
        endpointURL: URL? = nil
    ) async {
            do {
                let url = endpointURL ?? URL(string: Self.walletEndpointURLString)!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = Self.formBody(Self.requestFields(
                    barcodeText: barcodeText,
                    barcodeType: barcodeType,
                    flightDate: flightDate,
                    debug: Self.debugFlag,
                    foregroundColor: foregroundColor,
                    backgroundColor: backgroundColor,
                    labelColor: labelColor,
                    semantics: semantics,
                    logoText: logoText,
                    fieldsJSON: fieldsJSON
                ))

                let (data, _) = try await URLSession.shared.data(for: request)
                logResponseBody(data)

                let pass = try PKPass(data: data)

                guard let vc = PKAddPassesViewController(pass: pass) else {

                    return

                }

                await MainActor.run {
                    topViewController()?.present(vc, animated: true)
                }

            } catch {

                print(error)

            }

        }
    
    
    
    

    private func logResponseBody(_ data: Data) {
        if let responseBody = String(data: data, encoding: .utf8) {
            print("Wallet response body:", responseBody)
        } else {
            print("Wallet response body is not UTF-8 text. Bytes:", data.count)
        }
    }

    static func requestFields(
        barcodeText: String,
        barcodeType: String,
        flightDate: String,
        debug: String,
        foregroundColor: String,
        backgroundColor: String,
        labelColor: String,
        semantics: Bool,
        logoText: String,
        fieldsJSON: String
    ) -> [String: String] {
        [
            "barcodeText": barcodeText,
            "barcodeType": barcodeType,
            "flightDate": flightDate,
            "debug": debug,
            "foregroundColor": foregroundColor,
            "backgroundColor": backgroundColor,
            "labelColor": labelColor,
            "semantics": semantics ? "true" : "false",
            "logoText": logoText,
            "fieldsConfig": fieldsJSON
        ]
    }

    static func formBody(_ fields: [String: String]) -> Data? {
        formBodyString(fields)?.data(using: .utf8)
    }

    static func formBodyString(_ fields: [String: String]) -> String? {
        fields
            .map { key, value in
                "\(percentEncoded(key))=\(percentEncoded(value))"
            }
            .joined(separator: "&")
    }

    static func percentEncoded(_ value: String) -> String {
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: "+&=")
        return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
    }
    
    @MainActor
    func topViewController() -> UIViewController? {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: \.isKeyWindow)?
            .rootViewController else {
            return nil
        }

        return topViewController(from: rootViewController)
    }

    @MainActor
    private func topViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return topViewController(from: presentedViewController)
        }

        if let navigationController = viewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return topViewController(from: visibleViewController)
        }

        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return topViewController(from: selectedViewController)
        }

        return viewController
    }
}

//struct AddPassView: UIViewControllerRepresentable {
//    let pass: PKPass
//    
//    func makeUIViewController(context: Context) -> PKAddPassesViewController {
//        PKAddPassesViewController(pass: pass)!
//    }
//    
//    func updateUIViewController(
//        _ uiViewController: PKAddPassesViewController,
//        context: Context
//    ) { }
//}
