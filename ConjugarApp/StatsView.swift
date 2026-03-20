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

            Section("7-Day Activity") {
                SevenDayCalendarView(recentDates: appState.recentPracticeDates)
                    .padding(.vertical, 8)
            }

            Section("Mastery Breakdown") {
                let dist = appState.masteryDistribution
                MasteryRow(level: .mastered, count: dist[.mastered] ?? 0)
                MasteryRow(level: .learning, count: dist[.learning] ?? 0)
                MasteryRow(level: .struggling, count: dist[.struggling] ?? 0)
                MasteryRow(level: .new, count: dist[.new] ?? 0)
            }

            let byTense = appState.perTenseAccuracy
            Section("By Tense") {
                if byTense.isEmpty {
                    Text("Practice to see accuracy by tense.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(byTense, id: \.tense) { item in
                        TenseAccuracyRow(tense: item.tense, accuracy: item.accuracy)
                    }
                }
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

private struct TenseAccuracyRow: View {
    let tense: Tense
    let accuracy: Double

    var barColor: Color {
        if accuracy >= 0.8 { return Color("EcuadorBlue") }
        if accuracy >= 0.5 { return Color("EcuadorYellow") }
        return Color("EcuadorRed")
    }

    var textColor: Color {
        if accuracy >= 0.8 { return Color("EcuadorBlue") }
        if accuracy >= 0.5 { return Color.orange }
        return Color("EcuadorRed")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tense.shortName)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(accuracy * 100))%")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(textColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.gray.opacity(0.2))
                        .frame(height: 4)
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * accuracy, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 2)
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

private struct SevenDayCalendarView: View {
    let recentDates: [Date]

    private let calendar = Calendar.current
    private var lastSevenDays: [Date] {
        (0..<7).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: Date()))
        }
    }

    private func hasPractice(on day: Date) -> Bool {
        recentDates.contains { calendar.isDate($0, inSameDayAs: day) }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(lastSevenDays, id: \.self) { day in
                VStack(spacing: 4) {
                    Circle()
                        .fill(hasPractice(on: day) ? Color("EcuadorBlue") : Color.gray.opacity(0.25))
                        .frame(width: 28, height: 28)
                        .overlay(
                            hasPractice(on: day)
                                ? Image(systemName: "checkmark").font(.caption2.bold()).foregroundStyle(.white)
                                : nil
                        )
                    Text(dayLabel(day))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}
