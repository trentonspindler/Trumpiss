//
//  LegalView.swift
//  Trumpiss
//
//  Presents the (sample) Terms of Service and Privacy Policy documents.
//  This copy is provided as a professional template and is NOT legal advice.
//

import SwiftUI

struct LegalView: View {
    enum Document {
        case terms
        case privacy
    }

    let document: Document
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Last updated: May 30, 2026")
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.textTertiary)

                    ForEach(sections, id: \.heading) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.heading)
                                .font(Theme.title(17))
                                .foregroundStyle(Theme.gold)
                            Text(section.body)
                                .font(Theme.body(14))
                                .foregroundStyle(Theme.textSecondary)
                                .lineSpacing(4)
                        }
                    }

                    Text("This document is a sample template for demonstration purposes and does not constitute legal advice. Consult a licensed attorney before publishing.")
                        .font(Theme.body(11))
                        .italic()
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 12)
                }
                .padding(24)
            }
            .background(BrandBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.gold)
                }
            }
            .toolbarBackground(Theme.navy, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var title: String {
        document == .terms ? "Terms of Service" : "Privacy Policy"
    }

    private struct Section { let heading: String; let body: String }

    private var sections: [Section] {
        document == .terms ? termsSections : privacySections
    }

    private var termsSections: [Section] {
        [
            Section(heading: "1. Acceptance of Terms",
                    body: "By downloading, accessing, or using The Nickname Project (\"the App\"), operated by Liberty Lens Studios (\"we\", \"us\"), you agree to be bound by these Terms of Service. If you do not agree, do not use the App."),
            Section(heading: "2. Entertainment Use Only",
                    body: "The App generates novelty nicknames and personality descriptions for entertainment purposes only. Results are algorithmically generated, are not factual assessments, and should not be relied upon for any decision."),
            Section(heading: "3. Eligibility",
                    body: "You must be at least 18 years of age to use the App. By using the App you represent and warrant that you meet this requirement."),
            Section(heading: "4. Your Content",
                    body: "You retain all rights to photos you capture. Photos are processed locally on your device and are not transmitted to or stored by us. You are responsible for ensuring you have the right to use any image you analyze."),
            Section(heading: "5. Acceptable Use",
                    body: "You agree not to misuse the App, including by analyzing images of other people without their consent, or using results to harass, demean, or harm any individual."),
            Section(heading: "6. Disclaimer of Warranties",
                    body: "The App is provided \"as is\" without warranties of any kind. We do not warrant that the App will be uninterrupted, error-free, or that results will meet your expectations."),
            Section(heading: "7. Limitation of Liability",
                    body: "To the maximum extent permitted by law, Liberty Lens Studios shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App."),
            Section(heading: "8. Changes",
                    body: "We may update these Terms from time to time. Continued use of the App after changes constitutes acceptance of the revised Terms."),
            Section(heading: "9. Contact",
                    body: "Questions about these Terms may be sent to legal@libertylensstudios.example.")
        ]
    }

    private var privacySections: [Section] {
        [
            Section(heading: "1. Overview",
                    body: "This Privacy Policy explains how Liberty Lens Studios collects, uses, and protects your information when you use The Nickname Project."),
            Section(heading: "2. On-Device Photo Processing",
                    body: "Photos you capture or select are analyzed entirely on your device using Apple's Vision framework. Your images are never uploaded, transmitted, or stored on our servers."),
            Section(heading: "3. Information We Collect",
                    body: "We collect the name and email address you voluntarily provide. If you opt in, we also record your consent to receive marketing communications, including the date and time of consent."),
            Section(heading: "4. How We Use Your Information",
                    body: "We use your name to personalize results and your email to deliver your results and, where you have opted in, marketing messages. We do not sell your personal information."),
            Section(heading: "5. Marketing Consent & Opt-Out",
                    body: "Marketing emails are sent only with your explicit opt-in. Every message includes an unsubscribe link, and you may withdraw consent at any time without affecting use of the App."),
            Section(heading: "6. Your Rights",
                    body: "Depending on your jurisdiction, you may have rights under the GDPR, UK GDPR, or CCPA to access, correct, delete, or port your data, and to object to processing. Contact us to exercise these rights."),
            Section(heading: "7. Data Retention",
                    body: "We retain your contact details until you request deletion or withdraw consent. On-device analysis data is not retained after results are generated."),
            Section(heading: "8. Security",
                    body: "We apply industry-standard administrative, technical, and physical safeguards to protect the limited personal data we hold."),
            Section(heading: "9. Contact",
                    body: "For privacy requests, contact privacy@libertylensstudios.example.")
        ]
    }
}
