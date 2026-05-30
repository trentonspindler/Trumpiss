//
//  ConsentView.swift
//  Trumpiss
//
//  Collects basic profile info and records marketing / terms consent before
//  any photo is captured.
//

import SwiftUI

struct ConsentView: View {
    @EnvironmentObject private var app: AppState
    @FocusState private var focused: Field?
    @State private var showTerms = false
    @State private var showPrivacy = false

    private enum Field { case name, email }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                GlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        fieldLabel("Full Name", required: true)
                        textField("e.g. Jordan Rivera", text: $app.profile.fullName)
                            .textContentType(.name)
                            .focused($focused, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focused = .email }

                        fieldLabel("Email Address", required: true)
                        textField("you@example.com", text: $app.profile.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focused, equals: .email)
                            .submitLabel(.done)
                            .onSubmit { focused = nil }

                        if !app.profile.email.isEmpty && !UserProfile.isValidEmail(app.profile.email) {
                            Label("Please enter a valid email address.", systemImage: "exclamationmark.triangle.fill")
                                .font(Theme.body(12))
                                .foregroundStyle(Theme.crimson)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        consentToggle(
                            isOn: $app.profile.marketingOptIn,
                            title: "Keep me in the loop",
                            detail: "I agree to receive product news, feature updates, and promotional offers from Liberty Lens Studios by email. I understand I can unsubscribe at any time using the link in any message."
                        )

                        Divider().overlay(Color.white.opacity(0.08))

                        consentToggle(
                            isOn: $app.profile.agreedToTerms,
                            title: "Terms & Privacy",
                            detail: nil,
                            required: true
                        ) {
                            (
                                Text("I am 18 or older and I agree to the ")
                                + Text("Terms of Service").foregroundColor(Theme.gold).underline()
                                + Text(" and ")
                                + Text("Privacy Policy").foregroundColor(Theme.gold).underline()
                                + Text(".")
                            )
                            .font(Theme.body(13))
                            .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                HStack(spacing: 18) {
                    Button("Terms of Service") { showTerms = true }
                    Button("Privacy Policy") { showPrivacy = true }
                }
                .font(Theme.body(13))
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)

                legalFootnote

                PrimaryButton(title: "Agree & Continue", systemImage: "lock.fill", enabled: app.profile.isValid) {
                    focused = nil
                    app.submitConsent()
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showTerms) { LegalView(document: .terms) }
        .sheet(isPresented: $showPrivacy) { LegalView(document: .privacy) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Pill(text: "Step 1 of 2 · Your Details")
            Text("Let's get acquainted")
                .font(Theme.display(30))
                .foregroundStyle(Theme.textPrimary)
            Text("We personalize your nickname with your name. A few details up front and we're ready to roll.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
        }
        .padding(.top, 8)
    }

    private var legalFootnote: some View {
        Text("Your photo is analyzed entirely on your device and is never uploaded to our servers. The name and email you provide are stored to deliver your results and, if you opt in, marketing communications. See our Privacy Policy for details on data handling, retention, and your rights under GDPR and CCPA.")
            .font(Theme.body(11))
            .foregroundStyle(Theme.textTertiary)
            .lineSpacing(2)
    }

    // MARK: - Builders

    private func fieldLabel(_ text: String, required: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(text.uppercased())
                .font(Theme.mono(11))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)
            if required {
                Text("*").foregroundStyle(Theme.crimson).font(Theme.mono(11))
            }
        }
    }

    private func textField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(Theme.textTertiary))
            .font(Theme.body(17))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.ink.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }

    @ViewBuilder
    private func consentToggle<L: View>(
        isOn: Binding<Bool>,
        title: String,
        detail: String?,
        required: Bool = false,
        @ViewBuilder customDetail: () -> L = { EmptyView() }
    ) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(Theme.title(15))
                        .foregroundStyle(Theme.textPrimary)
                    if required {
                        Text("(required)")
                            .font(Theme.body(11))
                            .foregroundStyle(Theme.crimson)
                    }
                }
                if let detail {
                    Text(detail)
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    customDetail()
                }
            }
        }
        .tint(Theme.goldDeep)
    }
}
