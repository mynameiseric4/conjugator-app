import SwiftUI

struct VocabularyView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var filterMode: FilterMode = .all
    @State private var showVocabPractice = false

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case studyList = "Study List"
    }

    private func verbMasteryLevel(for verb: Verb) -> MasteryLevel {
        guard let tenseData = appState.verbMasteryData[verb.id],
              !tenseData.isEmpty else { return .new }
        let levels = tenseData.values.map { $0.masteryLevel }
        if levels.allSatisfy({ $0 == .mastered }) { return .mastered }
        if levels.contains(.struggling) { return .struggling }
        if levels.contains(.learning) { return .learning }
        return .new
    }

    private var filteredVerbs: [Verb] {
        var verbs = appState.allVerbs

        if filterMode == .studyList {
            verbs = verbs.filter { appState.isInStudyList(verb: $0) }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            verbs = verbs.filter {
                $0.infinitive.lowercased().contains(query) ||
                $0.translation.lowercased().contains(query)
            }
        }

        return verbs
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $filterMode) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        if mode == .studyList {
                            Text("\(mode.rawValue) (\(appState.studyListVerbIDs.count))").tag(mode)
                        } else {
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if filterMode == .studyList && !appState.studyListVerbIDs.isEmpty {
                    Button {
                        showVocabPractice = true
                    } label: {
                        Label("Practice Vocabulary", systemImage: "rectangle.on.rectangle.angled")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                if filteredVerbs.isEmpty {
                    ContentUnavailableView {
                        Label(
                            filterMode == .studyList ? "Study List Empty" : "No Results",
                            systemImage: filterMode == .studyList ? "bookmark" : "magnifyingglass"
                        )
                    } description: {
                        Text(filterMode == .studyList
                             ? "Add verbs from the All tab to build your study list."
                             : "No verbs match your search.")
                    }
                } else {
                    List {
                        ForEach(filteredVerbs) { verb in
                            NavigationLink {
                                VerbDetailView(verb: verb)
                                    .environmentObject(appState)
                            } label: {
                                VerbRow(
                                    verb: verb,
                                    isInStudyList: appState.isInStudyList(verb: verb),
                                    masteryLevel: verbMasteryLevel(for: verb)
                                ) {
                                    appState.toggleStudyList(verb: verb)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Vocabulary")
            .searchable(text: $searchText, prompt: "Search verbs...")
            .fullScreenCover(isPresented: $showVocabPractice) {
                VocabPracticeView()
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Verb Row

private struct VerbRow: View {
    let verb: Verb
    let isInStudyList: Bool
    let masteryLevel: MasteryLevel
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(verb.infinitive)
                        .font(.body.weight(.semibold))
                    if verb.hasIrregularForms {
                        Text("irregular")
                            .font(.caption2)
                            .foregroundStyle(Color("EcuadorRed"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color("EcuadorRed").opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(verb.translation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 8)

            Spacer()

            Button {
                onToggle()
            } label: {
                Image(systemName: isInStudyList ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(isInStudyList ? Color("EcuadorBlue") : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(masteryLevel.color)
                .frame(width: 3)
        }
        .contentShape(Rectangle())
    }
}
