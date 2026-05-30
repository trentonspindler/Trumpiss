//
//  AppState.swift
//  Trumpiss
//
//  The single source of truth that drives the app's flow and holds the
//  user's profile, captured photo and generated result.
//

import SwiftUI

@MainActor
final class AppState: ObservableObject {

    enum Phase {
        case launch
        case onboarding
        case consent
        case capture
        case analyzing
        case result
    }

    @Published var phase: Phase = .launch
    @Published var profile = UserProfile()
    @Published var capturedImage: UIImage?
    @Published var result: NicknameResult?
    @Published var analysisError: String?

    private let analyzer = FaceAnalyzer()
    private let engine = NicknameEngine()

    private let profileKey = "trumpiss.profile.v1"

    init() {
        loadProfile()
    }

    // MARK: - Flow

    func finishLaunch() {
        withAnimation(.easeInOut(duration: 0.5)) {
            phase = .onboarding
        }
    }

    func startConsent() {
        withAnimation(.easeInOut(duration: 0.4)) {
            phase = .consent
        }
    }

    func submitConsent() {
        guard profile.isValid else { return }
        saveProfile()
        Haptics.success()
        withAnimation(.easeInOut(duration: 0.4)) {
            phase = .capture
        }
    }

    func didCapture(_ image: UIImage) {
        capturedImage = image
        analysisError = nil
        withAnimation(.easeInOut(duration: 0.4)) {
            phase = .analyzing
        }
        runAnalysis(on: image)
    }

    func runAnalysis(on image: UIImage) {
        Task {
            // Run the real analysis and a minimum "cinematic" delay in parallel
            // so the experience always feels deliberate and premium.
            async let minimumDelay: Void = Self.sleep(seconds: 3.2)
            do {
                let metrics = try await analyzer.analyze(image)
                let generated = engine.generate(from: metrics, name: profile.firstName)
                _ = await minimumDelay
                self.result = generated
                Haptics.success()
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.phase = .result
                }
            } catch {
                _ = await minimumDelay
                self.analysisError = error.localizedDescription
                Haptics.heavy()
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.phase = .capture
                }
            }
        }
    }

    func startOver() {
        capturedImage = nil
        result = nil
        analysisError = nil
        withAnimation(.easeInOut(duration: 0.4)) {
            phase = .capture
        }
    }

    func retakeFromError() {
        analysisError = nil
        capturedImage = nil
    }

    // MARK: - Persistence

    private func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: profileKey),
              let saved = try? JSONDecoder().decode(UserProfile.self, from: data) else { return }
        profile = saved
    }

    private func saveProfile() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: profileKey)
    }

    private static func sleep(seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
