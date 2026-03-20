import SwiftUI

struct QuizResultView: View {
    let result: QuizResult
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: result.accuracy >= 0.7 ? "star.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(result.accuracy >= 0.7 ? Color("EcuadorYellow") : Color("EcuadorBlue"))

                    Text("Quiz Complete!")
                        .font(.title.bold())
                        .foregroundStyle(Color("EcuadorBlue"))

                    Text("\(result.score) points")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Stats grid
                HStack(spacing: 0) {
                    statBox(title: "Correct", value: "\(result.correctAnswers)/\(result.totalQuestions)", color: Color("EcuadorBlue"))
                    Divider().frame(height: 50)
                    statBox(title: "Accuracy", value: "\(Int(result.accuracy * 100))%", color: Color.orange)
                    Divider().frame(height: 50)
                    statBox(title: "Best Streak", value: "\(result.longestStreak)", color: Color("EcuadorRed"))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal)

                // Tense breakdown
                if !result.tenseBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("By Tense")
                            .font(.headline.bold())
                            .padding(.horizontal)

                        ForEach(result.tenseBreakdown.sorted(by: { $0.key < $1.key }), id: \.key) { tense, score in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(tense)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(score.correct)/\(score.total)")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(score.accuracy >= 0.7 ? Color("EcuadorBlue") : Color("EcuadorRed"))
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                                        Capsule()
                                            .fill(score.accuracy >= 0.7 ? Color("EcuadorBlue") : Color("EcuadorRed"))
                                            .frame(width: geo.size.width * score.accuracy, height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal)
                }

                // Actions
                Button {
                    onDismiss()
                } label: {
                    Text("Try Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
        }
    }

    private func statBox(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
