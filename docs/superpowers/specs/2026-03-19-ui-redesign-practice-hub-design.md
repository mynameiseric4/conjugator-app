# UI Redesign & Practice Hub — Design Spec
**Date:** 2026-03-19
**Status:** Approved

---

## Overview

Two intertwined goals: push the visual design further (bolder, richer, more personality) and make the app more robust as a learning tool. The primary structural change is rebuilding the Practice tab into a hub with mode-specific tense selection and a new fill-in-the-blank practice mode. All other tabs receive a consistent visual baseline lift.

---

## 1. Visual Design Language

### Core shift
Move from "accents of color on white" to "color as structure." The Ecuador flag colors (blue `#0033A0`, red `#CE1125`, yellow `#FFD100`) are used as fills and identity colors, not just accents.

### Color roles
- **Navy `#0d1b3e`** — Practice hub background, chrome/navigation surfaces
- **Warm cream `#FFFCF0`** — Content screens (flashcards, fill-in-the-blank, quiz questions) for readability
- **Ecuador Blue** — Flashcard mode identity, primary action color
- **Ecuador Red** — SRS Review mode identity, incorrect/again states
- **Ecuador Yellow** — Fill-in-the-blank mode identity (dark text on yellow)

### Typography
- Palatino Bold retained for navigation titles, increased size contrast between title and body
- Verb infinitives and conjugated forms rendered larger and bolder throughout
- Secondary text bumped up 1pt across the board for readability

### Animations
- Spring-based transitions entering/exiting practice modes
- Card flip weighted more satisfyingly (slightly slower, spring easing)
- Rating buttons (Again/Good/Easy) have a brief scale-down/up on tap
- Correct answer fill-in animation: blank fills green, 1-second hold, auto-advance

### Recurring motifs
- Ecuador flag stripe (thin 3-color horizontal bar) used as section dividers and card top-borders throughout the app
- Card shadow treatment: `shadow(color: .black.opacity(0.15), radius: 12, y: 6)` consistently applied

---

## 2. Practice Hub

### Structure
The Practice tab is replaced by a scrollable hub with two zones, both on the navy background.

**Top zone — Status bar:**
- Compact row: today's streak (flame icon), SRS cards due (stack icon), overall accuracy (checkmark icon)
- Data sourced from existing `AppState` computed properties — no new data model
- Tapping the row navigates to the Stats tab
- "Focus: Weak Spots" toggle — when enabled, biases all modes to prioritize tenses where `perTenseAccuracy` is below 70%. Stored in `UserDefaults` under `focus_weak_spots`. Passed as a parameter into each mode's card generation.

**Bottom zone — Mode cards:**
Three vertically stacked cards, each displaying:
- Mode name + large SF Symbol icon
- One-line description
- Last-session stat or cards-due count
- Chevron indicating tappability

**Modes:**
| Card | Icon | Description | Color |
|------|------|-------------|-------|
| Flashcards | `rectangle.on.rectangle.angled` | Flip cards, build memory | Ecuador Blue |
| SRS Review | `arrow.triangle.2.circlepath` | Scheduled review queue | Ecuador Red |
| Fill-in-the-Blank | `text.cursor` | Type the conjugation in context | Ecuador Yellow |

### Session Setup sheet
- Tapping Flashcards or Fill-in-the-Blank presents a half-sheet (`presentationDetents([.medium])`)
- Sheet shows tense checkboxes for that mode, stored independently: `flashcard_tenses` and `fillintheblank_tenses` in `UserDefaults.standard`
- Default value (first launch): inherits from the existing global `active_tenses` setting
- "Start" button launches the session; sheet dismisses and mode view appears
- SRS Review skips this sheet — its queue is pre-scheduled

### Weak-spot targeting
- `AppState.perTenseAccuracy` already returns per-tense accuracy sorted ascending
- When "Focus: Weak Spots" is on, `VerbDataService.generateCards` receives a weighted tense list biasing toward tenses with accuracy < 0.70
- Applies to Flashcards and Fill-in-the-Blank; SRS Review is unaffected (its scheduling handles this intrinsically)

---

## 3. Fill-in-the-Blank Mode

### Card anatomy
```
[ Tense badge: "Condicional Simple" ]

  "Si tuviera tiempo, ____________ más."
              (poder — yo)

[ _______________________ ] ← text field, auto-focused
[ Submit ]
```

- Sentence sourced from `VerbExamples.sentences[verb.id]` with the conjugated form replaced by `____________`
- Hint line shows infinitive + pronoun in secondary style
- Sentence displayed at `title3` size for readability

### Answer evaluation
- Correct: blank animates to green, shows correct form, auto-advances after 1 second
- Incorrect: blank animates to red showing typed text, correct form appears below in Ecuador Blue, manual "Continue" button to advance
- Accent toolbar: reuses existing quiz keyboard toolbar pattern — row of buttons for á é í ó ú ü ñ ¿ ¡ above the system keyboard

### Tense selection
- Configured in Session Setup sheet before starting
- Stored under `fillintheblank_tenses` key, completely independent of flashcard or quiz tense selections
- Falls back to global `active_tenses` if not yet configured

### SRS integration
- Each answer calls `appState.recordAnswer(verb:tense:pronoun:correct:)` — identical to flashcard and quiz modes
- Feeds mastery levels and SRS queue without any separate tracking system

### Card generation
- Filters `allVerbs` to those with a non-nil `exampleSentence` (all 499 verbs now have one)
- Picks a random pronoun with a valid conjugation for the selected tense
- Replaces the conjugated form in the sentence using string matching; if the exact form doesn't appear verbatim, displays the full sentence as context and asks for the form directly (fallback)

---

## 4. Consistent Baseline Lift

### Quiz tab
- Question card: larger verb display, stronger tense badge, more vertical padding
- Progress bar: thicker (6pt), Ecuador Blue fill with animation
- `QuizResultView` hero: large score number, tense breakdown as horizontal bar chart

### Vocabulary tab
- Verb row left-edge color bar reflects `MasteryLevel.color` (new → gray, struggling → red, learning → orange, mastered → blue) instead of red-only irregular indicator
- "Practice Vocabulary" button styled as a compact mode card

### Stats tab
- Accuracy by tense: horizontal bar chart (reuses the bar style from onboarding illustration)
- Mastery distribution: segmented ring (4 segments, one per MasteryLevel)
- Streak: 7-day dot calendar row (filled dot = practiced, empty = missed)

### Settings tab
- Section headers get Ecuador flag stripe as left-border accent
- Tense Guide and Irregular Verbs links styled as cards rather than plain list rows

### Global
- All `List`-based screens use `.insetGrouped` with increased row height/padding
- Navigation titles: Palatino Bold, increased contrast vs. body text
- Secondary text: +1pt size throughout

---

## 5. Architecture Notes

### New files
- `PracticeHubView.swift` — replaces `FlashcardView` as the root of the Practice tab
- `ModeCardView.swift` — reusable card component for the three mode cards
- `SessionSetupSheet.swift` — half-sheet tense picker, parameterized by mode key
- `FillInTheBlankView.swift` — new practice mode

### Modified files
- `ContentView.swift` — Practice tab points to `PracticeHubView`
- `AppState.swift` — add `focusWeakSpots: Bool` @AppStorage, per-mode tense accessors
- `VerbDataService.generateCards` — add `weightedTenses` parameter for weak-spot targeting
- `FlashcardView.swift` — accepts tense set as parameter instead of reading global `activeTenses`
- `QuizView.swift` — visual updates only
- `VocabularyView.swift` — mastery color bar, practice button styling
- `StatsView.swift` — bar chart, ring, 7-day streak dots
- `SettingsView.swift` — card-style reference links, flag stripe section headers

### UserDefaults keys added
| Key | Type | Description |
|-----|------|-------------|
| `flashcard_tenses` | `[String]` | Per-mode tense selection for flashcards |
| `fillintheblank_tenses` | `[String]` | Per-mode tense selection for fill-in-the-blank |
| `focus_weak_spots` | `Bool` | Weak-spot targeting toggle |

### No new data models required
All features build on existing `AppState`, `Verb`, `PracticeCard`, `VerbMastery`, and `SRSCard` types.

---

## Out of Scope
- Audio/TTS for sentences
- Conjugation builder (full table from memory) mode
- Multiple choice mode
- User accounts or cloud sync
