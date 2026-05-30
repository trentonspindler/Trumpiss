//
//  NicknameEngine.swift
//  Trumpiss
//
//  Translates objective face metrics into a signature nickname and a
//  shareable "analysis". Fully deterministic for a given photo + name, so a
//  user always gets the same result for the same portrait.
//
//  The nicknames are written to be playful and brand-safe.
//

import Foundation

/// A tiny deterministic PRNG (SplitMix64) so results are reproducible.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct NicknameEngine {

    /// Each nickname "family" maps to a dominant trait and a flattering tagline.
    private struct Style {
        let prefixes: [String]
        let trait: String
        let taglines: [String]
        let verdicts: [String]
    }

    private let styles: [Style] = [
        Style(
            prefixes: ["Big-League", "Tremendous", "Bigly", "The Powerful"],
            trait: "Star Power",
            taglines: ["A presence you can feel from across the room.",
                       "Born to stand in the spotlight."],
            verdicts: ["\"Total star. Believe me, everybody's talking about it.\"",
                       "\"A face for the big stage. The biggest. Tremendous.\""]
        ),
        Style(
            prefixes: ["High-Energy", "Turbo", "Rocket", "The Unstoppable"],
            trait: "Energy",
            taglines: ["Pure momentum — never slows down.",
                       "The kind of energy that wins."],
            verdicts: ["\"So much energy. Incredible. We love the energy.\"",
                       "\"Always moving, always winning. Very high-energy person.\""]
        ),
        Style(
            prefixes: ["Sunny", "Smilin'", "Cheerful", "The Bright"],
            trait: "Charisma",
            taglines: ["A smile that closes the deal.",
                       "Warmth that lights up the polls."],
            verdicts: ["\"Great smile. People love this smile, frankly.\"",
                       "\"Such a likable face. Everybody says it. Tremendous charm.\""]
        ),
        Style(
            prefixes: ["Steady", "Cool-Hand", "The Sharp", "Ice-Cold"],
            trait: "Composure",
            taglines: ["Calm, sharp, and always in control.",
                       "Never rattled. Always ready."],
            verdicts: ["\"Very steady. Smart. A sharp cookie, this one.\"",
                       "\"Cool under pressure. The best people are calm like this.\""]
        ),
        Style(
            prefixes: ["Iron", "Tough", "The Mighty", "Rock-Solid"],
            trait: "Toughness",
            taglines: ["Built strong — impossible to push around.",
                       "The toughest in the room, hands down."],
            verdicts: ["\"Strong. Very strong. Tough as they come, believe me.\"",
                       "\"A real fighter's face. Nobody pushes this one around.\""]
        ),
        Style(
            prefixes: ["Classy", "The Distinguished", "Five-Star", "The Elegant"],
            trait: "Class",
            taglines: ["Old-school class, top to bottom.",
                       "Pure elegance — first-class all the way."],
            verdicts: ["\"Very classy. Top of the line. A first-class look.\"",
                       "\"Distinguished. Like a five-star resort, frankly the best.\""]
        )
    ]

    /// Suffix variants used to format the final nickname with the user's name.
    private let suffixVariants: [(String) -> String] = [
        { name in "\(name)" },
        { name in "\(name) the Great" },
        { name in "\(name), the Best" }
    ]

    func generate(from metrics: FaceMetrics, name: String) -> NicknameResult {
        var rng = SeededGenerator(seed: metrics.seed ^ nameSeed(name))

        let traits = computeTraits(metrics: metrics, rng: &rng)
        let dominant = traits.max { $0.value < $1.value } ?? traits[0]
        let style = styles.first { $0.trait == dominant.name } ?? styles[0]

        let prefix = style.prefixes.randomElement(using: &rng) ?? style.prefixes[0]
        let display = displayName(name)
        let suffix = suffixVariants.randomElement(using: &rng) ?? suffixVariants[0]
        let nickname = "\(prefix) \(suffix(display))"

        let tagline = style.taglines.randomElement(using: &rng) ?? style.taglines[0]
        let verdict = style.verdicts.randomElement(using: &rng) ?? style.verdicts[0]
        let confidence = 78 + Int(rng.next() % 21) // 78...98, always confident

        return NicknameResult(
            nickname: nickname,
            tagline: tagline,
            verdict: verdict,
            confidence: confidence,
            traits: traits.sorted { $0.value > $1.value },
            dominantTrait: dominant.name
        )
    }

    // MARK: - Trait computation

    private func computeTraits(metrics: FaceMetrics, rng: inout SeededGenerator) -> [TraitScore] {
        func score(_ base: Double, jitter: Int = 14) -> Int {
            let noise = Double(Int(rng.next() % UInt64(jitter * 2 + 1)) - jitter)
            return min(99, max(42, Int(base * 100) + Int(noise)))
        }

        let starPower = (metrics.faceFillRatio * 0.5) + (metrics.captureQuality * 0.5)
        let energy = (metrics.eyeOpenness * 0.55) + (abs(metrics.roll) * 1.4).clamped(to: 0...0.45)
        let charisma = (metrics.smileScore * 0.7) + (metrics.brightness * 0.3)
        let composure = (1.0 - abs(metrics.roll) * 1.2).clamped(to: 0...1) * 0.6 + metrics.symmetry * 0.4
        let toughness = (1.0 - metrics.smileScore * 0.5) * 0.5 + (1.0 - metrics.eyeOpenness * 0.4) * 0.5
        let classScore = (metrics.symmetry * 0.5) + (metrics.captureQuality * 0.3) + (metrics.brightness * 0.2)

        return [
            TraitScore(name: "Star Power", value: score(starPower), icon: "star.fill"),
            TraitScore(name: "Energy", value: score(energy), icon: "bolt.fill"),
            TraitScore(name: "Charisma", value: score(charisma), icon: "face.smiling.fill"),
            TraitScore(name: "Composure", value: score(composure), icon: "brain.head.profile"),
            TraitScore(name: "Toughness", value: score(toughness), icon: "shield.fill"),
            TraitScore(name: "Class", value: score(classScore), icon: "crown.fill")
        ]
    }

    // MARK: - Name helpers

    private func displayName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let first = trimmed.split(separator: " ").first.map(String.init) ?? trimmed
        return first.isEmpty ? "Champ" : first.capitalized
    }

    private func nameSeed(_ name: String) -> UInt64 {
        var hasher = Hasher()
        hasher.combine(name.lowercased())
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(range.upperBound, Swift.max(range.lowerBound, self))
    }
}
