import Foundation

struct VerbDataService {
    static func loadVerbs() -> [Verb] {
        guard let url = Bundle.main.url(forResource: "verbs", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let verbs = try? JSONDecoder().decode([Verb].self, from: data) else {
            return []
        }
        return verbs
    }

    static func generateCards(
        from verbs: [Verb],
        tenses: Set<Tense>,
        count: Int,
        masteryData: [String: [String: VerbMastery]] = [:]
    ) -> [PracticeCard] {
        var weightedCards: [(card: PracticeCard, weight: Double)] = []

        for verb in verbs {
            for tense in tenses {
                let pronouns = verb.availablePronouns(for: tense)
                for pronoun in pronouns {
                    guard let answer = verb.conjugation(tense: tense, pronoun: pronoun) else { continue }
                    let card = PracticeCard(
                        verb: verb,
                        tense: tense,
                        pronoun: pronoun,
                        correctAnswer: answer
                    )
                    let mastery = masteryData[verb.id]?[tense.rawValue]
                    let weight = Self.weight(for: mastery)
                    weightedCards.append((card, weight))
                }
            }
        }

        return weightedSample(from: weightedCards, count: count)
    }

    private static func weight(for mastery: VerbMastery?) -> Double {
        guard let mastery = mastery else { return 2.0 }
        switch mastery.masteryLevel {
        case .new: return 2.0
        case .struggling: return 3.0
        case .learning: return 1.5
        case .mastered: return 0.5
        }
    }

    private static func weightedSample(
        from items: [(card: PracticeCard, weight: Double)],
        count: Int
    ) -> [PracticeCard] {
        guard !items.isEmpty else { return [] }
        var selected: [PracticeCard] = []
        var remaining = items

        for _ in 0..<min(count, items.count) {
            let remainingWeight = remaining.reduce(0) { $0 + $1.weight }
            guard remainingWeight > 0 else { break }
            var random = Double.random(in: 0..<remainingWeight)
            var pickedIndex = 0
            for (i, item) in remaining.enumerated() {
                random -= item.weight
                if random <= 0 {
                    pickedIndex = i
                    break
                }
            }
            selected.append(remaining[pickedIndex].card)
            remaining.remove(at: pickedIndex)
        }

        return selected
    }
}
