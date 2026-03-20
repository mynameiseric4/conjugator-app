import SwiftUI

struct ModeCardView: View {
    let mode: PracticeMode
    let stat: String
    let onTap: () -> Void

    @State private var isPressed = false

    private var title: String {
        switch mode {
        case .flashcards:     return "Flashcards"
        case .srsReview:      return "SRS Review"
        case .fillInTheBlank: return "Fill in the Blank"
        }
    }

    private var subtitle: String {
        switch mode {
        case .flashcards:     return "Flip cards, build memory"
        case .srsReview:      return "Scheduled review queue"
        case .fillInTheBlank: return "Type the conjugation in context"
        }
    }

    private var symbol: String {
        switch mode {
        case .flashcards:     return "rectangle.on.rectangle.angled"
        case .srsReview:      return "arrow.triangle.2.circlepath"
        case .fillInTheBlank: return "text.cursor"
        }
    }

    private var accentColor: Color {
        switch mode {
        case .flashcards:     return Color("EcuadorBlue")
        case .srsReview:      return Color("EcuadorRed")
        case .fillInTheBlank: return Color("EcuadorYellow")
        }
    }

    var body: some View {
        Button { onTap() } label: {
            HStack(spacing: 14) {
                // Ecuador flag stripe
                VStack(spacing: 0) {
                    Color("EcuadorYellow")
                    Color("EcuadorBlue")
                    Color("EcuadorRed")
                }
                .frame(width: 4, height: 56)
                .clipShape(Capsule())

                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                Text(stat)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(accentColor.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.2), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}
