import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_config.dart';
import '../models/exam_part.dart';
import '../models/history_entry.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_box.dart';
import 'exam_config_screen.dart';
import 'quiz_session_screen.dart';

class MockScreen extends StatelessWidget {
  const MockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final available = app.parts.where((p) => p.count > 0).toList();
    final history = app.progress.history;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        Text(
          'ប្រឡងសាកល្បង',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'សាកល្បងក្រោមលក្ខខណ្ឌនិងពេលវេលាដូចការប្រឡងពិត',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.slate,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.amberBg,
            border: Border.all(color: AppColors.amberBorder),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🏛️', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'សម្រង់លក្ខខណ្ឌប្រឡងស្តង់ដារ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Simulation Mode • ចាប់ពេល • គ្មានការបញ្ឈប់',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.isDark
                                ? AppColors.amber
                                : const Color(0xFF6D654B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(
                    child: StatBox(value: '៥០', label: 'សំណួរ'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: StatBox(value: '៤០ នាទី', label: 'រយៈពេល'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: StatBox(value: '៥០%', label: 'ពិន្ទុជាប់'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: available.isEmpty
                      ? null
                      : () => _startStandardMock(context, app),
                  child: const Text('ចាប់ផ្ដើម Mock Exam'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'កំណត់ Mock Exam ផ្ទាល់ខ្លួន',
          subtitle: 'ជ្រើសមុខវិជ្ជា រយៈពេល និងចំនួនសំណួរដោយខ្លួនឯង',
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'រៀបចំវគ្គប្រឡងផ្ទាល់ខ្លួនរបស់អ្នក',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ជ្រើសផ្នែកមេរៀន កំណត់ម៉ោង និង Negative Marking',
                  style: TextStyle(fontSize: 11, color: AppColors.slate),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const ExamConfigScreen(mode: ExamMode.mock),
                      ),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('កំណត់ Mock Exam'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'ប្រវត្តិប្រឡងរបស់ខ្ញុំ',
          subtitle: 'លទ្ធផលនៃវគ្គប្រឡងកន្លងមក',
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.history_rounded, color: AppColors.muted, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    'អ្នកមិនទាន់ប្រឡងសាកល្បងណាមួយនៅឡើយទេ',
                    style: TextStyle(fontSize: 12, color: AppColors.slate),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  for (var i = 0; i < history.length.clamp(0, 8); i++) ...[
                    _HistoryRow(entry: history[i]),
                    if (i != history.length.clamp(0, 8) - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _startStandardMock(BuildContext context, AppState app) {
    final available = app.parts
        .where((p) => p.count > 0)
        .map((p) => p.id)
        .toSet();
    final config = ExamConfig(
      mode: ExamMode.mock,
      partIds: available,
      questionCount: 50,
      timeLimit: const Duration(minutes: 40),
      shuffleQuestions: true,
      instantFeedback: false,
      presetLabel: 'ស្តង់ដារផ្លូវការ',
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizSessionScreen(config: config)),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final passed = entry.percent >= 50;
    final partLabel = entry.partIds.length == ExamPart.catalog.length
        ? 'គ្រប់មុខវិជ្ជា'
        : '${kh(entry.partIds.length)} មុខវិជ្ជា';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: passed ? AppColors.mint : AppColors.redBg,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              '${kh(entry.percent.round())}%',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: passed ? AppColors.emerald : AppColors.red,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.mode == ExamMode.mock ? 'Mock Exam' : 'ហ្វឹកហាត់',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${kh(entry.correct)}/${kh(entry.total)} ត្រូវ • $partLabel • ${_fmtDate(entry.date)}',
                  style: TextStyle(fontSize: 10.5, color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${kh(d.day)}/${kh(d.month)}/${kh(d.year)}';
}
