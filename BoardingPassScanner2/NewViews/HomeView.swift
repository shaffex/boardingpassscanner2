//
//  HomeView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 26/05/2026.
//

import SwiftUI
import SwiftData
import AVFoundation
import WebKit
import MagicUiFramework

private struct EmbeddedWebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.load(URLRequest(url: url))
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Query private var records: [BoardingPassRecord]

    @State private var selectedUpcomingFlight: SelectedFlight?
    @State private var showCameraPermissionSheet = false
    @State private var showHelp = false

    private var upcomingFlight: BoardingPassRecord? {
        let today = Calendar.current.startOfDay(for: .now)
        return records
            .map { (record: $0, date: $0.flightDate) }
            .filter { Calendar.current.startOfDay(for: $0.date) >= today }
            .min { $0.date < $1.date }?
            .record
    }

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("Next Flight") {
                        if let upcomingFlight {
                            Button {
                                Haptics.tap()
                                selectedUpcomingFlight = SelectedFlight(record: upcomingFlight)
                            } label: {
                                BoardingPassCard(record: upcomingFlight, style: .compact)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NoUpcomingFlightCard()
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    Section("Boarding Pass") {
                        VStack(spacing: 12) {
                            actionButton(
                                title: String(localized: "TEXT_SCAN_BOARDING_PASS"),
                                description: String(localized: "TEXT_SCAN_BOARDING_DESCRIPTION"),
                                systemImage: "camera.viewfinder"
                            ) {
                                requestCameraAndScan()
                            }

                            actionButton(
                                title: String(localized: "TEXT_BATCH_SCAN_BOARDING_PASS"),
                                description: String(localized: "TEXT_BATCH_SCAN_BOARDING_PASS_DESCRIPTION"),
                                systemImage: "square.stack.3d.up"
                            ) {
                                requestCameraAndScan(batch: true)
                            }

                            actionButton(
                                title: String(localized: "TEXT_IMPORT_BOARDING_PASS"),
                                description: String(localized: "TEXT_IMPORT_BOARDING_PASS_DESCRIPTION"),
                                systemImage: "photo.on.rectangle"
                            ) {
                                PluginActions.shared.runAction("setBool:isShowingImagePicker=true")
                            }
                            
                            actionButton(
                                title: String(localized: "TEXT_PASTE_BOARDING_PASS"),
                                description: String(localized: "TEXT_PASTE_BOARDING_PASS_DESCRIPTION"),
                                systemImage: "doc.on.clipboard"
                            ) {
                                PluginActions.shared.runAction("detectFromClipboard")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    Section("Help") {
                        actionButton(
                            title: String(localized: "TEXT_HELP"),
                            description: String(localized: "TEXT_HELP_DESCRIPTION"),
                            systemImage: "questionmark.circle"
                        ) {
                            showHelp = true
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Section {
                        ProUpgradeCard()
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    if MainConfig.TESTING_MODE_SHOW_TESTPASSES {
                        MagicUiView(string: """
<body>
<remoteview src="resource:DEBUG_TestPasses"/>
</body>
""")
                    }
                }
                
                MagicUiView(string: "<body><admobview adUnitID=\"\(MainConfig.adUnitID_Banner)\"/></body>")
                    .padding(.bottom, 8)
            }
            .navigationTitle(String(localized: "TEXT_HOME"))
            .sheet(item: $selectedUpcomingFlight) { selectedFlight in
                NavigationStack {
                    BoardingPassDetailView(record: selectedFlight.record)
                }
            }
            .sheet(isPresented: $showCameraPermissionSheet) {
                CameraPermissionDeniedView()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showHelp) {
                NavigationStack {
                    EmbeddedWebView(url: URL(string: "https://shaffex.com/api/boardingpass2/Links/help.html")!)
                        .ignoresSafeArea()
                        .navigationTitle(String(localized: "TEXT_HELP"))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(String(localized: "Done")) {
                                    showHelp = false
                                }
                            }
                        }
                }
            }
        }
    }

    private func requestCameraAndScan(batch: Bool = false) {
        let presentScanner = "presentSheet:item:sheetItem;id:\(batch ? "batchScannerView" : "scannerView")"
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            PluginActions.shared.runAction(presentScanner)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        PluginActions.shared.runAction(presentScanner)
                    } else {
                        showCameraPermissionSheet = true
                    }
                }
            }
        default:
            showCameraPermissionSheet = true
        }
    }

    private func actionButton(
        title: String,
        description: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            actionCardLabel(title: title, description: description, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func actionCardLabel(
        title: String,
        description: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 52, height: 52)
                .background(Color.blue.opacity(colorScheme == .dark ? 0.18 : 0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(actionButtonBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(actionButtonStroke, lineWidth: 1)
        }
        .shadow(color: actionButtonShadow, radius: 14, x: 0, y: 8)
    }

    private var actionButtonBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : .white
    }

    private var actionButtonStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }

    private var actionButtonShadow: Color {
        colorScheme == .dark ? .clear : Color.black.opacity(0.06)
    }
}

private struct SelectedFlight: Identifiable {
    let id: PersistentIdentifier
    let record: BoardingPassRecord

    init(record: BoardingPassRecord) {
        self.id = record.persistentModelID
        self.record = record
    }
}

private struct NoUpcomingFlightCard: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 52, height: 52)
                .background(Color.secondary.opacity(colorScheme == .dark ? 0.16 : 0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text("No upcoming flight")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Your next saved flight will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        }
        .shadow(color: cardShadow, radius: 14, x: 0, y: 8)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : .white
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }

    private var cardShadow: Color {
        colorScheme == .dark ? .clear : Color.black.opacity(0.06)
    }
}

struct HomePluginView: View {
    var body: some View {
        HomeView()
            .modelContainer(BoardingPassStore.shared.container)
    }
}

#Preview {
    HomeView()
}
