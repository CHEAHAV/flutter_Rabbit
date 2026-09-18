import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_config.dart';
import '../models/question.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
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
        const SectionHeader(title: 'សៀវភៅកត់ត្រា', subtitle: 'តាមដានកំហុស និងសំណួរដែលបានរក្សាទុក'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _metric(kh(mistakeQuestions.length), 'ត្រូវពិនិត្យឡើងវិញ', AppColors.red),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _metric(kh(bookmarkQuestions.length), 'បានរក្សាទុក', AppColors.gold),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _metric(kh(mastered), 'ចម្លើយត្រឹមត្រូវសរុប', AppColors.emerald),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: mistakeQuestions.isEmpty
                ? null
                : () => _practiceMistakes(context, mistakeQuestions),
            icon: const Icon(Icons.refresh_rounded),
            label: Text('ហ្វឹកហាត់សំណួរខុសទាំង ${kh(mistakeQuestions.length)} ឡើងវិញ'),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _tab('សំណួរខុស (${kh(mistakeQuestions.length)})', !_showBookmarks, () => setState(() => _showBookmarks = false))),
            const SizedBox(width: 8),
            Expanded(child: _tab('បានរក្សាទុក (${kh(bookmarkQuestions.length)})', _showBookmarks, () => setState(() => _showBookmarks = true))),
          ],
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(_showBookmarks ? Icons.bookmark_border_rounded : Icons.emoji_events_outlined,
                      size: 32, color: AppColors.muted),
                  const SizedBox(height: 10),
                  Text(
                    _showBookmarks
                        ? 'អ្នកមិនទាន់រក្សាទុកសំណួរណាមួយទេ'
                        : 'ល្អណាស់! អ្នកមិនមានសំណួរខុសដែលត្រូវពិនិត្យឡើងវិញទេ',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...list.map((q) => _QuestionPreviewCard(
                question: q,
                partTitle: app.repo.partById(q.partId).titleKm,
                isBookmark: _showBookmarks,
              )),
      ],
    );
  }

  Widget _metric(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.slate), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.emerald : Colors.white,
          border: Border.all(color: active ? AppColors.emerald : AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.slate),
        ),
      ),
    );
  }

  void _practiceMistakes(BuildContext context, List<Question> questions) {
    final config = ExamConfig(
      mode: ExamMode.practice,
      partIds: questions.map((q) => q.partId).toSet(),
      questionCount: questions.length,
      timeLimit: null,
      shuffleQuestions: true,
      instantFeedback: true,
      presetLabel: 'ពិនិត្យសំណួរខុស',
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizSessionScreen(config: config, overrideQuestions: questions),
    ));
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  final Question question;
  final String partTitle;
  final bool isBookmark;

  const _QuestionPreviewCard({required this.question, required this.partTitle, required this.isBookmark});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(999)),
                    child: Text(partTitle, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emerald)),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      await app.progress.toggleBookmark(question.uid);
                      app.refresh();
                    },
                    icon: Icon(
                      app.progress.isBookmarked(question.uid) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(question.text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.55)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '✓ ចម្លើយត្រឹមត្រូវ៖ ${khmerLabel(question.answerIndex)}. ${question.correctOptionText}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emerald),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String khmerLabel(int i) => const ['ក', 'ខ', 'គ', 'ឃ'][i];
