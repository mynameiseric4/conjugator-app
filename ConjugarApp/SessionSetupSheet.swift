import SwiftUI

struct SessionSetupSheet: View {
    let mode: PracticeMode
    let weakTenses: Set<Tense>?
    let onStart: (Set<Tense>) -> Void

    @State private var selectedTenses: Set<Tense> = []
    @Environment(\.dismiss) private var dismiss

    /// The 8 simple tenses available for fill-in-the-blank.
    static let fillInTheBlankAllowed: Set<Tense> = [
        .presente, .preteritoIndefinido, .preteritoImperfecto,
        .futuroSimple, .condicionalSimple, .presenteSubjuntivo,
        .imperfectoSubjuntivo, .imperativoAfirmativo
    ]

    private var availableTenses: [Tense] {
        if mode == .fillInTheBlank {
            return Tense.allCases.filter { Self.fillInTheBlankAllowed.contains($0) }
        }
        return Tense.allCases
    }

    private var defaultsKey: String {
        mode == .flashcards ? "flashcard_tenses" : "fillintheblank_tenses"
    }

    /// When weak-spot mode is active, a tense is interactive only if it is in weakTenses.
    private func isEnabled(_ tense: Tense) -> Bool {
        guard let weak = weakTenses, !weak.isEmpty else { return true }
        return weak.contains(tense)
    }

    /// A tense appears checked only if it is in selectedTenses AND (no weak filter, or in weakTenses).
    private func isChecked(_ tense: Tense) -> Bool {
        guard selectedTenses.contains(tense) else { return false }
        if let weak = weakTenses, !weak.isEmpty { return weak.contains(tense) }
        return true
    }

    /// The set that will actually be passed to onStart.
    private var effectiveSelection: Set<Tense> {
        if let weak = weakTenses, !weak.isEmpty {
            let intersection = selectedTenses.intersection(weak)
            return intersection.isEmpty ? weak : intersection
        }
        return selectedTenses.isEmpty ? Set(availableTenses) : selectedTenses
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let weak = weakTenses, !weak.isEmpty {
                    HStack {
                        Image(systemName: "target")
                            .foregroundStyle(Color("EcuadorRed"))
                        Text("Weak-spot mode active")
                            .font(.caption.weight(.semibold))
                        Spacer()
                    }
                    .padding(12)
                    .background(Color("EcuadorRed").opacity(0.10))
                    .padding([.horizontal, .top], 12)
                }

                List {
                    Section("Select Tenses") {
                        ForEach(availableTenses) { tense in
                            Button {
                                guard isEnabled(tense) else { return }
                                if selectedTenses.contains(tense) {
                                    selectedTenses.remove(tense)
                                } else {
                                    selectedTenses.insert(tense)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: isChecked(tense) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isChecked(tense) ? Color("EcuadorBlue") : .secondary)
                                    Text(tense.rawValue)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .opacity(isEnabled(tense) ? 1.0 : 0.35)
                            }
                            .disabled(!isEnabled(tense))
                        }
                    }
                }
                .listStyle(.insetGrouped)

                Button {
                    UserDefaults.standard.set(
                        Array(selectedTenses).map(\.rawValue),
                        forKey: defaultsKey
                    )
                    onStart(effectiveSelection)
                    dismiss()
                } label: {
                    Text("Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(effectiveSelection.isEmpty)
                .padding()
            }
            .navigationTitle(mode == .flashcards ? "Flashcard Setup" : "Fill-in-the-Blank Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear { loadSelectedTenses() }
    }

    private func loadSelectedTenses() {
        if let saved = UserDefaults.standard.stringArray(forKey: defaultsKey) {
            selectedTenses = Set(saved.compactMap { Tense(rawValue: $0) })
        } else {
            // First use: seed from active_tenses
            if let savedActive = UserDefaults.standard.stringArray(forKey: "active_tenses") {
                let activeTenses = Set(savedActive.compactMap { Tense(rawValue: $0) })
                if mode == .fillInTheBlank {
                    let filtered = activeTenses.intersection(Self.fillInTheBlankAllowed)
                    selectedTenses = filtered.isEmpty ? Self.fillInTheBlankAllowed : filtered
                } else {
                    selectedTenses = activeTenses
                }
            } else {
                selectedTenses = mode == .fillInTheBlank
                    ? Self.fillInTheBlankAllowed
                    : [.presente]
            }
        }
    }
}
