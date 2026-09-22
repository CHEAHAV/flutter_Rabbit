import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_config.dart';
import '../models/question.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/save_snackbar.dart';
import '../widgets/section_header.dart';
import 'quiz_session_screen.dart';

class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key});

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  bool _showBookmarks = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final mistakeQuestions = app.progress.mistakeUids
        .map((uid) => app.repo.questionByUid(uid))
        .whereType<Question>()
        .toList();
    final bookmarkQuestions = app.progress.bookmarkUids
        .map((uid) => app.repo.questionByUid(uid))
        .whereType<Question>()
        .toList();

    final mastered = app.progress.totalCorrect;

    final list = _showBookmarks ? bookmarkQuestions : mistakeQuestions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        SectionHeader(
          title: 'សៀវភៅកត់ត្រា',
          subtitle: 'តាមដានកំហុស និងសំណួរដែលបានរក្សាទុក',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _metric(
                kh(mistakeQuestions.length),
                'ត្រូវពិនិត្យឡើងវិញ',
                AppColors.red,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _metric(
                kh(bookmarkQuestions.length),
                'បានរក្សាទុក',
                AppColors.gold,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _metric(
                kh(mastered),
                'ចម្លើយត្រឹមត្រូវសរុប',
                AppColors.emerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: list.isEmpty
                ? null
                : () => _practice(
                    context,
                    list,
                    _showBookmarks ? 'សំណួរដែលបានរក្សាទុក' : 'ពិនិត្យសំណួរខុស',
                  ),
            // Deliberately not a bookmark icon: the bookmark is the toggle on
            // each card, and reusing it here would read as "save all".
            icon: Icon(
              _showBookmarks
                  ? Icons.menu_book_rounded
                  : Icons.refresh_rounded,
            ),
            label: Text(
              _showBookmarks
                  ? 'ហ្វឹកហាត់សំណួរដែលបានរក្សាទុក ${kh(list.length)}'
                  : 'ហ្វឹកហាត់សំណួរខុសទាំង ${kh(list.length)} ឡើងវិញ',
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _tab(
                'សំណួរខុស (${kh(mistakeQuestions.length)})',
                !_showBookmarks,
                () => setState(() => _showBookmarks = false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _tab(
                'បានរក្សាទុក (${kh(bookmarkQuestions.length)})',
                _showBookmarks,
                () => setState(() => _showBookmarks = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(
                    _showBookmarks
                        ? Icons.bookmark_border_rounded
                        : Icons.emoji_events_outlined,
                    size: 32,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _showBookmarks
                        ? 'អ្នកមិនទាន់រក្សាទុកសំណួរណាមួយទេ'
                        : 'ល្អណាស់! អ្នកមិនមានសំណួរខុសដែលត្រូវពិនិត្យឡើងវិញទេ',
                    style: TextStyle(fontSize: 12, color: AppColors.slate),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...list.map(
            (q) => _QuestionPreviewCard(
              key: ValueKey(q.uid),
              question: q,
              partTitle: app.repo.partById(q.partId).titleKm,
              saved: app.progress.isBookmarked(q.uid),
              onToggleSave: () => _toggleSave(q),
            ),
          ),
      ],
    );
  }

  Widget _metric(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: AppColors.slate),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        if (!active) sfx.select();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.emerald : AppColors.card,
          border: Border.all(
            color: active ? AppColors.emerald : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.onEmerald : AppColors.slate,
          ),
        ),
      ),
    );
  }

  /// Unsaves (or re-saves) [question] from the notebook itself.
  ///
  /// Unsaving takes the card out of the list straight away, so the snackbar
  /// carries an undo: the saved list is the user's own shelf and a mis-tap on a
  /// question they wanted to keep should cost one tap to put back.
  Future<void> _toggleSave(Question question) async {
    final app = context.read<AppState>();
    sfx.tap();
    final saved = await app.progress.toggleBookmark(question.uid);
    if (!mounted) return;
    app.refresh();
    if (!context.mounted) return;
    showSaveChoiceSnackBar(
      context,
      saved: saved,
      onUndo: () => _toggleSave(question),
    );
  }

  /// Opens a practice session over exactly [questions] - the mistakes list or
  /// the saved list. Passed through as `overrideQuestions` so the session is
  /// built from this list rather than from the unanswered pool: these questions
  /// have all been answered already, and the point is to meet them again.
  void _practice(
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
}

/// One saved/mistaken question as it appears in the notebook: the question,
/// every option with the right one marked, and the bookmark toggle that puts
/// it on - or takes it off - the saved shelf.
///
/// Never instantiate it with `const`: [AppColors] is the app's mutable palette
/// and a const instance would keep whichever theme it was first built under.
class _QuestionPreviewCard extends StatelessWidget {
  final Question question;
  final String partTitle;
  final bool saved;
  final VoidCallback onToggleSave;

  const _QuestionPreviewCard({
    super.key,
    required this.question,
    required this.partTitle,
    required this.saved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        partTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: saved ? 'ដកចេញពីបញ្ជីរក្សាទុក' : 'រក្សាទុក',
                    onPressed: onToggleSave,
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                question.text,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.55,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < question.options.length; i++) _option(i),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '✓ ចម្លើយត្រឹមត្រូវ៖ ${question.labelAt(question.answerIndex)}. ${question.correctOptionText}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Option [i], with the correct one in emerald so the card can be studied
  /// from without opening a session.
  Widget _option(int i) {
    final isAnswer = i == question.answerIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${question.labelAt(i)}. ',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isAnswer ? FontWeight.w800 : FontWeight.w500,
              color: isAnswer ? AppColors.emerald : AppColors.slate,
            ),
          ),
          Expanded(
            child: Text(
              question.options[i],
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                fontWeight: isAnswer ? FontWeight.w800 : FontWeight.w500,
                color: isAnswer ? AppColors.emerald : AppColors.ink,
              ),
            ),
          ),
          if (isAnswer)
            Icon(
              Icons.check_circle_rounded,
              size: 15,
              color: AppColors.emerald,
            ),
        ],
      ),
    );
  }
}
