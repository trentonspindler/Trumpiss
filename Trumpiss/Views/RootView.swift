//
//  RootView.swift
//  Trumpiss
//
//  Routes between the app's phases with smooth transitions.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        ZStack {
            BrandBackground()

            switch app.phase {
            case .launch:
                LaunchView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            case .consent:
                ConsentView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .capture:
                CaptureView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .analyzing:
                AnalyzingView()
                    .transition(.opacity)
            case .result:
                ResultView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.45), value: app.phase)
    }
}
