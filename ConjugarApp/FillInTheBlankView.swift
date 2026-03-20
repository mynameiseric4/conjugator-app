import SwiftUI

struct FillInTheBlankView: View {
    let tenses: Set<Tense>
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var advanceTask: Task<Void, Never>? = nil

    private static let sessionLength = 15

    private var keyboardRows: [[String]] {
        [
            ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
            ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
            ["z", "x", "c", "v", "b", "n", "m"],
            ["á", "é", "í", "ó", "ú", "ñ", "ü"]
        ]
    }

    private let accentedKeys: Set<String> = ["á", "é", "í", "ó", "ú", "ñ", "ü"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if appState.fillCards.isEmpty {
                    ContentUnavailableView("No Cards", systemImage: "text.cursor",
                                           description: Text("No verbs available for the selected tenses."))
                } else if appState.fillCurrentIndex >= appState.fillCards.count {
                    completionView
                } else {
                    cardView
                }
            }
            .navigationTitle("Fill in the Blank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { startOrResumeSession() }
        .onDisappear { advanceTask?.cancel() }
    }

    // MARK: - Session Management

    private func startOrResumeSession() {
        if appState.fillCards.isEmpty || appState.fillSessionTenses != tenses {
            appState.fillCards = generateFillCards()
            appState.fillCurrentIndex = 0
            appState.fillUserInput = ""
            appState.fillAnswerState = .unanswered
            appState.fillSessionTenses = tenses
        }
    }

    // MARK: - Card View

    private var cardView: some View {
        let card = appState.fillCards[appState.fillCurrentIndex]
        return VStack(spacing: 0) {
            ProgressView(value: Double(appState.fillCurrentIndex), total: Double(appState.fillCards.count))
                .tint(Color("EcuadorYellow"))
                .frame(height: 6)
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 20) {
                    // Tense badge
                    Text(card.tense.shortName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("EcuadorYellow"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color("EcuadorYellow").opacity(0.2))
                        .clipShape(Capsule())

                    // Ecuador flag stripe divider
                    HStack(spacing: 0) {
                        Color("EcuadorYellow").frame(height: 3)
                        Color("EcuadorBlue").frame(height: 3)
                        Color("EcuadorRed").frame(height: 3)
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 60)

                    if card.isSentenceCard {
                        sentenceCardContent(card: card)
                    } else {
                        promptCardContent(card: card)
                    }

                    answerSection(card: card)
                }
                .padding()
            }

            onScreenKeyboard(card: card)
        }
    }

    private func sentenceCardContent(card: FillCard) -> some View {
        VStack(spacing: 12) {
            Text(displayedSentence(card: card))
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Text("\(card.verb.infinitive) — \(card.pronoun.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !card.translationHint.isEmpty {
                Text(card.translationHint)
                    .font(.subheadline.italic())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func promptCardContent(card: FillCard) -> some View {
        VStack(spacing: 8) {
            Text("Conjugate")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(card.verb.infinitive) (\(card.verb.translation))")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("in \(card.tense.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("for \(card.pronoun.rawValue)")
                .font(.headline)
                .foregroundStyle(Color("EcuadorBlue"))
        }
        .multilineTextAlignment(.center)
    }

    private func answerSection(card: FillCard) -> some View {
        VStack(spacing: 12) {
            // Answer display
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(fieldBorderColor, lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(fieldBackground))
                Text(appState.fillUserInput.isEmpty ? "Type conjugation…" : appState.fillUserInput)
                    .font(.body)
                    .foregroundStyle(appState.fillUserInput.isEmpty ? .secondary : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .frame(height: 38)
            .padding(.horizontal, 40)

            if appState.fillAnswerState == .incorrect {
                VStack(spacing: 8) {
                    Text(card.correctForm)
                        .font(.title2.bold())
                        .foregroundStyle(Color("EcuadorBlue"))

                    Button("Continue") { advance() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("EcuadorBlue"))
                }
            }
        }
    }

    private var fieldBackground: Color {
        switch appState.fillAnswerState {
        case .unanswered: return Color(.systemBackground)
        case .correct:    return Color.green.opacity(0.15)
        case .incorrect:  return Color.red.opacity(0.12)
        }
    }

    private var fieldBorderColor: Color {
        switch appState.fillAnswerState {
        case .unanswered: return Color.secondary.opacity(0.4)
        case .correct:    return Color.green
        case .incorrect:  return Color("EcuadorRed")
        }
    }

    // MARK: - Custom Keyboard

    private func onScreenKeyboard(card: FillCard) -> some View {
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
                    if !appState.fillUserInput.isEmpty {
                        appState.fillUserInput.removeLast()
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
                .disabled(appState.fillAnswerState != .unanswered)

                Button {
                    appState.fillUserInput += " "
                } label: {
                    Text("space")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray5))
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .frame(height: 36)
                .disabled(appState.fillAnswerState != .unanswered)

                Button {
                    submitAnswer(card: card)
                } label: {
                    let canSubmit = !appState.fillUserInput.trimmingCharacters(in: .whitespaces).isEmpty
                    Text("submit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(canSubmit ? Color("EcuadorBlue") : Color("EcuadorBlue").opacity(0.4))
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .disabled(appState.fillUserInput.trimmingCharacters(in: .whitespaces).isEmpty || appState.fillAnswerState != .unanswered)
                .frame(height: 36)
            }
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private func keyButton(_ key: String) -> some View {
        let isAccented = accentedKeys.contains(key)
        return Button {
            if appState.fillAnswerState == .unanswered {
                appState.fillUserInput += key
            }
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
        .disabled(appState.fillAnswerState != .unanswered)
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color("EcuadorBlue"))
            Text("Session Complete!")
                .font(.title.bold())
            Text("You practiced \(appState.fillCards.count) cards.")
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .padding(.top)
        }
    }

    // MARK: - Answer Logic

    private func submitAnswer(card: FillCard) {
        let trimmed = appState.fillUserInput.trimmingCharacters(in: .whitespaces).lowercased()
        let isCorrect = trimmed == card.correctForm.lowercased()
        appState.fillAnswerState = isCorrect ? .correct : .incorrect
        appState.recordAnswer(verb: card.verb, tense: card.tense,
                              pronoun: card.pronoun, correct: isCorrect)
        if isCorrect {
            advanceTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                advance()
            }
        }
    }

    private func advance() {
        appState.fillUserInput = ""
        appState.fillAnswerState = .unanswered
        appState.fillCurrentIndex += 1
    }

    // MARK: - Sentence Display

    private func displayedSentence(card: FillCard) -> String {
        guard appState.fillAnswerState == .unanswered else {
            return card.displaySentence.replacingOccurrences(of: "____________", with: card.correctForm)
        }
        return card.displaySentence
    }

    // MARK: - Card Generation

    private func generateFillCards() -> [FillCard] {
        let verbPool = appState.allVerbs.shuffled()
        var result: [FillCard] = []

        for verb in verbPool {
            guard result.count < Self.sessionLength else { break }
            guard let tense = tenses.randomElement() else { continue }

            // Sentence path
            if let example = VerbExamples.sentences[verb.id],
               example.tense == tense {
                let matchedPronoun = Pronoun.allCases.first { pronoun in
                    if let form = verb.conjugation(tense: tense, pronoun: pronoun) {
                        return example.spanish.contains(form)
                    }
                    return false
                }
                if let pronoun = matchedPronoun,
                   let form = verb.conjugation(tense: tense, pronoun: pronoun) {
                    let blanked = example.spanish.replacingOccurrences(of: form, with: "____________")
                    result.append(FillCard(
                        verb: verb,
                        tense: tense,
                        pronoun: pronoun,
                        correctForm: form,
                        displaySentence: blanked,
                        translationHint: example.english,
                        isSentenceCard: true
                    ))
                    continue
                }
            }

            // Prompt path (fallback)
            let available = verb.availablePronouns(for: tense)
            guard let pronoun = available.randomElement(),
                  let form = verb.conjugation(tense: tense, pronoun: pronoun) else { continue }

            result.append(FillCard(
                verb: verb,
                tense: tense,
                pronoun: pronoun,
                correctForm: form,
                displaySentence: "Conjugate \(verb.infinitive) (\(verb.translation)) in \(tense.rawValue) for \(pronoun.rawValue)",
                translationHint: "",
                isSentenceCard: false
            ))
        }

        return result
    }
}
