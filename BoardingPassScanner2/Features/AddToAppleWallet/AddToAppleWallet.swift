//
//  AddToAppleWallet.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 08/05/2026.
//

import SwiftUI
import PassKit
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

    static func presentForRecord(_ record: BoardingPassRecord) async {
        let flightDateString = ISO8601DateFormatter().string(from: record.flightDate)
        await Action_addPass(node: nil).presentWallet(
            barcodeText: record.text,
            flightDate: flightDateString
        )
    }

    static func requestDebugDescription(for record: BoardingPassRecord) -> String {
        let flightDateString = ISO8601DateFormatter().string(from: record.flightDate)
        let fields = requestFields(
            barcodeText: record.text,
            flightDate: flightDateString,
            debug: Self.debugFlag
        )
        let body = formBodyString(fields) ?? ""

        return """
        POST \(walletEndpointURLString)
        Content-Type: application/x-www-form-urlencoded

        barcodeText=\(fields["barcodeText"] ?? "")
        flightDate=\(fields["flightDate"] ?? "")
        debug=\(fields["debug"] ?? "")

        Body:
        \(body)
        """
    }

    func execute(_ actionString: String) {
        Task {
            await presentWallet(
                barcodeText: SxMagicVariables.shared.value(forKey: "selectedCode.text") as? String ?? "",
                flightDate: SxMagicVariables.shared.value(forKey: "selectedCode.flightDate") as? String ?? ""
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
    
    func presentWallet(barcodeText: String, flightDate: String) async {
            do {
                let url = URL(string: Self.walletEndpointURLString)!
                //let url = URL(string: "https://shaffex.com/api/boardingpass2/Tests/generateBoardingPass.php")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = Self.formBody(Self.requestFields(
                    barcodeText: barcodeText,
                    flightDate: flightDate,
                    debug: Self.debugFlag
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

    static func requestFields(barcodeText: String, flightDate: String, debug: String) -> [String: String] {
        [
            "barcodeText": barcodeText,
            "flightDate": flightDate,
            "debug": debug
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
