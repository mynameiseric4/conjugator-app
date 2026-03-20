import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: FlagStripeHeader("Practice")) {
                    NavigationLink {
                        TenseSelectionView()
                    } label: {
                        HStack {
                            Label {
                                Text("Tenses")
                            } icon: {
                                Image(systemName: "list.bullet.clipboard")
                                    .foregroundStyle(Color("EcuadorBlue"))
                            }
                            Spacer()
                            Text("\(appState.activeTenses.count) selected")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(header: FlagStripeHeader("Reference")) {
                    NavigationLink {
                        TenseGuideView()
                    } label: {
                        Label {
                            Text("Tense Guide")
                        } icon: {
                            Image(systemName: "books.vertical")
                                .foregroundStyle(Color("EcuadorBlue"))
                        }
                    }
                    NavigationLink {
                        IrregularFormsView()
                    } label: {
                        Label {
                            Text("Irregular Verbs")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color("EcuadorRed"))
                        }
                    }
                }

                Section(header: FlagStripeHeader("Progress")) {
                    NavigationLink {
                        StatsView()
                    } label: {
                        Label {
                            Text("Statistics")
                        } icon: {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(Color("EcuadorBlue"))
                        }
                    }

                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Color("EcuadorYellow"))
                        Text("Daily Streak")
                        Spacer()
                        Text("\(appState.currentDailyStreak) day\(appState.currentDailyStreak == 1 ? "" : "s")")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "percent")
                            .foregroundStyle(Color("EcuadorBlue"))
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

private struct FlagStripeHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 0) {
                Color("EcuadorYellow")
                Color("EcuadorBlue")
                Color("EcuadorRed")
            }
            .frame(width: 3, height: 18)
            .clipShape(Capsule())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(nil)
        }
    }
}
