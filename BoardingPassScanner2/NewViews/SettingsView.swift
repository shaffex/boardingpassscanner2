//
//  SettingsView.swift
//  BoardingPassScanner2
//

import SwiftUI
import SafariServices

private struct InlineSafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct SettingsView: View {
    @AppStorage("showBarcodeText")   private var showBarcodeText   = true
    @AppStorage("showSeatOnBarcode") private var showSeatOnBarcode = true

    @State private var showPrivacyPolicy = false
    @State private var showContactUs     = false

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
                    Haptics.tap()
                    if let url = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1166018608&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Rate this app")
                        .foregroundStyle(Color.accentColor)
                }

                Button {
                    Haptics.tap()
                    showPrivacyPolicy = true
                } label: {
                    HStack {
                        Text("Privacy Policy")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    Haptics.tap()
                    showContactUs = true
                } label: {
                    HStack {
                        Text("Contact us")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "TEXT_SETTINGS"))
        .sheet(isPresented: $showPrivacyPolicy) {
            InlineSafariView(url: URL(string: "https://shaffex.com/api/boardingpass2/Links/privacyPolicy.html")!)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showContactUs) {
            InlineSafariView(url: URL(string: "https://shaffex.com/api/boardingpass2/Links/contactUs.php")!)
                .ignoresSafeArea()
        }
    }
}

struct SettingsPluginView: View {
    var body: some View {
        SettingsView()
    }
}
