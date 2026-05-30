//
//  OnboardingView.swift
//  Trumpiss
//
//  A short, paged value-proposition walkthrough.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var app: AppState
    @State private var page = 0

    private struct Slide: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        Slide(icon: "camera.aperture",
              title: "Snap Your Portrait",
              body: "One photo is all our engine needs. Front camera, good light, and a confident look."),
        Slide(icon: "cpu",
              title: "On-Device Analysis",
              body: "Apple's Vision framework maps dozens of facial signals — right on your iPhone. Your photo never leaves the device."),
        Slide(icon: "sparkles",
              title: "Get Your Signature Nickname",
              body: "We translate your look into a bold, presidential-grade nickname — complete with a full personality breakdown.")
    ]

    var body: some View {
        VStack {
            HStack {
                Pill(text: "Welcome")
                Spacer()
                Button("Skip") {
                    Haptics.tap()
                    app.startConsent()
                }
                .font(Theme.title(15))
                .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            TabView(selection: $page) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    slideView(slide).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Theme.gold : Color.white.opacity(0.2))
                        .frame(width: i == page ? 22 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: page)
                }
            }
            .padding(.bottom, 18)

            PrimaryButton(
                title: page == slides.count - 1 ? "Get Started" : "Continue",
                systemImage: page == slides.count - 1 ? "arrow.right" : nil
            ) {
                if page == slides.count - 1 {
                    app.startConsent()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.gold.opacity(0.12))
                    .frame(width: 168, height: 168)
                Circle()
                    .stroke(Theme.gold.opacity(0.3), lineWidth: 1)
                    .frame(width: 168, height: 168)
                Image(systemName: slide.icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Theme.goldGradient)
            }

            VStack(spacing: 14) {
                Text(slide.title)
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(slide.body)
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
            }
            Spacer()
        }
    }
}
