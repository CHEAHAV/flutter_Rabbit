import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_config.dart';
import '../models/exam_result.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/readiness_gauge.dart';
import '../widgets/stat_box.dart';
import 'quiz_session_screen.dart';
import 'review_screen.dart';

class ResultScreen extends StatefulWidget {
  final ExamResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  ExamResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    // Fanfare (or an encouraging tone) once the result is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) sfx.result(passed: result.passed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final passed = result.passed;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    passed ? '🎉 ល្អប្រសើរណាស់!' : 'បន្តព្យាយាមទៀត 💪',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.config.mode == ExamMode.mock
                        ? 'លទ្ធផលការប្រឡងសាកល្បង'
                        : 'លទ្ធផលការហ្វឹកហាត់',
                    style: TextStyle(fontSize: 12, color: AppColors.slate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    ReadinessGauge(value: result.scorePercent, size: 168),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: passed ? AppColors.mint : AppColors.redBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        passed ? 'ជាប់លទ្ធផល' : 'មិនទាន់ជាប់',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: passed ? AppColors.emerald : AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatBox(
                    value: kh(result.correctCount),
                    label: 'ត្រូវ',
                    valueColor: AppColors.emerald,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatBox(
                    value: kh(result.wrongCount),
                    label: 'ខុស',
                    valueColor: AppColors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatBox(
                    value: kh(result.skippedCount),
                    label: 'រំលង',
                    valueColor: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatBox(
                    value: khDuration(result.timeSpent),
                    label: 'ពេលប្រើ',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'លទ្ធផលតាមមុខវិជ្ជា',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final entry in result.byPart.entries) ...[
                      _PartRow(
                        title: app.repo.partById(entry.key).titleKm,
                        correct: entry.value.correct,
                        total: entry.value.total,
                      ),
                      if (entry.key != result.byPart.keys.last)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  sfx.tap();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReviewScreen(result: result),
                    ),
                  );
                },
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('ពិនិត្យមើលចម្លើយទាំងអស់'),
              ),
            ),
            const SizedBox(height: 10),
            if (result.mistakes.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    sfx.tap();
                    final wrongQuestions = result.mistakes
                        .map((a) => a.question)
                        .toList();
                    final config = ExamConfig(
                      mode: ExamMode.practice,
                      partIds: wrongQuestions.map((q) => q.partId).toSet(),
                      questionCount: wrongQuestions.length,
                      timeLimit: null,
                      shuffleQuestions: true,
                      instantFeedback: true,
                      presetLabel: 'ហ្វឹកហាត់សំណួរខុស',
                    );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => QuizSessionScreen(
                          config: config,
                          overrideQuestions: wrongQuestions,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'ហ្វឹកហាត់សំណួរខុសទាំង ${kh(result.mistakes.length)}',
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  sfx.tap();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('ត្រឡប់ទៅទំព័រដើម'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  final String title;
  final int correct;
  final int total;
  const _PartRow({
    required this.title,
    required this.correct,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : correct / total;
    final color = pct >= 0.75
        ? AppColors.emerald
        : (pct >= 0.5 ? AppColors.amber : AppColors.red);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${kh(correct)}/${kh(total)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: AppColors.line,
            color: color,
          ),
        ),
      ],
    );
  }
}
