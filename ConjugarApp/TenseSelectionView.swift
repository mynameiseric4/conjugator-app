import SwiftUI

struct TenseSelectionView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            ForEach(Mood.allCases) { mood in
                Section {
                    ForEach(mood.tenses) { tense in
                        Toggle(tense.rawValue, isOn: binding(for: tense))
                    }
                } header: {
                    HStack {
                        Text(mood.displayName)
                        Spacer()
                        Button(allSelected(mood) ? "Deselect All" : "Select All") {
                            toggleAll(mood)
                        }
                        .font(.caption)
                        .textCase(nil)
                    }
                }
            }
        }
        .navigationTitle("Tenses")
    }

    private func binding(for tense: Tense) -> Binding<Bool> {
        Binding(
            get: { appState.activeTenses.contains(tense) },
            set: { isOn in
                if isOn {
                    appState.activeTenses.insert(tense)
                } else {
                    appState.activeTenses.remove(tense)
                }
            }
        )
    }

    private func allSelected(_ mood: Mood) -> Bool {
        mood.tenses.allSatisfy { appState.activeTenses.contains($0) }
    }

    private func toggleAll(_ mood: Mood) {
        if allSelected(mood) {
            for tense in mood.tenses {
                appState.activeTenses.remove(tense)
            }
        } else {
            for tense in mood.tenses {
                appState.activeTenses.insert(tense)
            }
        }
    }
}
