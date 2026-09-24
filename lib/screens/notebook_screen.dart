import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/question_preview_card.dart';
import '../widgets/section_header.dart';
import 'saved_part_screen.dart';

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
    // The saved shelf is kept part by part: each part the user saved from is
    // one row, and its questions open on that part's own page.
    final savedParts = savedQuestionsByPart(app);
    final savedCount = savedParts.fold(0, (n, e) => n + e.$2.length);

    final mastered = app.progress.totalCorrect;

    final isEmpty = _showBookmarks
        ? savedParts.isEmpty
        : mistakeQuestions.isEmpty;

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
              child: _metric(kh(savedCount), 'បានរក្សាទុក', AppColors.gold),
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
        // Only the mistakes are practised from here, all together. Saved
        // questions are practised a part at a time, from each part's page.
        if (!_showBookmarks) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: mistakeQuestions.isEmpty
                  ? null
                  : () => practiceQuestions(
                      context,
                      mistakeQuestions,
                      'ពិនិត្យសំណួរខុស',
                    ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'ហ្វឹកហាត់សំណួរខុសទាំង ${kh(mistakeQuestions.length)} ឡើងវិញ',
              ),
            ),
          ),
        ],
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
                'បានរក្សាទុក (${kh(savedCount)})',
                _showBookmarks,
                () => setState(() => _showBookmarks = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_showBookmarks && !isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'ចុចលើផ្នែកណាមួយ ដើម្បីមើល និងហ្វឹកហាត់សំណួរដែលបានរក្សាទុកក្នុងផ្នែកនោះ',
              style: TextStyle(fontSize: 11.5, color: AppColors.slate),
            ),
          ),
        if (isEmpty)
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
        else if (_showBookmarks)
          for (final (part, questions) in savedParts)
            SavedPartTile(
              key: ValueKey('saved-part-${part.id}'),
              part: part,
              count: questions.length,
            )
        else
          for (final q in mistakeQuestions)
            QuestionPreviewCard(
              key: ValueKey(q.uid),
              question: q,
              partTitle: app.repo.partById(q.partId).titleKm,
              saved: app.progress.isBookmarked(q.uid),
              onToggleSave: () => toggleSavedQuestion(context, q),
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
}
