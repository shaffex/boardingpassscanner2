//
//  ContentView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 08/05/2026.
//

import SwiftUI
import MagicUiFramework

struct ContentView: View {
    @StateObject private var bannerPresenter = BannerPresenter.shared

    init() {
        Task { @MainActor in
            BoardingPassStore.shared.prefetchParsed()
        }
        
        Task {
            try? await DataUpdater().checkForDataUpdate()
        }
        
        // views
        MagicUiView.installViewPlugin(name: "barcodescannerlocal", plugin: SxView_BarcodeScanner.self)
        
        MagicUiView.installViewPlugin(name: "barcodeicon", plugin: SxView_BarcodeIcon.self)
        MagicUiView.installViewPlugin(name: "buttonAddToAppleWallet", plugin: ButtonAddToAppleWallet.self)
        MagicUiView.installViewPlugin(name: "ViewFinderCorners", plugin: SxView_ViewFinderCorners.self)
        MagicUiView.installViewPlugin(name: "homeview", plugin: HomePluginView())
        MagicUiView.installViewPlugin(name: "myBoardingPassesList", plugin: MyBoardingPassesPluginView())
        MagicUiView.installViewPlugin(name: "toolsview", plugin: ToolsPluginView())
        MagicUiView.installViewPlugin(name: "admobview", plugin: AdmobBanner.self)
        
        // modifiers
        MagicUiView.installModifierPlugin(name: "photospicker2", plugin: SxModifier_photosPicker2.self)
        
        // actions
        MagicUiView.installActionPlugin(name: "showBanner", plugin: Action_showBanner.self)
        
        MagicUiView.installActionPlugin(name: "addNewBoardingPass", plugin: Action_addNewBoardingPass.self)
        MagicUiView.installActionPlugin(name: "addPassToWallet", plugin: Action_addPass.self)
        MagicUiView.installActionPlugin(name: "detectFromClipboard", plugin: Action_detectFromClipboard.self)
        
        MagicUiView.installActionPlugin(name: "importFromV1", plugin: Action_importFromV1.self)
    }

    var body: some View {
        ZStack(alignment: .top) {
            MagicUiView(resource: "MainScreen")
                .onFirstAppear {
                    MagicLocalisation.exportKeys()
                    
                    Task { @MainActor in
                        MigrationAssistant.checkMigration()
                    }
                }

            AppBannerOverlay(presenter: bannerPresenter)
        }
    }
}

#Preview {
    ContentView()
        .environment(BoardingPassMapper.shared)
}
