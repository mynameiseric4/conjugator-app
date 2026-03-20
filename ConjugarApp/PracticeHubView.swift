import SwiftUI

enum PracticeMode: CaseIterable, Identifiable {
    case flashcards, srsReview, fillInTheBlank
    var id: Self { self }
}

struct PracticeHubView: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var appState: AppState

    @State private var showSetupSheet: PracticeMode? = nil
    @State private var navigateToFlashcards: Set<Tense>? = nil
    @State private var navigateToFillInTheBlank: Set<Tense>? = nil
    @State private var navigateToSRS = false

    private static let hubBackground = Color(red: 0.051, green: 0.106, blue: 0.243)

    private var weakTenses: Set<Tense>? {
        guard appState.focusWeakSpots else { return nil }
        let weak = Set(appState.perTenseAccuracy.filter { $0.accuracy < 0.70 }.map { $0.tense })
        return weak.isEmpty ? nil : weak
    }

    private var showWeakSpotFallbackNote: Bool {
        appState.focusWeakSpots && (weakTenses == nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Self.hubBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    statusBar
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    if showWeakSpotFallbackNote {
                        Text("Practice more to unlock weak-spot targeting.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        ModeCardView(mode: .flashcards, stat: flashcardStat) {
                            showSetupSheet = .flashcards
                        }
                        ModeCardView(mode: .srsReview, stat: "\(appState.dueCardCount) due") {
                            navigateToSRS = true
                        }
                        ModeCardView(mode: .fillInTheBlank, stat: fillStat) {
                            showSetupSheet = .fillInTheBlank
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Practice")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $navigateToSRS) {
                SRSReviewView()
            }
            .navigationDestination(item: $navigateToFlashcards) { tenses in
                FlashcardView(tenses: tenses)
            }
            .navigationDestination(item: $navigateToFillInTheBlank) { tenses in
                FillInTheBlankView(tenses: tenses)
            }
            .sheet(item: $showSetupSheet) { mode in
                SessionSetupSheet(
                    mode: mode,
                    weakTenses: weakTenses
                ) { tenses in
                    if mode == .flashcards {
                        navigateToFlashcards = tenses
                    } else {
                        navigateToFillInTheBlank = tenses
                    }
                }
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        VStack(spacing: 10) {
            Button { selectedTab = .settings } label: {
                HStack(spacing: 0) {
                    statCell(icon: "flame.fill",
                             value: "\(appState.currentDailyStreak)",
                             label: "streak",
                             color: Color("EcuadorYellow"))
                    statCell(icon: "arrow.triangle.2.circlepath",
                             value: "\(appState.dueCardCount)",
                             label: "due",
                             color: Color("EcuadorRed"))
                    statCell(icon: "checkmark.circle",
                             value: "\(Int(appState.overallAccuracy * 100))%",
                             label: "accuracy",
                             color: Color("EcuadorBlue"))
                }
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
            }
            .buttonStyle(.plain)

            Toggle(isOn: $appState.focusWeakSpots) {
                Label("Focus: Weak Spots", systemImage: "target")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .tint(Color("EcuadorRed"))
            .padding(.horizontal, 28)
        }
    }

    private func statCell(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundStyle(color)
                Text(value).font(.headline.bold()).foregroundStyle(.white)
            }
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats strings

    private var flashcardStat: String {
        let mastered = appState.masteryDistribution[.mastered] ?? 0
        let total = appState.allVerbs.count
        return "\(mastered)/\(total) mastered"
    }

    private var fillStat: String {
        let total = appState.totalAttempted
        return total == 0 ? "new" : "\(Int(appState.overallAccuracy * 100))% last"
    }
}
