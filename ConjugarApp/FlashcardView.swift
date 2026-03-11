import SwiftUI

struct FlashcardView: View {
    @EnvironmentObject var appState: AppState
    @State private var isFlipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var cardOpacity: Double = 1.0

    var body: some View {
        NavigationStack {
            Group {
                if appState.activeTenses.isEmpty {
                    ContentUnavailableView(
                        "No Tenses Selected",
                        systemImage: "checklist",
                        description: Text("Go to Settings to select which tenses to practice.")
                    )
                } else if appState.flashcardComplete {
                    deckCompleteView
                } else {
                    cardView
                }
            }
            .navigationTitle("Practice")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        resetDeck()
                    } label: {
                        Image(systemName: "shuffle")
                    }
                    .disabled(appState.activeTenses.isEmpty)
                }
            }
            .onAppear {
                if appState.flashcardDeck.isEmpty {
                    resetDeck()
                }
            }
        }
    }

    private var cardView: some View {
        VStack(spacing: 20) {
            // Progress
            Text("\(appState.flashcardIndex + 1) / \(appState.flashcardDeck.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Card
            if appState.flashcardIndex < appState.flashcardDeck.count {
                let card = appState.flashcardDeck[appState.flashcardIndex]
                FlashcardCardView(card: card, isFlipped: $isFlipped)
                    .frame(height: 400)
                    .padding(.horizontal)
                    .offset(dragOffset)
                    .opacity(cardOpacity)
                    .gesture(swipeGesture)
                    .id(appState.flashcardIndex)
            }

            // Manual buttons
            if isFlipped {
                HStack(spacing: 40) {
                    Button {
                        dismissCard(correct: false)
                    } label: {
                        Label("Incorrect", systemImage: "xmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }

                    Button {
                        dismissCard(correct: true)
                    } label: {
                        Label("Correct", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var deckCompleteView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Deck Complete!")
                .font(.title.bold())

            Text("You've reviewed all \(appState.flashcardDeck.count) cards.")
                .foregroundStyle(.secondary)

            Button("Start New Deck") {
                resetDeck()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                let progress = abs(value.translation.width) / 150
                cardOpacity = 1 - min(progress * 0.5, 0.5)
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

        appState.markFlashcard(correct: correct)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            dragOffset = .zero
            cardOpacity = 1
            isFlipped = false
            appState.nextFlashcard()
        }
    }

    private func resetDeck() {
        isFlipped = false
        dragOffset = .zero
        cardOpacity = 1
        appState.generateFlashcardDeck()
    }
}
