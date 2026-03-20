import SwiftUI
import WidgetKit

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

    // MARK: - SRS State
    @Published var srsCards: [String: SRSCard] = [:]

    @Published var recentPracticeDates: [Date] = []

    // MARK: - Fill-in-the-Blank Session (ephemeral — not persisted to disk)
    @Published var fillCards: [FillCard] = []
    @Published var fillCurrentIndex: Int = 0
    @Published var fillUserInput: String = ""
    @Published var fillAnswerState: FillAnswerState = .unanswered
    @Published var fillSessionTenses: Set<Tense> = []

    @Published var focusWeakSpots: Bool = false {
        didSet { localDefaults.set(focusWeakSpots, forKey: Keys.focusWeakSpots) }
    }

    var dueCards: [SRSCard] {
        let now = Date()
        return srsCards.values
            .filter { $0.dueDate <= now }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var dueCardCount: Int {
        let now = Date()
        return srsCards.values.filter { $0.dueDate <= now }.count
    }

    // MARK: - UserDefaults
    // widgetDefaults: shared with the widget extension — keep this small (4 integers only)
    private let widgetDefaults = UserDefaults(suiteName: "group.com.conjugar.practice") ?? .standard
    // localDefaults: main app only — heavy data (SRS cards, mastery, quiz history)
    private let localDefaults = UserDefaults.standard

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
        static let srsCards = "srs_cards"
        static let focusWeakSpots      = "focus_weak_spots"
        static let recentPracticeDates = "recent_practice_dates"
        static let flashcardTenses     = "flashcard_tenses"
        static let fillInTheBlankTenses = "fillintheblank_tenses"
    }

    // MARK: - Init

    init() {
        // Load active tenses
        if let saved = localDefaults.stringArray(forKey: Keys.activeTenses) {
            self.activeTenses = Set(saved.compactMap { Tense(rawValue: $0) })
        } else {
            self.activeTenses = [.presente]
        }

        // Load study list
        if let saved = localDefaults.stringArray(forKey: Keys.studyList) {
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
        localDefaults.set(Array(studyListVerbIDs), forKey: Keys.studyList)
    }

    // MARK: - Deck Generation

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

    func generateFlashcardDeck(tenses: Set<Tense>, count: Int = 20) {
        guard !tenses.isEmpty else { flashcardDeck = []; return }
        flashcardDeck = VerbDataService.generateCards(
            from: allVerbs,
            tenses: tenses,
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
        recordAnswer(verb: card.verb, tense: card.tense, pronoun: card.pronoun, correct: correct)
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
        recordAnswer(verb: card.verb, tense: card.tense, pronoun: card.pronoun, correct: correct)

        if correct {
            quizStreak += 1
            quizLongestStreak = max(quizLongestStreak, quizStreak)
            quizScore += calculatePoints(streak: quizStreak, timeRemaining: quizTimeRemaining, timeAllotted: quizTimeRemaining + 1)
        } else {
            quizStreak = 0
        }

        return correct
    }

    func advanceQuiz() {
        quizIndex += 1
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

    // MARK: - SRS Scheduling

    func reviewSRSCard(id: String, rating: SRSRating) {
        guard var card = srsCards[id] else { return }
        let now = Date()

        switch rating {
        case .again:
            card.repetitions = 0
            card.interval = 0
            card.easeFactor = max(1.3, card.easeFactor - 0.2)
            card.dueDate = now
        case .good:
            let newInterval: Int
            if card.repetitions == 0 { newInterval = 1 }
            else if card.repetitions == 1 { newInterval = 4 }
            else { newInterval = max(1, Int(Double(card.interval) * card.easeFactor)) }
            card.repetitions += 1
            card.interval = newInterval
            card.dueDate = Calendar.current.date(byAdding: .day, value: newInterval, to: now) ?? now
        case .easy:
            let baseInterval: Int
            if card.repetitions == 0 { baseInterval = 1 }
            else if card.repetitions == 1 { baseInterval = 4 }
            else { baseInterval = max(1, Int(Double(card.interval) * card.easeFactor)) }
            let newInterval = baseInterval + 1
            card.easeFactor = min(2.5, card.easeFactor + 0.1)
            card.repetitions += 1
            card.interval = newInterval
            card.dueDate = Calendar.current.date(byAdding: .day, value: newInterval, to: now) ?? now
        }

        card.lastReviewed = now
        srsCards[id] = card

        if let verb = allVerbs.first(where: { $0.id == card.verbID }),
           let tense = Tense(rawValue: card.tenseRawValue),
           let pronoun = Pronoun(rawValue: card.pronounRawValue) {
            recordAnswer(verb: verb, tense: tense, pronoun: pronoun, correct: rating != .again)
        }
    }

    // MARK: - Mastery Tracking

    func recordAnswer(verb: Verb, tense: Tense, pronoun: Pronoun? = nil, correct: Bool) {
        totalAttempted += 1
        if correct { totalCorrect += 1 }

        var verbData = verbMasteryData[verb.id] ?? [:]
        var mastery = verbData[tense.rawValue] ?? VerbMastery()
        mastery.totalCount += 1
        if correct { mastery.correctCount += 1 }
        mastery.lastPracticed = Date()
        verbData[tense.rawValue] = mastery
        verbMasteryData[verb.id] = verbData

        if let pronoun = pronoun {
            let srsKey = "\(verb.id)|\(tense.rawValue)|\(pronoun.rawValue)"
            if srsCards[srsKey] == nil {
                srsCards[srsKey] = SRSCard(
                    id: srsKey,
                    verbID: verb.id,
                    tenseRawValue: tense.rawValue,
                    pronounRawValue: pronoun.rawValue,
                    interval: 0,
                    easeFactor: 2.5,
                    repetitions: 0,
                    dueDate: Date(),
                    lastReviewed: nil
                )
            }
        }

        updateDailyStreak()
        save()
    }

    // MARK: - Daily Streak

    private func updateDailyStreak() {
        let calendar = Calendar.current
        if let last = lastPracticeDate {
            if calendar.isDateInToday(last) {
                // Already practiced today — no streak change
            } else if calendar.isDateInYesterday(last) {
                currentDailyStreak += 1
            } else {
                currentDailyStreak = 1
            }
        } else {
            currentDailyStreak = 1
        }
        lastPracticeDate = Date()

        let today = Date()
        if !recentPracticeDates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
            recentPracticeDates.append(today)
            if recentPracticeDates.count > 30 {
                recentPracticeDates = Array(recentPracticeDates.suffix(30))
            }
        }
    }

    // MARK: - Persistence

    func save() {
        // Heavy data — local app storage only, never read by the widget
        localDefaults.set(lastPracticeDate, forKey: Keys.lastPracticeDate)
        if let data = try? JSONEncoder().encode(verbMasteryData) {
            localDefaults.set(data, forKey: Keys.verbMastery)
        }
        if let data = try? JSONEncoder().encode(quizHistory) {
            localDefaults.set(data, forKey: Keys.quizHistory)
        }
        if let data = try? JSONEncoder().encode(srsCards) {
            localDefaults.set(data, forKey: Keys.srsCards)
        }
        localDefaults.set(recentPracticeDates.map { $0.timeIntervalSince1970 },
                          forKey: Keys.recentPracticeDates)
        writeDerivedWidgetData()
    }

    private func writeDerivedWidgetData() {
        // Only small scalar values go into the shared App Group suite
        let due = srsCards.values.filter { $0.dueDate <= Date() }.count
        widgetDefaults.set(due, forKey: "srs_due_count")
        widgetDefaults.set(totalCorrect, forKey: Keys.totalCorrect)
        widgetDefaults.set(totalAttempted, forKey: Keys.totalAttempted)
        widgetDefaults.set(currentDailyStreak, forKey: Keys.dailyStreak)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func saveActiveTenses() {
        localDefaults.set(activeTenses.map(\.rawValue), forKey: Keys.activeTenses)
    }

    private func loadPersistedData() {
        totalCorrect = widgetDefaults.integer(forKey: Keys.totalCorrect)
        totalAttempted = widgetDefaults.integer(forKey: Keys.totalAttempted)
        currentDailyStreak = widgetDefaults.integer(forKey: Keys.dailyStreak)
        lastPracticeDate = localDefaults.object(forKey: Keys.lastPracticeDate) as? Date

        if let data = localDefaults.data(forKey: Keys.verbMastery),
           let decoded = try? JSONDecoder().decode([String: [String: VerbMastery]].self, from: data) {
            verbMasteryData = decoded
        }
        if let data = localDefaults.data(forKey: Keys.quizHistory),
           let decoded = try? JSONDecoder().decode([QuizResult].self, from: data) {
            quizHistory = decoded
        }
        if let data = localDefaults.data(forKey: Keys.srsCards),
           let decoded = try? JSONDecoder().decode([String: SRSCard].self, from: data) {
            srsCards = decoded
        }
        focusWeakSpots = localDefaults.bool(forKey: Keys.focusWeakSpots)

        if let timestamps = localDefaults.array(forKey: Keys.recentPracticeDates) as? [Double] {
            recentPracticeDates = timestamps.map { Date(timeIntervalSince1970: $0) }
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
        srsCards = [:]
        recentPracticeDates = []
        focusWeakSpots = false
        localDefaults.removeObject(forKey: Keys.flashcardTenses)
        localDefaults.removeObject(forKey: Keys.fillInTheBlankTenses)
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

    var perTenseAccuracy: [(tense: Tense, correct: Int, total: Int, accuracy: Double)] {
        var tenseTotals: [Tense: (correct: Int, total: Int)] = [:]
        for (_, tenseData) in verbMasteryData {
            for (tenseRaw, mastery) in tenseData {
                guard let tense = Tense(rawValue: tenseRaw) else { continue }
                var current = tenseTotals[tense] ?? (correct: 0, total: 0)
                current.correct += mastery.correctCount
                current.total += mastery.totalCount
                tenseTotals[tense] = current
            }
        }
        return tenseTotals.compactMap { tense, counts in
            guard counts.total > 0 else { return nil }
            let accuracy = Double(counts.correct) / Double(counts.total)
            return (tense: tense, correct: counts.correct, total: counts.total, accuracy: accuracy)
        }.sorted { $0.accuracy < $1.accuracy }
    }
}
