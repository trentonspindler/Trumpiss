//
//  ResultView.swift
//  Trumpiss
//
//  The big reveal — the user's signature nickname, verdict, confidence and a
//  full trait breakdown, plus sharing and restart actions.
//

import SwiftUI

struct ResultView: View {
    @EnvironmentObject private var app: AppState
    @State private var reveal = false
    @State private var animateBars = false

    var body: some View {
        if let result = app.result {
            ScrollView {
                VStack(spacing: 24) {
                    portrait

                    VStack(spacing: 10) {
                        Pill(text: "Your Signature Nickname")
                        Text("“\(result.nickname)”")
                            .font(Theme.display(34))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.goldGradient)
                            .minimumScaleFactor(0.6)
                            .padding(.horizontal, 12)
                        Text(result.tagline)
                            .font(Theme.body(16))
                            .italic()
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(reveal ? 1 : 0)
                    .offset(y: reveal ? 0 : 16)

                    verdictCard(result)
                    confidenceCard(result)
                    traitsCard(result)
                    actions(result)

                    Text("Generated on-device · For entertainment only")
                        .font(Theme.body(11))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.bottom, 20)
                }
                .padding(24)
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) { reveal = true }
                withAnimation(.easeOut(duration: 0.9).delay(0.4)) { animateBars = true }
            }
        } else {
            ProgressView().tint(Theme.gold)
        }
    }

    private var portrait: some View {
        ZStack {
            if let image = app.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.goldGradient, lineWidth: 3))
                    .shadow(color: Theme.gold.opacity(0.4), radius: 16, y: 6)
            }
            Image(systemName: "crown.fill")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(Theme.ink)
                .padding(8)
                .background(Circle().fill(Theme.goldGradient))
                .offset(x: 44, y: -44)
        }
        .scaleEffect(reveal ? 1 : 0.7)
        .opacity(reveal ? 1 : 0)
        .padding(.top, 12)
    }

    private func verdictCard(_ result: NicknameResult) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("THE VERDICT", systemImage: "quote.bubble.fill")
                    .font(Theme.mono(11))
                    .tracking(2)
                    .foregroundStyle(Theme.gold)
                Text(result.verdict)
                    .font(Theme.title(19))
                    .foregroundStyle(Theme.textPrimary)
                    .lineSpacing(3)
                Text("— Analysis Engine, presidential mode")
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func confidenceCard(_ result: NicknameResult) -> some View {
        GlassCard {
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: animateBars ? CGFloat(result.confidence) / 100 : 0)
                        .stroke(Theme.goldGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(result.confidence)%")
                        .font(Theme.display(20))
                        .foregroundStyle(Theme.textPrimary)
                }
                .frame(width: 78, height: 78)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Match Confidence")
                        .font(Theme.title(16))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Dominant signal: \(result.dominantTrait)")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
        }
    }

    private func traitsCard(_ result: NicknameResult) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("PERSONALITY BREAKDOWN", systemImage: "chart.bar.fill")
                    .font(Theme.mono(11))
                    .tracking(2)
                    .foregroundStyle(Theme.gold)

                ForEach(result.traits) { trait in
                    VStack(spacing: 6) {
                        HStack {
                            Label(trait.name, systemImage: trait.icon)
                                .font(Theme.body(14))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(trait.value)")
                                .font(Theme.mono(13))
                                .foregroundStyle(Theme.gold)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule()
                                    .fill(Theme.goldGradient)
                                    .frame(width: animateBars ? geo.size.width * CGFloat(trait.value) / 100 : 0)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
    }

    private func actions(_ result: NicknameResult) -> some View {
        VStack(spacing: 12) {
            ShareLink(item: shareText(result)) {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .bold))
                    Text("Share My Nickname")
                        .font(Theme.title(17))
                }
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.goldGradient)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .shadow(color: Theme.gold.opacity(0.4), radius: 14, y: 8)
            }
            .simultaneousGesture(TapGesture().onEnded { Haptics.tap() })

            SecondaryButton(title: "Try Another Photo", systemImage: "arrow.counterclockwise") {
                app.startOver()
            }
        }
        .padding(.top, 4)
    }

    private func shareText(_ result: NicknameResult) -> String {
        """
        My signature nickname is “\(result.nickname)” 👑
        \(result.verdict)
        Match confidence: \(result.confidence)%

        Get yours with The Nickname Project by Liberty Lens Studios.
        """
    }
}
