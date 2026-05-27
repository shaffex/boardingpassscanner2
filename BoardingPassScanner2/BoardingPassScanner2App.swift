//
//  BoardingPassScanner2App.swift
//  BoardingPassScanner2
//
//  Created by Peter Popovec on 08/05/2026.
//

import SwiftUI

@main
struct BoardingPassScanner2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(BoardingPassMapper.shared)
        }
    }
}
