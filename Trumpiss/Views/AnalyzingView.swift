//
//  AnalyzingView.swift
//  Trumpiss
//
//  A cinematic "analysis in progress" experience shown while the engine works.
//

import SwiftUI

struct AnalyzingView: View {
    @EnvironmentObject private var app: AppState
    @State private var rotate = false
    @State private var pulse = false
    @State private var stepIndex = 0

    private let steps = [
        "Detecting facial geometry…",
        "Mapping 68 landmark points…",
        "Measuring star power & energy…",
        "Cross-referencing nickname matrix…",
        "Finalizing your verdict…"
    ]

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                if let image = app.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.gold.opacity(0.5), lineWidth: 2))
                        .opacity(0.85)
                }

                Circle()
                    .trim(from: 0, to: 0.18)
                    .stroke(Theme.goldGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 230, height: 230)
                    .rotationEffect(.degrees(rotate ? 360 : 0))

                Circle()
                    .trim(from: 0.55, to: 0.7)
                    .stroke(Theme.crimson.opacity(0.7), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 230, height: 230)
                    .rotationEffect(.degrees(rotate ? -360 : 0))

                Circle()
                    .stroke(Theme.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: 260, height: 260)
                    .scaleEffect(pulse ? 1.08 : 0.96)
                    .opacity(pulse ? 0 : 0.8)
            }

            VStack(spacing: 10) {
                Text("ANALYZING")
                    .font(Theme.mono(13))
                    .tracking(4)
                    .foregroundStyle(Theme.gold)

                Text(steps[min(stepIndex, steps.count - 1)])
                    .font(Theme.title(17))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                    .id(stepIndex)
                    .animation(.easeInOut, value: stepIndex)
            }

            Spacer()

            Text("Powered by on-device Vision intelligence")
                .font(Theme.body(12))
                .foregroundStyle(Theme.textTertiary)
                .padding(.bottom, 30)
        }
        .padding()
        .onAppear {
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) { rotate = true }
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { pulse = true }
            advanceSteps()
        }
    }

    private func advanceSteps() {
        guard stepIndex < steps.count - 1 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
            withAnimation { stepIndex += 1 }
            advanceSteps()
        }
    }
}
