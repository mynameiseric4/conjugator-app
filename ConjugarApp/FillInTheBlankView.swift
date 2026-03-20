import SwiftUI

struct FillInTheBlankView: View {
    let tenses: Set<Tense>
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var cards: [FillCard] = []
    @State private var currentIndex = 0
    @State private var userInput = ""
    @State private var answerState: AnswerState = .unanswered
    @FocusState private var fieldFocused: Bool

    private static let warmCream = Color(red: 1.0, green: 0.988, blue: 0.941)
    private static let sessionLength = 15

    enum AnswerState { case unanswered, correct, incorrect }

    var body: some View {
        NavigationStack {
            ZStack {
                Self.warmCream.ignoresSafeArea()

                if cards.isEmpty {
                    ContentUnavailableView("No Cards", systemImage: "text.cursor",
                                           description: Text("No verbs available for the selected tenses."))
                } else if currentIndex >= cards.count {
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
        .onAppear { cards = generateFillCards() }
    }

    // MARK: - Card View

    private var cardView: some View {
        let card = cards[currentIndex]
        return VStack(spacing: 0) {
            ProgressView(value: Double(currentIndex), total: Double(cards.count))
                .tint(Color("EcuadorYellow"))
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

            // Accent toolbar
            accentToolbar
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
            HStack(spacing: 8) {
                TextField("Type conjugation…", text: $userInput)
                    .focused($fieldFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(fieldBorderColor, lineWidth: 1.5)
                    )
                    .disabled(answerState != .unanswered)

                if answerState == .unanswered {
                    Button("Submit") { submitAnswer(card: card) }
                        .buttonStyle(.borderedProminent)
                        .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal, 4)

            if answerState == .incorrect {
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
        switch answerState {
        case .unanswered: return Color(.systemBackground)
        case .correct:    return Color.green.opacity(0.15)
        case .incorrect:  return Color.red.opacity(0.12)
        }
    }

    private var fieldBorderColor: Color {
        switch answerState {
        case .unanswered: return Color.secondary.opacity(0.4)
        case .correct:    return Color.green
        case .incorrect:  return Color("EcuadorRed")
        }
    }

    // MARK: - Accent Toolbar

    private var accentToolbar: some View {
        HStack(spacing: 0) {
            ForEach(["á", "é", "í", "ó", "ú", "ü", "ñ", "¿", "¡"], id: \.self) { char in
                Button(char) { userInput += char }
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .background(Color(.systemGray6))
        .disabled(answerState != .unanswered)
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color("EcuadorBlue"))
            Text("Session Complete!")
                .font(.title.bold())
            Text("You practiced \(cards.count) cards.")
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .padding(.top)
        }
    }

    // MARK: - Answer Logic

    private func submitAnswer(card: FillCard) {
        let trimmed = userInput.trimmingCharacters(in: .whitespaces).lowercased()
        let isCorrect = trimmed == card.correctForm.lowercased()
        answerState = isCorrect ? .correct : .incorrect
        appState.recordAnswer(verb: card.verb, tense: card.tense,
                              pronoun: card.pronoun, correct: isCorrect)
        if isCorrect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { advance() }
        }
    }

    private func advance() {
        userInput = ""
        answerState = .unanswered
        currentIndex += 1
        fieldFocused = true
    }

    // MARK: - Sentence Display

    private func displayedSentence(card: FillCard) -> String {
        guard answerState == .unanswered else {
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
