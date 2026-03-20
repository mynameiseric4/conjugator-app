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

    /// Returns true if this verb has any irregular form in any tense.
    var hasIrregularForms: Bool {
        Tense.allCases.contains { isIrregularIn($0) }
    }

    /// Returns true if this verb has at least one form that differs from the
    /// regular pattern in the given tense.
    func isIrregularIn(_ tense: Tense) -> Bool {
        guard isIrregular else { return false }
        let expected = regularForms(for: tense)
        for (pronounKey, expectedForm) in expected {
            if conjugations[tense.rawValue]?[pronounKey] != expectedForm { return true }
        }
        return false
    }

    // MARK: - Regular form generation

    private enum VerbEnding { case ar, er, ir }

    private var verbEnding: VerbEnding? {
        if infinitive.hasSuffix("ar") { return .ar }
        if infinitive.hasSuffix("er") { return .er }
        if infinitive.hasSuffix("ir") { return .ir }
        return nil
    }

    private var regularStem: String { String(infinitive.dropLast(2)) }

    private var regularParticipio: String {
        switch verbEnding {
        case .ar: return regularStem + "ado"
        case .er, .ir: return regularStem + "ido"
        case nil: return participioPasado
        }
    }

    /// Generates the expected regular conjugation forms for a tense.
    /// Returns a dict of [Pronoun.rawValue: expectedForm] for comparison.
    private func regularForms(for tense: Tense) -> [String: String] {
        guard let ending = verbEnding else { return [:] }
        let s = regularStem
        let inf = infinitive
        let pp = regularParticipio

        switch tense {
        case .presente:
            switch ending {
            case .ar: return ["yo": s+"o","tú": s+"as","él/ella/Ud.": s+"a","nosotros": s+"amos","ellos/ellas/Uds.": s+"an"]
            case .er: return ["yo": s+"o","tú": s+"es","él/ella/Ud.": s+"e","nosotros": s+"emos","ellos/ellas/Uds.": s+"en"]
            case .ir: return ["yo": s+"o","tú": s+"es","él/ella/Ud.": s+"e","nosotros": s+"imos","ellos/ellas/Uds.": s+"en"]
            }
        case .preteritoIndefinido:
            switch ending {
            case .ar: return ["yo": s+"é","tú": s+"aste","él/ella/Ud.": s+"ó","nosotros": s+"amos","ellos/ellas/Uds.": s+"aron"]
            case .er, .ir: return ["yo": s+"í","tú": s+"iste","él/ella/Ud.": s+"ió","nosotros": s+"imos","ellos/ellas/Uds.": s+"ieron"]
            }
        case .preteritoImperfecto:
            switch ending {
            case .ar: return ["yo": s+"aba","tú": s+"abas","él/ella/Ud.": s+"aba","nosotros": s+"ábamos","ellos/ellas/Uds.": s+"aban"]
            case .er, .ir: return ["yo": s+"ía","tú": s+"ías","él/ella/Ud.": s+"ía","nosotros": s+"íamos","ellos/ellas/Uds.": s+"ían"]
            }
        case .futuroSimple:
            return ["yo": inf+"é","tú": inf+"ás","él/ella/Ud.": inf+"á","nosotros": inf+"emos","ellos/ellas/Uds.": inf+"án"]
        case .condicionalSimple:
            return ["yo": inf+"ía","tú": inf+"ías","él/ella/Ud.": inf+"ía","nosotros": inf+"íamos","ellos/ellas/Uds.": inf+"ían"]
        case .preteritoPerfecto:
            return ["yo": "he "+pp,"tú": "has "+pp,"él/ella/Ud.": "ha "+pp,"nosotros": "hemos "+pp,"ellos/ellas/Uds.": "han "+pp]
        case .preteritoPluscuamperfecto:
            return ["yo": "había "+pp,"tú": "habías "+pp,"él/ella/Ud.": "había "+pp,"nosotros": "habíamos "+pp,"ellos/ellas/Uds.": "habían "+pp]
        case .futuroPerfecto:
            return ["yo": "habré "+pp,"tú": "habrás "+pp,"él/ella/Ud.": "habrá "+pp,"nosotros": "habremos "+pp,"ellos/ellas/Uds.": "habrán "+pp]
        case .condicionalPerfecto:
            return ["yo": "habría "+pp,"tú": "habrías "+pp,"él/ella/Ud.": "habría "+pp,"nosotros": "habríamos "+pp,"ellos/ellas/Uds.": "habrían "+pp]
        case .presenteSubjuntivo:
            switch ending {
            case .ar: return ["yo": s+"e","tú": s+"es","él/ella/Ud.": s+"e","nosotros": s+"emos","ellos/ellas/Uds.": s+"en"]
            case .er, .ir: return ["yo": s+"a","tú": s+"as","él/ella/Ud.": s+"a","nosotros": s+"amos","ellos/ellas/Uds.": s+"an"]
            }
        case .imperfectoSubjuntivo:
            switch ending {
            case .ar: return ["yo": s+"ara","tú": s+"aras","él/ella/Ud.": s+"ara","nosotros": s+"áramos","ellos/ellas/Uds.": s+"aran"]
            case .er, .ir: return ["yo": s+"iera","tú": s+"ieras","él/ella/Ud.": s+"iera","nosotros": s+"iéramos","ellos/ellas/Uds.": s+"ieran"]
            }
        case .perfectoSubjuntivo:
            return ["yo": "haya "+pp,"tú": "hayas "+pp,"él/ella/Ud.": "haya "+pp,"nosotros": "hayamos "+pp,"ellos/ellas/Uds.": "hayan "+pp]
        case .pluscuamperfectoSubjuntivo:
            return ["yo": "hubiera "+pp,"tú": "hubieras "+pp,"él/ella/Ud.": "hubiera "+pp,"nosotros": "hubiéramos "+pp,"ellos/ellas/Uds.": "hubieran "+pp]
        case .imperativoAfirmativo:
            switch ending {
            case .ar: return ["tú": s+"a","él/ella/Ud.": s+"e","nosotros": s+"emos","ellos/ellas/Uds.": s+"en"]
            case .er: return ["tú": s+"e","él/ella/Ud.": s+"a","nosotros": s+"amos","ellos/ellas/Uds.": s+"an"]
            case .ir: return ["tú": s+"e","él/ella/Ud.": s+"a","nosotros": s+"amos","ellos/ellas/Uds.": s+"an"]
            }
        case .imperativoNegativo:
            switch ending {
            case .ar: return ["tú": s+"es","él/ella/Ud.": s+"e","nosotros": s+"emos","ellos/ellas/Uds.": s+"en"]
            case .er: return ["tú": s+"as","él/ella/Ud.": s+"a","nosotros": s+"amos","ellos/ellas/Uds.": s+"an"]
            case .ir: return ["tú": s+"as","él/ella/Ud.": s+"a","nosotros": s+"amos","ellos/ellas/Uds.": s+"an"]
            }
        }
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

// MARK: - Fill Answer State

enum FillAnswerState { case unanswered, correct, incorrect }

// MARK: - Fill Card

struct FillCard: Identifiable {
    let id = UUID()
    let verb: Verb
    let tense: Tense
    let pronoun: Pronoun
    let correctForm: String
    /// The sentence with the conjugated form replaced by blanks, OR a prompt string for fallback cards.
    let displaySentence: String
    /// English translation hint; empty string `""` for fallback (prompt) cards.
    let translationHint: String
    let isSentenceCard: Bool
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

// MARK: - SRS

struct SRSCard: Codable, Identifiable {
    var id: String
    var verbID: String
    var tenseRawValue: String
    var pronounRawValue: String
    var interval: Int
    var easeFactor: Double
    var repetitions: Int
    var dueDate: Date
    var lastReviewed: Date?
}

enum SRSRating { case again, good, easy }

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
        case .struggling: return Color("EcuadorRed")
        case .learning: return Color.orange
        case .mastered: return Color("EcuadorBlue")
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
