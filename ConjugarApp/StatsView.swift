import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            Section("Overview") {
                StatRow(label: "Total Practiced", value: "\(appState.totalAttempted)")
                StatRow(label: "Correct Answers", value: "\(appState.totalCorrect)")
                StatRow(label: "Overall Accuracy", value: formatPercent(appState.overallAccuracy))
                StatRow(label: "Daily Streak", value: "\(appState.currentDailyStreak) day\(appState.currentDailyStreak == 1 ? "" : "s")")
            }

            Section("Mastery Breakdown") {
                let dist = appState.masteryDistribution
                MasteryRow(level: .mastered, count: dist[.mastered] ?? 0)
                MasteryRow(level: .learning, count: dist[.learning] ?? 0)
                MasteryRow(level: .struggling, count: dist[.struggling] ?? 0)
                MasteryRow(level: .new, count: dist[.new] ?? 0)
            }

            if !appState.quizHistory.isEmpty {
                Section("Recent Quizzes") {
                    ForEach(appState.quizHistory.prefix(10)) { result in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(result.correctAnswers)/\(result.totalQuestions) correct")
                                    .font(.headline)
                                Text(result.date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(result.score) pts")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Statistics")
    }

    private func formatPercent(_ value: Double) -> String {
        "\(Int(value * 100))%"
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

private struct MasteryRow: View {
    let level: MasteryLevel
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: level.icon)
                .foregroundStyle(level.color)
                .frame(width: 24)
            Text(level.rawValue)
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
    }
}
