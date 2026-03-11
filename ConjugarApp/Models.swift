import SwiftUI

// MARK: - Mood

enum Mood: String, Codable, CaseIterable, Identifiable {
    case indicative = "Indicativo"
    case subjunctive = "Subjuntivo"
    case imperative = "Imperativo"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var tenses: [Tense] {
        Tense.allCases.filter { $0.mood == self }
    }
}

// MARK: - Tense

enum Tense: String, Codable, CaseIterable, Identifiable {
    // Indicative
    case presente = "Presente"
    case preteritoIndefinido = "Pretérito Indefinido"
    case preteritoImperfecto = "Pretérito Imperfecto"
    case futuroSimple = "Futuro Simple"
    case condicionalSimple = "Condicional Simple"
    case preteritoPerfecto = "Pretérito Perfecto"
    case preteritoPluscuamperfecto = "Pretérito Pluscuamperfecto"
    case futuroPerfecto = "Futuro Perfecto"
    case condicionalPerfecto = "Condicional Perfecto"

    // Subjunctive
    case presenteSubjuntivo = "Presente de Subjuntivo"
    case imperfectoSubjuntivo = "Imperfecto de Subjuntivo"
    case perfectoSubjuntivo = "Pretérito Perfecto de Subjuntivo"
    case pluscuamperfectoSubjuntivo = "Pluscuamperfecto de Subjuntivo"

    // Imperative
    case imperativoAfirmativo = "Imperativo Afirmativo"
    case imperativoNegativo = "Imperativo Negativo"

    var id: String { rawValue }

    var mood: Mood {
        switch self {
        case .presente, .preteritoIndefinido, .preteritoImperfecto,
             .futuroSimple, .condicionalSimple, .preteritoPerfecto,
             .preteritoPluscuamperfecto, .futuroPerfecto, .condicionalPerfecto:
            return .indicative
        case .presenteSubjuntivo, .imperfectoSubjuntivo,
             .perfectoSubjuntivo, .pluscuamperfectoSubjuntivo:
            return .subjunctive
        case .imperativoAfirmativo, .imperativoNegativo:
            return .imperative
        }
    }

    var shortName: String {
        switch self {
        case .presente: return "Presente"
        case .preteritoIndefinido: return "Indefinido"
        case .preteritoImperfecto: return "Imperfecto"
        case .futuroSimple: return "Futuro"
        case .condicionalSimple: return "Condicional"
        case .preteritoPerfecto: return "Perfecto"
        case .preteritoPluscuamperfecto: return "Pluscuamperf."
        case .futuroPerfecto: return "Fut. Perfecto"
        case .condicionalPerfecto: return "Cond. Perfecto"
        case .presenteSubjuntivo: return "Pres. Subj."
        case .imperfectoSubjuntivo: return "Imp. Subj."
        case .perfectoSubjuntivo: return "Perf. Subj."
        case .pluscuamperfectoSubjuntivo: return "Plusc. Subj."
        case .imperativoAfirmativo: return "Imp. Afirm."
        case .imperativoNegativo: return "Imp. Neg."
        }
    }

    /// Key used in the verbs.json source data
    var jsonMoodKey: String {
        switch mood {
        case .indicative: return "indicativo"
        case .subjunctive: return "subjuntivo"
        case .imperative: return "imperativo"
        }
    }
}

// MARK: - Pronoun (Latin American Spanish - no vosotros)

enum Pronoun: String, Codable, CaseIterable, Identifiable {
    case yo = "yo"
    case tu = "tú"
    case el = "él/ella/Ud."
    case nosotros = "nosotros"
    case ellos = "ellos/ellas/Uds."

    var id: String { rawValue }

    /// Key used in the verbs.json source data
    var jsonKey: String {
        switch self {
        case .yo: return "yo"
        case .tu: return "tu"
        case .el: return "ud"
        case .nosotros: return "nosotros"
        case .ellos: return "uds"
        }
    }
}

// MARK: - Verb

struct Verb: Codable, Identifiable {
    let id: String
    let infinitive: String
    let translation: String
    let isIrregular: Bool
    let gerundio: String
    let participioPasado: String
    let conjugations: [String: [String: String]]
    // outer key: Tense.rawValue -> inner key: Pronoun.rawValue -> conjugated form

    func conjugation(tense: Tense, pronoun: Pronoun) -> String? {
        conjugations[tense.rawValue]?[pronoun.rawValue]
    }

    func availablePronouns(for tense: Tense) -> [Pronoun] {
        guard let tenseData = conjugations[tense.rawValue] else { return [] }
        return Pronoun.allCases.filter { tenseData[$0.rawValue] != nil }
    }
}

// MARK: - Practice Card

struct PracticeCard: Identifiable {
    let id = UUID()
    let verb: Verb
    let tense: Tense
    let pronoun: Pronoun
    let correctAnswer: String
}

// MARK: - Quiz Result

struct QuizResult: Identifiable, Codable {
    let id: UUID
    let date: Date
    let totalQuestions: Int
    let correctAnswers: Int
    let longestStreak: Int
    let score: Int
    let tenseBreakdown: [String: TenseScore]

    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
}

struct TenseScore: Codable {
    var correct: Int
    var total: Int

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }
}

// MARK: - Mastery

struct VerbMastery: Codable {
    var correctCount: Int = 0
    var totalCount: Int = 0
    var lastPracticed: Date?

    var masteryLevel: MasteryLevel {
        guard totalCount >= 3 else { return .new }
        let accuracy = Double(correctCount) / Double(totalCount)
        if accuracy >= 0.9 && totalCount >= 10 { return .mastered }
        if accuracy >= 0.7 { return .learning }
        return .struggling
    }
}

enum MasteryLevel: String, Codable {
    case new = "New"
    case struggling = "Struggling"
    case learning = "Learning"
    case mastered = "Mastered"

    var color: Color {
        switch self {
        case .new: return .secondary
        case .struggling: return .red
        case .learning: return .orange
        case .mastered: return .green
        }
    }

    var icon: String {
        switch self {
        case .new: return "circle"
        case .struggling: return "exclamationmark.triangle.fill"
        case .learning: return "chart.line.uptrend.xyaxis"
        case .mastered: return "checkmark.seal.fill"
        }
    }
}
