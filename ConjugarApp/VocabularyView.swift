import SwiftUI

struct VocabularyView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var filterMode: FilterMode = .all

    enum FilterMode: String, CaseIterable {
        case all = "All"
        case studyList = "Study List"
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

                if filterMode == .studyList && !appState.studyListVerbIDs.isEmpty && !appState.activeTenses.isEmpty {
                    Button {
                        appState.generateStudyListFlashcardDeck()
                    } label: {
                        Label("Practice Study List", systemImage: "rectangle.on.rectangle.angled")
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
                            VerbRow(verb: verb, isInStudyList: appState.isInStudyList(verb: verb)) {
                                appState.toggleStudyList(verb: verb)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Vocabulary")
            .searchable(text: $searchText, prompt: "Search verbs...")
        }
    }
}

// MARK: - Verb Row

private struct VerbRow: View {
    let verb: Verb
    let isInStudyList: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(verb.infinitive)
                        .font(.body.weight(.medium))
                    if verb.isIrregular {
                        Text("irregular")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(verb.translation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onToggle()
            } label: {
                Image(systemName: isInStudyList ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(isInStudyList ? .blue : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}
