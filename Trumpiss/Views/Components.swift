//
//  Components.swift
//  Trumpiss
//
//  Shared, reusable UI building blocks used across screens.
//

import SwiftUI

// MARK: - Background

struct BrandBackground: View {
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            Theme.heroGlow
                .frame(width: 600, height: 600)
                .offset(y: -220)
                .blendMode(.screen)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Brand mark

struct BrandMark: View {
    var size: CGFloat = 84

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.goldGradient)
                .shadow(color: Theme.gold.opacity(0.5), radius: 18, y: 6)
            Image(systemName: "crown.fill")
                .font(.system(size: size * 0.42, weight: .black))
                .foregroundStyle(Theme.ink)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Primary button

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .bold))
                }
                Text(title)
                    .font(Theme.title(17))
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.goldGradient)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: Theme.gold.opacity(enabled ? 0.45 : 0), radius: 16, y: 8)
        }
        .buttonStyle(PressStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(Theme.title(16))
            }
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1.2)
            )
        }
        .buttonStyle(PressStyle())
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Glass card

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.navyElevated.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Pill / chip

struct Pill: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Theme.mono(11))
            .tracking(1.5)
            .foregroundStyle(Theme.gold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Theme.gold.opacity(0.12))
            )
            .overlay(
                Capsule().stroke(Theme.gold.opacity(0.35), lineWidth: 1)
            )
    }
}
