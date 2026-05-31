//
//  SettingsView.swift
//  BoardingPassScanner2
//

import SwiftUI
import WebKit

private struct EmbeddedWebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.load(URLRequest(url: url))
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct SettingsView: View {
    @AppStorage("showBarcodeText")   private var showBarcodeText   = true
    @AppStorage("showSeatOnBarcode") private var showSeatOnBarcode = true

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        List {
            Section("Preferences") {
                Toggle(isOn: $showBarcodeText) {
                    Text("Show barcode text")
                }
                Toggle(isOn: $showSeatOnBarcode) {
                    Text("Show seat number on barcode")
                }
            }

            Section("About") {
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("Shaffex Limited")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(appBuild)
                        .foregroundStyle(.secondary)
                }

                Button {
                    if let url = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1166018608&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Rate this app")
                        .foregroundStyle(Color.accentColor)
                }

                NavigationLink {
                    EmbeddedWebView(url: URL(string: "https://shaffex.com/api/boardingpass2/Links/privacyPolicy.html")!)
                        .ignoresSafeArea()
                        .navigationTitle("Privacy Policy")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Text("Privacy Policy")
                }

                NavigationLink {
                    EmbeddedWebView(url: URL(string: "https://shaffex.com/api/boardingpass2/Links/contactUs.php")!)
                        .ignoresSafeArea()
                        .navigationTitle("Contact Us")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    Text("Contact us")
                }
            }
        }
        .navigationTitle(String(localized: "TEXT_SETTINGS"))
    }
}

struct SettingsPluginView: View {
    var body: some View {
        SettingsView()
    }
}
