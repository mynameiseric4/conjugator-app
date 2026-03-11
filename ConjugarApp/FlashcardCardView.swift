import SwiftUI

struct FlashcardCardView: View {
    let card: PracticeCard
    @Binding var isFlipped: Bool

    var body: some View {
        ZStack {
            // Back face (answer)
            cardBack
                .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)

            // Front face (prompt)
            cardFront
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)
        }
        .animation(.easeInOut(duration: 0.4), value: isFlipped)
        .onTapGesture {
            isFlipped.toggle()
        }
    }

    private var cardFront: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(card.tense.shortName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Text(card.verb.infinitive)
                .font(.largeTitle.bold())

            Text(card.verb.translation)
                .font(.title3)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.horizontal, 40)

            Text(card.pronoun.rawValue)
                .font(.title2)

            Spacer()

            Text("Tap to reveal")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private var cardBack: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(card.tense.shortName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Text(card.verb.infinitive)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(card.pronoun.rawValue)
                .font(.title3)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.horizontal, 40)

            Text(card.correctAnswer)
                .font(.largeTitle.bold())
                .foregroundStyle(.green)

            Spacer()

            Text("Swipe right = correct, left = incorrect")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.green.opacity(0.3), lineWidth: 1)
        )
    }
}
