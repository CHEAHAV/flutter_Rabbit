import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_result.dart';
import '../models/question_attempt.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/save_snackbar.dart';

enum _ReviewFilter { all, wrong, flagged }

class ReviewScreen extends StatefulWidget {
  final ExamResult result;
  const ReviewScreen({super.key, required this.result});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  _ReviewFilter _filter = _ReviewFilter.all;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    List<QuestionAttempt> list = widget.result.attempts;
    if (_filter == _ReviewFilter.wrong) {
      list = list.where((a) => a.isAnswered && !a.isCorrect).toList();
    } else if (_filter == _ReviewFilter.flagged) {
      list = list.where((a) => a.flagged).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ពិនិត្យចម្លើយ')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: Row(
              children: [
                Expanded(
                  child: _filterChip(
                    'ទាំងអស់ (${kh(widget.result.total)})',
                    _ReviewFilter.all,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _filterChip(
                    'ខុស (${kh(widget.result.wrongCount)})',
                    _ReviewFilter.wrong,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _filterChip(
                    'ចំណាំ (${kh(widget.result.attempts.where((a) => a.flagged).length)})',
                    _ReviewFilter.flagged,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'គ្មានធាតុសម្រាប់តម្រងនេះទេ',
                      style: TextStyle(color: AppColors.slate),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final a = list[i];
                      final partTitle = app.repo
                          .partById(a.question.partId)
                          .titleKm;
                      return _ReviewCard(
                        attempt: a,
                        partTitle: partTitle,
                        index: widget.result.attempts.indexOf(a),
                        saved: app.progress.isBookmarked(a.question.uid),
                        onToggleSave: () => _toggleSave(a),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Saves or unsaves the reviewed question, into the same notebook shelf the
  /// quiz screen's button writes to.
  ///
  /// The attempt's own flag is moved with it so the "ចំណាំ" filter and its
  /// count keep matching the bookmarks shown on the cards.
  Future<void> _toggleSave(QuestionAttempt attempt) async {
    final app = context.read<AppState>();
    sfx.tap();
    final saved = await app.progress.toggleBookmark(attempt.question.uid);
    if (!mounted) return;
    attempt.flagged = saved;
    app.refresh();
    setState(() {});
    if (!context.mounted) return;
    showSaveChoiceSnackBar(
      context,
      saved: saved,
      onUndo: () => _toggleSave(attempt),
    );
  }

  Widget _filterChip(String label, _ReviewFilter value) {
    final active = _filter == value;
    return InkWell(
      onTap: () {
        if (_filter != value) sfx.select();
        setState(() => _filter = value);
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
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.onEmerald : AppColors.slate,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// One reviewed question. Never instantiate it with `const`: its build reads
/// [AppColors], the palette the theme switch mutates in place.
class _ReviewCard extends StatelessWidget {
  final QuestionAttempt attempt;
  final String partTitle;
  final int index;

  /// Whether this question is on the notebook's saved shelf right now - read
  /// from [ProgressService], not from [attempt], so the icon still tells the
  /// truth after the question has been unsaved from elsewhere.
  final bool saved;
  final VoidCallback onToggleSave;

  const _ReviewCard({
    required this.attempt,
    required this.partTitle,
    required this.index,
    required this.saved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final correct = attempt.isCorrect;
    final skipped = !attempt.isAnswered;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'សំណួរទី ${kh(index + 1)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    partTitle,
                    style: TextStyle(fontSize: 9.5, color: AppColors.slate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  skipped
                      ? Icons.remove_circle_outline_rounded
                      : (correct
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded),
                  size: 18,
                  color: skipped
                      ? AppColors.muted
                      : (correct ? AppColors.emerald : AppColors.red),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: saved ? 'ដកចេញពីបញ្ជីរក្សាទុក' : 'រក្សាទុក',
                  onPressed: onToggleSave,
                  icon: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              attempt.question.text,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < attempt.question.options.length; i++)
              _optionLine(i),
          ],
        ),
      ),
    );
  }

  Widget _optionLine(int i) {
    final isAnswer = i == attempt.question.answerIndex;
    final isSelected = i == attempt.selectedIndex;
    Color color = AppColors.ink;
    FontWeight weight = FontWeight.w500;
    IconData? icon;
    Color iconColor = AppColors.emerald;

    if (isAnswer) {
      color = AppColors.emerald;
      weight = FontWeight.w800;
      icon = Icons.check_circle_rounded;
    }
    if (isSelected && !isAnswer) {
      color = AppColors.red;
      weight = FontWeight.w800;
      icon = Icons.cancel_rounded;
      iconColor = AppColors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Unlettered, like the quiz screen: the options were shuffled
            // for this session, so a letter would mean nothing.
            '•  ',
            style: TextStyle(color: color, fontWeight: weight, fontSize: 12.5),
          ),
          Expanded(
            child: Text(
              attempt.question.options[i],
              style: TextStyle(
                color: color,
                fontWeight: weight,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
          if (icon != null) Icon(icon, size: 15, color: iconColor),
        ],
      ),
    );
  }
}
