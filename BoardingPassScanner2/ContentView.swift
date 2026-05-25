//
//  ContentView.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 08/05/2026.
//

import SwiftUI
import MagicUiFramework

struct ContentView: View {
    init() {
        // views
        MagicUiView.installViewPlugin(name: "menuitem", plugin: MenuItemView.self)
        MagicUiView.installViewPlugin(name: "barcodescannerlocal", plugin: SxView_BarcodeScanner.self)
        
        MagicUiView.installViewPlugin(name: "barcodeicon", plugin: SxView_BarcodeIcon.self)
        MagicUiView.installViewPlugin(name: "buttonAddToAppleWallet", plugin: ButtonAddToAppleWallet.self)
        MagicUiView.installViewPlugin(name: "ViewFinderCorners", plugin: SxView_ViewFinderCorners.self)
        
        // modifiers
        MagicUiView.installModifierPlugin(name: "photospicker2", plugin: SxModifier_photosPicker2.self)
        
        // actions
        MagicUiView.installActionPlugin(name: "showBanner", plugin: Action_showBanner.self)
        
        MagicUiView.installActionPlugin(name: "addNewBoardingPass", plugin: Action_addNewBoardingPass.self)
        MagicUiView.installActionPlugin(name: "addPassToWallet", plugin: Action_addPass.self)
        MagicUiView.installActionPlugin(name: "detectFromClipboard", plugin: Action_detectFromClipboard.self)
        
        MagicUiView.installActionPlugin(name: "importFromV1", plugin: Action_importFromV1.self)
        
        MagicUiView.installActionPlugin(name: "checkForDataUpdate", plugin: Action_checkForDataUpdate.self)
        //MagicUiView.installActionPlugin(name: "decodeSelectedBoardingPass", plugin: Action_decodeSelectedBoardingPass.self)
    }
    
    var body: some View {
        MagicUiView(resource: "MainScreen")
            .onFirstAppear {
                Task {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        MigrationAssistant.checkMigration()
                        // what if ???
                    }
                }
//                Task { @MainActor in
//                    try? await Task.sleep(nanoseconds: 1_000_000_000)
//                    BoardingPassBackfill.backfillMissingFields()
//                }
            }
    }
}

#Preview {
    ContentView()
}
