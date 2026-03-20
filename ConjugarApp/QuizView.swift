import SwiftUI
import Combine

enum QuizMode { case typing, recognition }

struct QuizView: View {
    @EnvironmentObject var appState: AppState
    @State private var quizMode: QuizMode = .typing
    @State private var questionCount = 10
    @State private var timePerQuestion: Double = 15
    @State private var answer = ""
    @State private var showFeedback = false
    @State private var lastAnswerCorrect = false
    @State private var timerCancellable: AnyCancellable?
    @State private var quizResult: QuizResult?

    private let questionCounts = [10, 20]
    private let timeOptions: [Double] = [10, 15, 20, 30]

    var body: some View {
        NavigationStack {
            Group {
                if appState.activeTenses.isEmpty {
                    ContentUnavailableView(
                        "No Tenses Selected",
                        systemImage: "checklist",
                        description: Text("Go to Settings to select which tenses to practice.")
                    )
                } else if let result = quizResult {
                    QuizResultView(result: result) {
                        quizResult = nil
                    }
                } else if appState.isQuizActive {
                    quizActiveView
                } else {
                    VStack(spacing: 0) {
                        Picker("Quiz Mode", selection: $quizMode) {
                            Text("Typing").tag(QuizMode.typing)
                            Text("Recognition").tag(QuizMode.recognition)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top)

                        if quizMode == .recognition {
                            RecognitionQuizView()
                        } else {
                            quizSetupView
                        }
                    }
                }
            }
            .navigationTitle("Quiz")
        }
    }

    // MARK: - Setup

    private var quizSetupView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundStyle(Color("EcuadorBlue"))

            Text("Timed Quiz")
                .font(.title.bold())

            VStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Questions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("Questions", selection: $questionCount) {
                        ForEach(questionCounts, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Seconds per Question")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("Time", selection: $timePerQuestion) {
                        ForEach(timeOptions, id: \.self) { time in
                            Text("\(Int(time))s").tag(time)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal, 32)

            Button {
                startQuiz()
            } label: {
                Text("Start Quiz")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Active Quiz

    private var quizActiveView: some View {
        VStack(spacing: 8) {
            // Progress bar
            ProgressView(value: Double(appState.quizIndex), total: Double(appState.quizDeck.count))
                .tint(Color("EcuadorBlue")).animation(.linear, value: appState.quizIndex)
                .frame(height: 6)
                .padding(.horizontal)

            HStack {
                Text("Question \(appState.quizIndex + 1) of \(appState.quizDeck.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color("EcuadorYellow"))
                    Text("\(appState.quizStreak)")
                        .font(.caption.bold())
                }
            }
            .padding(.horizontal)

            // Timer bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                    let ratio = max(0, appState.quizTimeRemaining / timePerQuestion)
                    Rectangle()
                        .fill(timerColor)
                        .frame(width: geo.size.width * ratio)
                        .animation(.linear(duration: 0.1), value: appState.quizTimeRemaining)
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
            .padding(.horizontal)

            if appState.quizIndex < appState.quizDeck.count {
                let card = appState.quizDeck[appState.quizIndex]
                promptView(card: card)
            }

            Spacer(minLength: 0)

            // Score
            Text("Score: \(appState.quizScore)")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .padding(.bottom, 4)
        }
    }

    private func promptView(card: PracticeCard) -> some View {
        VStack(spacing: 8) {
            Text(card.tense.shortName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("EcuadorBlue"))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color("EcuadorBlue").opacity(0.12))
                .clipShape(Capsule())

            Text(card.verb.infinitive)
                .font(.largeTitle.bold())

            Text(card.verb.translation)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(card.pronoun.rawValue)
                .font(.title3.bold())
                .foregroundStyle(Color("EcuadorBlue"))

            if showFeedback {
                feedbackView(card: card)
            } else {
                answerInput(card: card)
            }
        }
    }

    private func answerInput(card: PracticeCard) -> some View {
        VStack(spacing: 6) {
            // Answer display
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
                Text(answer.isEmpty ? "Type conjugation..." : answer)
                    .font(.body)
                    .foregroundStyle(answer.isEmpty ? .secondary : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .frame(height: 38)
            .padding(.horizontal, 40)

            // On-screen keyboard
            onScreenKeyboard
        }
    }

    private var keyboardRows: [[String]] {
        [
            ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
            ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
            ["z", "x", "c", "v", "b", "n", "m"],
            ["á", "é", "í", "ó", "ú", "ñ", "ü"]
        ]
    }

    private var onScreenKeyboard: some View {
        VStack(spacing: 6) {
            ForEach(keyboardRows, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { key in
                        keyButton(key)
                    }
                }
            }

            // Bottom row: backspace, space, submit
            HStack(spacing: 5) {
                Button {
                    if !answer.isEmpty {
                        answer.removeLast()
                    }
                } label: {
                    Image(systemName: "delete.backward")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray3))
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .frame(height: 36)

                Button {
                    answer += " "
                } label: {
                    Text("space")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray5))
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .frame(height: 36)

                Button {
                    submitAnswer()
                } label: {
                    Text("submit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(answer.trimmingCharacters(in: .whitespaces).isEmpty ? Color("EcuadorBlue").opacity(0.4) : Color("EcuadorBlue"))
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty)
                .frame(height: 36)
            }
        }
        .padding(.horizontal, 3)
    }

    private let accentedKeys: Set<String> = ["á", "é", "í", "ó", "ú", "ñ", "ü"]

    private func keyButton(_ key: String) -> some View {
        let isAccented = accentedKeys.contains(key)
        return Button {
            answer += key
        } label: {
            Text(key)
                .font(.system(size: 16))
                .foregroundStyle(isAccented ? Color("EcuadorBlue") : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isAccented ? Color("EcuadorBlue").opacity(0.12) : Color(.systemGray5))
                .cornerRadius(5)
        }
        .buttonStyle(.plain)
        .frame(height: 36)
    }

    private func feedbackView(card: PracticeCard) -> some View {
        VStack(spacing: 8) {
            Image(systemName: lastAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(lastAnswerCorrect ? Color("EcuadorBlue") : Color("EcuadorRed"))

            if !lastAnswerCorrect {
                Text(card.correctAnswer)
                    .font(.title2.bold())
                    .foregroundStyle(Color.orange)
            }
        }
    }

    // MARK: - Timer

    private var timerColor: Color {
        let ratio = appState.quizTimeRemaining / timePerQuestion
        if ratio > 0.5 { return Color("EcuadorBlue") }
        if ratio > 0.25 { return Color("EcuadorYellow") }
        return Color("EcuadorRed")
    }

    private func startTimer() {
        appState.quizTimeRemaining = timePerQuestion
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if appState.quizTimeRemaining > 0 {
                    appState.quizTimeRemaining -= 0.1
                } else {
                    timeExpired()
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Actions

    private func startQuiz() {
        appState.generateQuizDeck(count: questionCount)
        appState.isQuizActive = true
        answer = ""
        showFeedback = false
        startTimer()
    }

    private func submitAnswer() {
        guard !showFeedback else { return }
        stopTimer()
        lastAnswerCorrect = appState.submitQuizAnswer(answer)
        showFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            advanceOrFinish()
        }
    }

    private func timeExpired() {
        guard !showFeedback else { return }
        stopTimer()
        lastAnswerCorrect = appState.submitQuizAnswer("")
        showFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            advanceOrFinish()
        }
    }

    private func advanceOrFinish() {
        showFeedback = false
        answer = ""
        appState.advanceQuiz()
        if appState.quizComplete {
            stopTimer()
            quizResult = appState.finishQuiz()
        } else {
            startTimer()
        }
    }
}
