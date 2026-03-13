import SwiftUI

@MainActor
class AppState: ObservableObject {
    // MARK: - Tense Selection
    @Published var activeTenses: Set<Tense> {
        didSet { saveActiveTenses() }
    }

    // MARK: - Verb Data
    @Published var allVerbs: [Verb] = []

    // MARK: - Flashcard State
    @Published var flashcardDeck: [PracticeCard] = []
    @Published var flashcardIndex: Int = 0

    // MARK: - Quiz State
    @Published var quizDeck: [PracticeCard] = []
    @Published var quizIndex: Int = 0
    @Published var quizScore: Int = 0
    @Published var quizStreak: Int = 0
    @Published var quizLongestStreak: Int = 0
    @Published var quizTimeRemaining: Double = 0
    @Published var isQuizActive: Bool = false
    @Published var quizAnswers: [(card: PracticeCard, userAnswer: String, isCorrect: Bool)] = []

    // MARK: - Study List
    @Published var studyListVerbIDs: Set<String> {
        didSet { saveStudyList() }
    }

    var studyListVerbs: [Verb] {
        allVerbs.filter { studyListVerbIDs.contains($0.id) }
    }

    // MARK: - Persisted Stats
    @Published var totalCorrect: Int = 0
    @Published var totalAttempted: Int = 0
    @Published var currentDailyStreak: Int = 0
    @Published var lastPracticeDate: Date?
    @Published var verbMasteryData: [String: [String: VerbMastery]] = [:]
    @Published var quizHistory: [QuizResult] = []

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let activeTenses = "active_tenses"
        static let totalCorrect = "total_correct"
        static let totalAttempted = "total_attempted"
        static let dailyStreak = "daily_streak"
        static let lastPracticeDate = "last_practice_date"
        static let verbMastery = "verb_mastery"
        static let quizHistory = "quiz_history"
        static let studyList = "study_list"
    }

    // MARK: - Init

    init() {
        // Load active tenses
        if let saved = UserDefaults.standard.stringArray(forKey: Keys.activeTenses) {
            self.activeTenses = Set(saved.compactMap { Tense(rawValue: $0) })
        } else {
            self.activeTenses = [.presente]
        }

        // Load study list
        if let saved = UserDefaults.standard.stringArray(forKey: Keys.studyList) {
            self.studyListVerbIDs = Set(saved)
        } else {
            self.studyListVerbIDs = []
        }

        loadPersistedData()
        allVerbs = VerbDataService.loadVerbs()
    }

    // MARK: - Study List Actions

    func toggleStudyList(verb: Verb) {
        if studyListVerbIDs.contains(verb.id) {
            studyListVerbIDs.remove(verb.id)
        } else {
            studyListVerbIDs.insert(verb.id)
        }
    }

    func isInStudyList(verb: Verb) -> Bool {
        studyListVerbIDs.contains(verb.id)
    }

    private func saveStudyList() {
        UserDefaults.standard.set(Array(studyListVerbIDs), forKey: Keys.studyList)
    }

    // MARK: - Deck Generation

    func generateStudyListFlashcardDeck(count: Int = 20) {
        guard !activeTenses.isEmpty, !studyListVerbIDs.isEmpty else {
            flashcardDeck = []
            return
        }
        flashcardDeck = VerbDataService.generateCards(
            from: studyListVerbs,
            tenses: activeTenses,
            count: count,
            masteryData: verbMasteryData
        )
        flashcardIndex = 0
    }

    func generateFlashcardDeck(count: Int = 20) {
        guard !activeTenses.isEmpty else {
            flashcardDeck = []
            return
        }
        flashcardDeck = VerbDataService.generateCards(
            from: allVerbs,
            tenses: activeTenses,
            count: count,
            masteryData: verbMasteryData
        )
        flashcardIndex = 0
    }

    func generateQuizDeck(count: Int = 10) {
        guard !activeTenses.isEmpty else {
            quizDeck = []
            return
        }
        quizDeck = VerbDataService.generateCards(
            from: allVerbs,
            tenses: activeTenses,
            count: count,
            masteryData: verbMasteryData
        )
        quizIndex = 0
        quizScore = 0
        quizStreak = 0
        quizLongestStreak = 0
        quizAnswers = []
    }

    // MARK: - Flashcard Actions

    func markFlashcard(correct: Bool) {
        guard flashcardIndex < flashcardDeck.count else { return }
        let card = flashcardDeck[flashcardIndex]
        recordAnswer(verb: card.verb, tense: card.tense, correct: correct)
    }

    func nextFlashcard() {
        flashcardIndex += 1
    }

    var flashcardComplete: Bool {
        flashcardDeck.isEmpty || flashcardIndex >= flashcardDeck.count
    }

    // MARK: - Quiz Actions

    func submitQuizAnswer(_ answer: String) -> Bool {
        guard quizIndex < quizDeck.count else { return false }
        let card = quizDeck[quizIndex]
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correct = trimmed == card.correctAnswer.lowercased()

        quizAnswers.append((card: card, userAnswer: answer, isCorrect: correct))
        recordAnswer(verb: card.verb, tense: card.tense, correct: correct)

        if correct {
            quizStreak += 1
            quizLongestStreak = max(quizLongestStreak, quizStreak)
            quizScore += calculatePoints(streak: quizStreak, timeRemaining: quizTimeRemaining, timeAllotted: quizTimeRemaining + 1)
        } else {
            quizStreak = 0
        }

        quizIndex += 1
        return correct
    }

    var quizComplete: Bool {
        quizDeck.isEmpty || quizIndex >= quizDeck.count
    }

    func finishQuiz() -> QuizResult {
        var tenseBreakdown: [String: TenseScore] = [:]
        for answer in quizAnswers {
            let key = answer.card.tense.rawValue
            var score = tenseBreakdown[key] ?? TenseScore(correct: 0, total: 0)
            score.total += 1
            if answer.isCorrect { score.correct += 1 }
            tenseBreakdown[key] = score
        }

        let result = QuizResult(
            id: UUID(),
            date: Date(),
            totalQuestions: quizAnswers.count,
            correctAnswers: quizAnswers.filter(\.isCorrect).count,
            longestStreak: quizLongestStreak,
            score: quizScore,
            tenseBreakdown: tenseBreakdown
        )
        quizHistory.insert(result, at: 0)
        if quizHistory.count > 50 { quizHistory = Array(quizHistory.prefix(50)) }
        isQuizActive = false
        save()
        return result
    }

    // MARK: - Scoring

    func calculatePoints(streak: Int, timeRemaining: Double, timeAllotted: Double) -> Int {
        let streakMultiplier: Double
        switch streak {
        case 0...2: streakMultiplier = 1.0
        case 3...4: streakMultiplier = 1.5
        case 5...9: streakMultiplier = 2.0
        default: streakMultiplier = 3.0
        }
        let timeBonus = timeAllotted > 0 ? (timeRemaining / timeAllotted) * 5.0 : 0
        return Int((10.0 * streakMultiplier) + timeBonus)
    }

    // MARK: - Mastery Tracking

    private func recordAnswer(verb: Verb, tense: Tense, correct: Bool) {
        totalAttempted += 1
        if correct { totalCorrect += 1 }

        var verbData = verbMasteryData[verb.id] ?? [:]
        var mastery = verbData[tense.rawValue] ?? VerbMastery()
        mastery.totalCount += 1
        if correct { mastery.correctCount += 1 }
        mastery.lastPracticed = Date()
        verbData[tense.rawValue] = mastery
        verbMasteryData[verb.id] = verbData

        updateDailyStreak()
        save()
    }

    // MARK: - Daily Streak

    private func updateDailyStreak() {
        let calendar = Calendar.current
        if let last = lastPracticeDate {
            if calendar.isDateInToday(last) {
                // Already practiced today
            } else if calendar.isDateInYesterday(last) {
                currentDailyStreak += 1
            } else {
                currentDailyStreak = 1
            }
        } else {
            currentDailyStreak = 1
        }
        lastPracticeDate = Date()
    }

    // MARK: - Persistence

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(totalCorrect, forKey: Keys.totalCorrect)
        defaults.set(totalAttempted, forKey: Keys.totalAttempted)
        defaults.set(currentDailyStreak, forKey: Keys.dailyStreak)
        defaults.set(lastPracticeDate, forKey: Keys.lastPracticeDate)

        if let data = try? JSONEncoder().encode(verbMasteryData) {
            defaults.set(data, forKey: Keys.verbMastery)
        }
        if let data = try? JSONEncoder().encode(quizHistory) {
            defaults.set(data, forKey: Keys.quizHistory)
        }
    }

    private func saveActiveTenses() {
        let strings = activeTenses.map(\.rawValue)
        UserDefaults.standard.set(strings, forKey: Keys.activeTenses)
    }

    private func loadPersistedData() {
        let defaults = UserDefaults.standard
        totalCorrect = defaults.integer(forKey: Keys.totalCorrect)
        totalAttempted = defaults.integer(forKey: Keys.totalAttempted)
        currentDailyStreak = defaults.integer(forKey: Keys.dailyStreak)
        lastPracticeDate = defaults.object(forKey: Keys.lastPracticeDate) as? Date

        if let data = defaults.data(forKey: Keys.verbMastery),
           let decoded = try? JSONDecoder().decode([String: [String: VerbMastery]].self, from: data) {
            verbMasteryData = decoded
        }
        if let data = defaults.data(forKey: Keys.quizHistory),
           let decoded = try? JSONDecoder().decode([QuizResult].self, from: data) {
            quizHistory = decoded
        }
    }

    // MARK: - Reset

    func resetAllData() {
        totalCorrect = 0
        totalAttempted = 0
        currentDailyStreak = 0
        lastPracticeDate = nil
        verbMasteryData = [:]
        quizHistory = []
        save()
    }

    // MARK: - Stats Helpers

    var overallAccuracy: Double {
        guard totalAttempted > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAttempted)
    }

    var masteryDistribution: [MasteryLevel: Int] {
        var counts: [MasteryLevel: Int] = [.new: 0, .struggling: 0, .learning: 0, .mastered: 0]
        for (_, tenses) in verbMasteryData {
            for (_, mastery) in tenses {
                counts[mastery.masteryLevel, default: 0] += 1
            }
        }
        return counts
    }
}
