import SwiftUI

enum AppTab: Hashable {
    case practice, quiz, vocabulary, settings
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: AppTab = .practice
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        TabView(selection: $selectedTab) {
            PracticeHubView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Practice", systemImage: "rectangle.on.rectangle.angled")
                }
                .tag(AppTab.practice)
                .badge(appState.dueCardCount)

            QuizView()
                .tabItem {
                    Label("Quiz", systemImage: "timer")
                }
                .tag(AppTab.quiz)

            VocabularyView()
                .tabItem {
                    Label("Vocabulary", systemImage: "book")
                }
                .tag(AppTab.vocabulary)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )) {
            OnboardingView(isPresented: Binding(
                get: { !hasCompletedOnboarding },
                set: { if !$0 { hasCompletedOnboarding = true } }
            ))
        }
    }
}
