import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            FlashcardView()
                .tabItem {
                    Label("Practice", systemImage: "rectangle.on.rectangle.angled")
                }

            QuizView()
                .tabItem {
                    Label("Quiz", systemImage: "timer")
                }

            VocabularyView()
                .tabItem {
                    Label("Vocabulary", systemImage: "book")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
