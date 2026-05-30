//
//  LaunchView.swift
//  Trumpiss
//
//  Branded splash screen that auto-advances into onboarding.
//

import SwiftUI

struct LaunchView: View {
    @EnvironmentObject private var app: AppState
    @State private var appear = false
    @State private var glow = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            BrandMark(size: 110)
                .scaleEffect(appear ? 1 : 0.6)
                .opacity(appear ? 1 : 0)
                .shadow(color: Theme.gold.opacity(glow ? 0.7 : 0.2), radius: glow ? 40 : 12)

            VStack(spacing: 8) {
                Text("THE NICKNAME")
                    .font(Theme.display(30))
                    .tracking(2)
                    .foregroundStyle(Theme.textPrimary)
                Text("PROJECT")
                    .font(Theme.display(30))
                    .tracking(8)
                    .foregroundStyle(Theme.goldGradient)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 12)

            Text("AI-Powered Portrait Branding")
                .font(Theme.body(14))
                .tracking(1)
                .foregroundStyle(Theme.textSecondary)
                .opacity(appear ? 1 : 0)

            Spacer()

            VStack(spacing: 6) {
                ProgressView()
                    .tint(Theme.gold)
                Text("A LIBERTY LENS STUDIOS PRODUCTION")
                    .font(Theme.mono(10))
                    .tracking(2)
                    .foregroundStyle(Theme.textTertiary)
            }
            .opacity(appear ? 1 : 0)
            .padding(.bottom, 28)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { appear = true }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glow = true }
            Task {
                try? await Task.sleep(nanoseconds: 2_400_000_000)
                app.finishLaunch()
            }
        }
    }
}
