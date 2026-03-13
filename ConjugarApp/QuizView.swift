import SwiftUI
import Combine

struct QuizView: View {
    @EnvironmentObject var appState: AppState
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
                    quizSetupView
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
                .foregroundStyle(.blue)

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
        VStack(spacing: 16) {
            // Progress bar
            ProgressView(value: Double(appState.quizIndex), total: Double(appState.quizDeck.count))
                .padding(.horizontal)

            HStack {
                Text("Question \(appState.quizIndex + 1) of \(appState.quizDeck.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(appState.quizStreak)")
                        .font(.subheadline.bold())
                }
            }
            .padding(.horizontal)

            // Timer bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                    Rectangle()
                        .fill(timerColor)
                        .frame(width: geo.size.width * (appState.quizTimeRemaining / timePerQuestion))
                        .animation(.linear(duration: 0.1), value: appState.quizTimeRemaining)
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
            .padding(.horizontal)

            Spacer()

            if appState.quizIndex < appState.quizDeck.count {
                let card = appState.quizDeck[appState.quizIndex]
                promptView(card: card)
            }

            Spacer()

            // Score
            Text("Score: \(appState.quizScore)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }

    private func promptView(card: PracticeCard) -> some View {
        VStack(spacing: 20) {
            Text(card.tense.shortName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Text(card.verb.infinitive)
                .font(.title.bold())

            Text(card.verb.translation)
                .font(.body)
                .foregroundStyle(.secondary)

            Text(card.pronoun.rawValue)
                .font(.title2)

            if showFeedback {
                feedbackView(card: card)
            } else {
                answerInput(card: card)
            }
        }
    }

    private func answerInput(card: PracticeCard) -> some View {
        VStack(spacing: 8) {
            // Answer display
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
                Text(answer.isEmpty ? "Type conjugation..." : answer)
                    .font(.title3)
                    .foregroundStyle(answer.isEmpty ? .secondary : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .frame(height: 44)
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
                HStack(spacing: 4) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            answer += key
                        } label: {
                            Text(key)
                                .font(.system(size: 18, weight: .medium))
                                .frame(minWidth: 28, minHeight: 36)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            // Bottom row: space, backspace, submit
            HStack(spacing: 8) {
                Button {
                    answer += " "
                } label: {
                    Text("space")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.bordered)

                Button {
                    if !answer.isEmpty {
                        answer.removeLast()
                    }
                } label: {
                    Image(systemName: "delete.backward")
                        .font(.system(size: 16))
                        .frame(minWidth: 50, minHeight: 36)
                }
                .buttonStyle(.bordered)

                Button {
                    submitAnswer()
                } label: {
                    Text("Submit")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(minWidth: 70, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .disabled(answer.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 4)
    }

    private func feedbackView(card: PracticeCard) -> some View {
        VStack(spacing: 8) {
            Image(systemName: lastAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(lastAnswerCorrect ? .green : .red)

            if !lastAnswerCorrect {
                Text(card.correctAnswer)
                    .font(.title2.bold())
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Timer

    private var timerColor: Color {
        let ratio = appState.quizTimeRemaining / timePerQuestion
        if ratio > 0.5 { return .green }
        if ratio > 0.25 { return .yellow }
        return .red
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
        if appState.quizComplete {
            stopTimer()
            quizResult = appState.finishQuiz()
        } else {
            startTimer()
        }
    }
}
