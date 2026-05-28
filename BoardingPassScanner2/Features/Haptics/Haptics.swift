//
//  Haptics.swift
//  BoardingPassScanner2
//

import SwiftUI
import UIKit

// Centralized haptic feedback. Tweak the static fields here to change
// behavior everywhere, or set `isEnabled = false` to silence in-app haptics.
enum Haptics {
    static var isEnabled = true

    static var tapStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
    static var warningType: UINotificationFeedbackGenerator.FeedbackType = .warning
    static var successType: UINotificationFeedbackGenerator.FeedbackType = .success

    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: tapStyle).impactOccurred()
    }

    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func warning() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(warningType)
    }

    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(successType)
    }
}

extension View {
    // Attach a light impact haptic to a tap on this view. Use on a Button or
    // tappable label when wrapping the action closure isn't convenient (e.g.
    // ShareLink, NavigationLink).
    func hapticTap() -> some View {
        simultaneousGesture(TapGesture().onEnded { Haptics.tap() })
    }
}
