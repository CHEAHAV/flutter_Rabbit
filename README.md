# 🐇 Rabbit — Khmer QCM Master

A professional, offline-first Flutter app for practicing Cambodian civil-service
("មន្ត្រីរាជការ") entrance exam questions — Khmer-first UI, 13 official subject
areas, practice drills, timed mock exams, a mistakes notebook, and local progress
tracking. No account or internet connection required after install.

## ✅ What's built (fully working)

- **Complete Flutter app** — compiles clean (`flutter analyze`: 0 errors, `flutter test`:
  passing, `flutter build web`: succeeds).
- **5 tabs / flows**: Practice, Mock Exam, Notebook, Profile, and a full live Quiz
  session engine.
- **Practice mode** — pick any combination of the 13 subject parts, choose question
  count, get instant right/wrong feedback per question.
- **Mock Exam mode** — timed sessions (Quick/Standard/Full presets or fully custom:
  subjects, duration, question count, shuffle, negative-marking toggle, 5-minute
  warning), auto-submits when time expires.
- **Live exam engine** — countdown timer, flag-for-review, quick navigator strip,
  full question grid (bottom sheet), non-destructive exit confirmation, submit
  confirmation showing unanswered-question count.
- **Results & review** — score gauge, pass/fail banner, per-subject breakdown bars,
  full answer review with filters (all / wrong / flagged), one-tap "retry mistakes."
- **Notebook** — every wrong answer is automatically saved; bookmark any question;
  practice just your mistakes in one tap.
- **Profile** — Exam Readiness Index (accuracy + subject coverage + volume),
  per-subject competency bars, study streak, local data summary.
- **100% local persistence** via `shared_preferences` — streaks, history, mistakes,
  bookmarks, per-subject stats all survive app restarts, no server needed.
- **Khmer-first everywhere**: all numerals rendered as Khmer glyphs (០-៩), the
  bundled "Hanuman" font is used app-wide, canonical ក/ខ/គ/ឃ option labels are
  always rendered by the app itself (never copied from source formatting).

## 📊 Content status — please read before relying on this for real exam prep

The question bank lives in `assets/data/part_01.json` … `part_13.json`, one file
per official subject area, in a simple format the app can hot-load without any
code changes:

```json
{"id": 1, "q": "question text", "o": ["A", "B", "C", "D"], "a": 0}
```
(`a` is the 0-based index of the correct option.)

**All 13 subjects are now populated — 937 questions total.**

| # | Subject (ផ្នែក) | Questions |
|---|---|---|
| 1 | ប្រវត្តិសាស្ត្រ (History) | 72 |
| 2 | វប្បធម៌ អរិយធម៌ (Culture & Civilization) | 39 |
| 3 | ភូមិសាស្ត្រ និងប្រជាសាស្ត្រ (Geography & Demography) | 59 |
| 4 | រដ្ឋបាលសាធារណៈ (Public Administration) | 139 |
| 5 | សេដ្ឋកិច្ច ហិរញ្ញវត្ថុ និងវិនិយោគ (Economy & Finance) | 88 |
| 6 | មុខងារសាធារណៈ និងធនធានមនុស្ស (Public Function & HR) | 171 |
| 7 | អាស៊ាន (ASEAN) | 95 |
| 8 | អន្តរជាតិ (International Affairs) | 70 |
| 9 | ច្បាប់ គោលនយោបាយ និងនយោបាយ (Law & Policy) | 108 |
| 10 | សាសនា ក្រមសីលធម៌ និងសុភាសិត (Religion & Ethics) | 38 |
| 11 | វិទ្យាសាស្ត្រ បច្ចេកវិទ្យា និងនវានុវត្តន៍ (Science & Technology) | 17 |
| 12 | ល្បែងប្រាជ្ញា តក្កវិទ្យា និងករណីសិក្សា (Logic & Case Studies) | 26 |
| 13 | វិស័យយុត្តិធម៌ (Justice Sector) | 15 |

**How this was built:** the original `QCM.pdf` (219 pages, now included in the
project root for reference) has a broken embedded font encoding — extracting its
text yields systematically corrupted Khmer (not real OCR noise, but a consistent
character-level substitution from the font's cmap table: e.g. "តតើ"→should read
"តើ", a consistent ខ↔ែ glyph swap, reordered subscript-consonant clusters). Every
question was reconstructed by reading through that corruption with Khmer-language
fluency, then cross-checked question-by-question against the book's own answer-key
appendix (pages 190–219). The answer key's **letter is authoritative** over its
restated text; wherever a question's four options couldn't be confidently
reconstructed, or the answer key's letter conflicted with its own restated value,
or a question printed 5–6 options instead of the standard 4, that question was
**omitted rather than guessed** — a silently-wrong answer in an exam-prep tool is
worse than a missing question. That's why part sizes aren't perfectly round
numbers and why "id" values sometimes skip (e.g. Part 6 goes up to id 177 but has
171 questions — the gaps are the omitted ones).

Given the scale (~40 omissions out of ~980 source questions, mostly idiom/proverb
items or malformed source options), spot-checking a subject you're about to rely
on heavily before an exam is still a good idea. The JSON schema is intentionally
simple, so hand-correcting any question is a one-line edit with zero Dart changes,
picked up on next app launch.

## 🚀 Running the app

```bash
flutter pub get
flutter run -d chrome     # fastest way to preview (no extra setup needed)
flutter run -d windows    # needs Visual Studio "Desktop development with C++"
flutter run -d <android-device-or-emulator>
```

`flutter doctor` on this machine shows Chrome and the Android SDK ready to go;
Windows desktop builds need the Visual Studio C++ workload installed first.

## 🏗️ Architecture

```
lib/
  app.dart                 # MaterialApp + theme + Provider root
  main.dart
  theme/app_theme.dart      # "Sovereign Scholar" emerald/gold Material 3 theme
  models/                   # Question, ExamPart, ExamConfig, ExamResult, ...
  data/question_repository.dart   # loads assets/data/part_XX.json at startup
  services/progress_service.dart  # shared_preferences-backed local progress store
  state/
    app_state.dart          # root app ChangeNotifier (bootstraps repo + progress)
    exam_session.dart        # drives one live practice/exam run (timer, nav, answers)
  screens/                  # splash, home shell, practice, mock, notebook,
                             # profile, exam config, live quiz, result, review
  widgets/                  # reusable UI: subject tile, option tile, stat box,
                             # readiness gauge, section header
assets/
  data/part_01.json … part_13.json   # question bank, one file per subject
  fonts/Hanuman-VariableFont_wght.ttf
```

Everything is plain `StatefulWidget`/`ChangeNotifier` + `provider` — no code
generation, no backend, no auth. Adding more questions is a JSON edit; adding a
14th subject is one entry in `ExamPart.catalog` + a new `part_14.json`.

## 🔜 Natural next steps

- Spot-check a few subjects against the source PDF before high-stakes exam prep
  (see **Content status** above for the omission methodology).
- Generate a proper Rabbit app icon/launcher icon (currently default Flutter icon).
- Optional: add a "report a wrong answer" button in Review/Notebook that just
  copies the question id, to make crowd-sourced corrections easy.
