import SwiftUI

struct VocabPracticeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var cards: [Verb] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var cardOpacity: Double = 1.0
    @State private var correctCount = 0
    @State private var incorrectCount = 0

    var body: some View {
        NavigationStack {
            Group {
                if cards.isEmpty {
                    ContentUnavailableView(
                        "No Words",
                        systemImage: "bookmark",
                        description: Text("Add words to your study list first.")
                    )
                } else if currentIndex >= cards.count {
                    completionView
                } else {
                    cardView
                }
            }
            .navigationTitle("Vocabulary Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            cards = appState.studyListVerbs.shuffled()
        }
    }

    // MARK: - Card View

    private var cardView: some View {
        VStack(spacing: 16) {
            // Progress bar + score badges
            VStack(spacing: 8) {
                ProgressView(value: Double(currentIndex), total: Double(cards.count))
                    .tint(Color("EcuadorBlue"))
                    .frame(height: 6)
                    .padding(.horizontal)

                HStack {
                    scoreBadge(count: incorrectCount, color: Color("EcuadorRed"), icon: "xmark")
                    Spacer()
                    Text("\(currentIndex + 1) / \(cards.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    scoreBadge(count: correctCount, color: Color("EcuadorBlue"), icon: "checkmark")
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 4)

            Spacer()

            vocabCard
                .frame(height: 380)
                .padding(.horizontal)
                .offset(dragOffset)
                .opacity(cardOpacity)
                .overlay(swipeOverlay)
                .gesture(swipeGesture)
                .id(currentIndex)

            Spacer()

            if isFlipped {
                HStack(spacing: 16) {
                    Button {
                        dismissCard(correct: false)
                    } label: {
                        Label("Didn't Know", systemImage: "xmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("EcuadorRed"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        dismissCard(correct: true)
                    } label: {
                        Label("Knew It", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color("EcuadorBlue"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text("Tap card to reveal • Swipe to answer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.spring(duration: 0.3), value: isFlipped)
    }

    // MARK: - Score Badge

    private func scoreBadge(count: Int, color: Color, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "\(icon).circle.fill")
                .font(.caption)
            Text("\(count)")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(count > 0 ? color : color.opacity(0.35))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(count > 0 ? color.opacity(0.12) : Color.clear)
        .clipShape(Capsule())
        .animation(.spring(duration: 0.25), value: count)
    }

    // MARK: - Swipe Color Overlay

    private var swipeOverlay: some View {
        let progress = dragOffset.width / 150
        return Group {
            if progress > 0.05 {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(min(Double(progress) * 0.35, 0.28)))
                    .overlay(alignment: .topLeading) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.green.opacity(min(Double(progress) * 1.5, 0.9)))
                            .padding(24)
                    }
            } else if progress < -0.05 {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(min(Double(-progress) * 0.35, 0.28)))
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.red.opacity(min(Double(-progress) * 1.5, 0.9)))
                            .padding(24)
                    }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Vocab Card

    private var vocabCard: some View {
        ZStack {
            // Back face (translation + example)
            VStack(spacing: 0) {
                // Header showing Spanish word
                ZStack(alignment: .bottom) {
                    Color("EcuadorBlue")
                    VStack(spacing: 6) {
                        Text(cards[currentIndex].infinitive)
                            .font(.title2.bold())
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.bottom, 16)
                    .padding(.horizontal, 20)
                }
                .frame(height: 80)

                // Flag stripe
                HStack(spacing: 0) {
                    Color("EcuadorYellow")
                    Color("EcuadorBlue")
                    Color("EcuadorRed")
                }
                .frame(height: 3)

                // Translation body
                VStack(spacing: 16) {
                    Spacer()

                    Text(cards[currentIndex].translation)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    if let example = cards[currentIndex].exampleSentence {
                        VStack(spacing: 4) {
                            Text(example.spanish)
                                .font(.subheadline.italic())
                                .multilineTextAlignment(.center)
                            Text(example.english)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color("EcuadorBlue").opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                    }

                    Spacer()
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
            .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 1 : 0)

            // Front face (Spanish word)
            VStack(spacing: 0) {
                // Blue header band
                ZStack {
                    Color("EcuadorBlue")
                    VStack(spacing: 6) {
                        Text(cards[currentIndex].infinitive)
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        if cards[currentIndex].hasIrregularForms {
                            Text("irregular")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("EcuadorYellow"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color("EcuadorYellow").opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxHeight: .infinity)

                // Flag stripe
                HStack(spacing: 0) {
                    Color("EcuadorYellow")
                    Color("EcuadorBlue")
                    Color("EcuadorRed")
                }
                .frame(height: 3)

                // Bottom hint
                HStack {
                    Image(systemName: "hand.tap")
                        .font(.caption)
                    Text("Tap to reveal")
                        .font(.caption)
                }
                .foregroundStyle(Color("EcuadorBlue").opacity(0.55))
                .padding(.vertical, 16)
            }
            .background(Color("EcuadorBlue"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color("EcuadorBlue").opacity(0.3), radius: 12, y: 6)
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .opacity(isFlipped ? 0 : 1)
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.75), value: isFlipped)
        .onTapGesture {
            isFlipped.toggle()
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color("EcuadorYellow"))

            VStack(spacing: 6) {
                Text("Practice Complete!")
                    .font(.title.bold())
                Text("You reviewed \(cards.count) words.")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                resultStat(count: correctCount, label: "Knew It", color: Color("EcuadorBlue"))
                resultStat(count: incorrectCount, label: "Didn't Know", color: Color("EcuadorRed"))
            }

            Button("Practice Again") {
                cards = appState.studyListVerbs.shuffled()
                currentIndex = 0
                correctCount = 0
                incorrectCount = 0
                isFlipped = false
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }

    private func resultStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 90)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Gestures & Actions

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                let progress = abs(value.translation.width) / 150
                cardOpacity = 1 - min(progress * 0.4, 0.4)
            }
            .onEnded { value in
                if value.translation.width > 100 {
                    dismissCard(correct: true)
                } else if value.translation.width < -100 {
                    dismissCard(correct: false)
                } else {
                    withAnimation(.spring()) {
                        dragOffset = .zero
                        cardOpacity = 1
                    }
                }
            }
    }

    private func dismissCard(correct: Bool) {
        let direction: CGFloat = correct ? 1 : -1
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: direction * 500, height: 0)
            cardOpacity = 0
        }

        if correct { correctCount += 1 } else { incorrectCount += 1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            dragOffset = .zero
            cardOpacity = 1
            isFlipped = false
            currentIndex += 1
        }
    }
}
