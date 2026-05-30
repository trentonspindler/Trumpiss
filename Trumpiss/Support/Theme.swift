//
//  Theme.swift
//  Trumpiss
//
//  Centralized brand system — colors, gradients, typography, spacing and haptics.
//

import SwiftUI

enum Theme {
    // MARK: - Brand colors
    static let navy = Color(red: 0.04, green: 0.06, blue: 0.13)
    static let navyElevated = Color(red: 0.08, green: 0.11, blue: 0.20)
    static let gold = Color(red: 0.92, green: 0.74, blue: 0.30)
    static let goldDeep = Color(red: 0.78, green: 0.58, blue: 0.16)
    static let crimson = Color(red: 0.78, green: 0.13, blue: 0.20)
    static let ink = Color(red: 0.02, green: 0.03, blue: 0.07)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.66)
    static let textTertiary = Color.white.opacity(0.40)

    // MARK: - Gradients
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [ink, navy, Color(red: 0.10, green: 0.07, blue: 0.16)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [gold, goldDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGlow: RadialGradient {
        RadialGradient(
            colors: [gold.opacity(0.35), .clear],
            center: .center,
            startRadius: 4,
            endRadius: 320
        )
    }

    // MARK: - Shape
    static let cornerRadius: CGFloat = 22
    static let cardRadius: CGFloat = 26

    // MARK: - Typography
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func mono(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Haptics
enum Haptics {
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
