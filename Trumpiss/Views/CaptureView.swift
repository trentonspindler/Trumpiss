//
//  CaptureView.swift
//  Trumpiss
//
//  Lets the user take a new portrait or choose one from their library.
//

import SwiftUI

struct CaptureView: View {
    @EnvironmentObject private var app: AppState
    @State private var showCamera = false
    @State private var showLibrary = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Pill(text: "Step 2 of 2 · Capture")
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10, 8]))
                    .foregroundStyle(Theme.gold.opacity(0.4))
                    .frame(width: 240, height: 300)

                VStack(spacing: 14) {
                    Image(systemName: "person.crop.rectangle.badge.plus")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(Theme.goldGradient)
                    Text("Center your face")
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            VStack(spacing: 10) {
                Text("Ready for your close-up,\n\(app.profile.firstName)?")
                    .font(Theme.display(26))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)
                Text("Good lighting and a head-on angle give the engine the most to work with.")
                    .font(Theme.body(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 36)
                    .lineSpacing(3)
            }

            if let error = app.analysisError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.crimson)
                    .multilineTextAlignment(.leading)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.crimson.opacity(0.12))
                    )
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(title: "Take Photo", systemImage: "camera.fill") {
                    showCamera = true
                }
                SecondaryButton(title: "Choose from Library", systemImage: "photo.on.rectangle") {
                    showLibrary = true
                }
            }
            .padding(.horizontal, 24)

            Text("🔒 Analyzed on-device. Your photo never leaves your iPhone.")
                .font(Theme.body(12))
                .foregroundStyle(Theme.textTertiary)
                .padding(.bottom, 24)
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(source: .camera) { app.didCapture($0) }
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showLibrary) {
            ImagePicker(source: .library) { app.didCapture($0) }
                .ignoresSafeArea()
        }
    }
}
