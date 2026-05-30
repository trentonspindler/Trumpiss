//
//  Models.swift
//  Trumpiss
//
//  Core data models for the user profile and the generated nickname result.
//

import Foundation

/// The basic information collected on the consent screen before capture.
struct UserProfile: Codable, Equatable {
    var fullName: String = ""
    var email: String = ""
    var marketingOptIn: Bool = false
    var agreedToTerms: Bool = false

    var firstName: String {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.split(separator: " ").first.map(String.init) ?? trimmed
    }

    var isValid: Bool {
        !firstName.isEmpty && Self.isValidEmail(email) && agreedToTerms
    }

    static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}

/// A single measured personality/appearance trait shown in the analysis breakdown.
struct TraitScore: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let value: Int           // 0...100
    let icon: String         // SF Symbol
}

/// The final result the app reveals.
struct NicknameResult: Equatable {
    let nickname: String
    let tagline: String
    let verdict: String      // a short "Trump-style" quote
    let confidence: Int      // 0...100
    let traits: [TraitScore]
    let dominantTrait: String
}
