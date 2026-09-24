import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_config.dart';
import '../models/exam_part.dart';
import '../models/question.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/question_preview_card.dart';
import '../widgets/save_snackbar.dart';
import 'quiz_session_screen.dart';

/// The saved questions, newest save first, grouped by the part (subject) they
/// were saved from, with the parts in catalog order. A part with nothing saved
/// in it is left out, so the notebook only lists parts the user has kept
/// something from.
///
/// Nothing is stored per part: a saved question's uid already names its part
/// ("27-15" is question 15 of part 27), so the grouping is read off the saved
/// list every time and can never disagree with it.
List<(ExamPart, List<Question>)> savedQuestionsByPart(AppState app) {
  final byPart = <int, List<Question>>{};
  for (final uid in app.progress.bookmarkUids.toList().reversed) {
    final q = app.repo.questionByUid(uid);
    if (q == null) continue;
    byPart.putIfAbsent(q.partId, () => []).add(q);
  }
  return [
    for (final part in app.repo.parts)
      if (byPart[part.id] case final questions?) (part, questions),
  ];
}

/// Opens a practice session over exactly [questions] - a part's saved
/// questions, or the mistakes list. Passed through as `overrideQuestions` so
/// the session is built from this list rather than from the unanswered pool:
/// these questions have all been answered already, and the point is to meet
/// them again.
void practiceQuestions(
  BuildContext context,
  List<Question> questions,
  String label,
) {
  sfx.tap();
  final config = ExamConfig(
    mode: ExamMode.practice,
    partIds: questions.map((q) => q.partId).toSet(),
    questionCount: questions.length,
    timeLimit: null,
    shuffleQuestions: true,
    instantFeedback: true,
    presetLabel: label,
  );
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          QuizSessionScreen(config: config, overrideQuestions: questions),
    ),
  );
}

/// Unsaves (or re-saves) [question] from a notebook card.
///
/// Unsaving takes the card off the shelf straight away, so the snackbar
/// carries an undo: a mis-tap on a question the user wanted to keep should
/// cost one tap to put back.
Future<void> toggleSavedQuestion(BuildContext context, Question question) =>
    _toggleSaved(context, context.read<AppState>(), question);

/// [app] is held on to rather than looked up again, because the undo can be
/// pressed after the page the card was on has been closed - the snackbar
/// outlives it. The save is still undone then; there is just no page left to
/// show a second snackbar on.
Future<void> _toggleSaved(
  BuildContext context,
  AppState app,
  Question question,
) async {
  sfx.tap();
  final saved = await app.progress.toggleBookmark(question.uid);
  app.refresh();
  if (!context.mounted) return;
  showSaveChoiceSnackBar(
    context,
    saved: saved,
    onUndo: () => _toggleSaved(context, app, question),
  );
}

/// One part's page in the saved-questions notebook: only the questions saved
/// from that part, and a practice button that runs just those.
///
/// It reads the saved list live, so unsaving a card here takes it off at once,
/// and an undo puts it back.
class SavedPartScreen extends StatelessWidget {
  final int partId;

  const SavedPartScreen({super.key, required this.partId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final part = app.repo.partById(partId);
    final questions = [
      for (final (p, qs) in savedQuestionsByPart(app))
        if (p.id == partId) ...qs,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('សំណួរដែលបានរក្សាទុក')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          _PartHeader(part: part, count: questions.length),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: questions.isEmpty
                  ? null
                  : () => practiceQuestions(context, questions, part.titleKm),
              icon: const Icon(Icons.menu_book_rounded),
              label: Text('ហ្វឹកហាត់សំណួរទាំង ${kh(questions.length)}'),
            ),
          ),
          const SizedBox(height: 14),
          if (questions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 32,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'មិនមានសំណួររក្សាទុកក្នុងផ្នែកនេះទៀតទេ',
                      style: TextStyle(fontSize: 12, color: AppColors.slate),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            for (final q in questions)
              QuestionPreviewCard(
                key: ValueKey(q.uid),
                question: q,
                partTitle: part.titleKm,
                saved: app.progress.isBookmarked(q.uid),
                onToggleSave: () => toggleSavedQuestion(context, q),
              ),
        ],
      ),
    );
  }
}

/// The part this page is about: its icon, name, course and how many of its
/// questions are saved.
class _PartHeader extends StatelessWidget {
  final ExamPart part;
  final int count;

  const _PartHeader({required this.part, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(part.icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.titleKm,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    part.track.titleKm,
                    style: TextStyle(fontSize: 11, color: AppColors.slate),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.bookmark_rounded,
                        size: 14,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'បានរក្សាទុក ${kh(count)} សំណួរ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One part on the notebook's saved shelf: tapping it opens [SavedPartScreen]
/// with just that part's saved questions.
class SavedPartTile extends StatelessWidget {
  final ExamPart part;
  final int count;

  const SavedPartTile({super.key, required this.part, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            sfx.tap();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SavedPartScreen(partId: part.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(part.icon, style: const TextStyle(fontSize: 19)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.titleKm,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        part.track.titleKm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // How many are saved here, in the notebook's gold.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_rounded,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        kh(count),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
