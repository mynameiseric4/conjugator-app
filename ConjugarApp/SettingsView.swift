import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Practice") {
                    NavigationLink {
                        TenseSelectionView()
                    } label: {
                        HStack {
                            Text("Tenses")
                            Spacer()
                            Text("\(appState.activeTenses.count) selected")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Progress") {
                    NavigationLink("Statistics") {
                        StatsView()
                    }

                    HStack {
                        Text("Daily Streak")
                        Spacer()
                        Text("\(appState.currentDailyStreak) day\(appState.currentDailyStreak == 1 ? "" : "s")")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Accuracy")
                        Spacer()
                        Text("\(Int(appState.overallAccuracy * 100))%")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Reset All Progress", role: .destructive) {
                        showResetAlert = true
                    }
                }

                Section {
                    Text("Verb data: Fred Jehle / miko3k/verbos (CC-BY-NC-SA-3.0)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Progress", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    appState.resetAllData()
                }
            } message: {
                Text("This will erase all your scores, streaks, and mastery data. This cannot be undone.")
            }
        }
    }
}
