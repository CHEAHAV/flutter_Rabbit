import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_config.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/section_header.dart';
import '../widgets/subject_tile.dart';
import 'exam_config_screen.dart';
import 'quiz_session_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  Set<int> _selected = {};
  int _count = 20;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final parts = app.parts;
    final available = parts.where((p) => p.count > 0).toList();

    if (!_initialized) {
      _selected = available.map((p) => p.id).toSet();
      _initialized = true;
    }

    final selectedCount = _selected.length;
    final totalQuestions = parts
        .where((p) => _selected.contains(p.id))
        .fold<int>(0, (sum, p) => sum + p.count);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.emerald, AppColors.emeraldDeep],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text('🐇', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rabbit',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'ត្រៀមប្រឡងមន្ត្រីរាជការកម្ពុជា',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.isDark
                  ? [AppColors.emeraldDeep, const Color(0xFF0D5C3A)]
                  : [AppColors.emerald, AppColors.emeraldDeep],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ហ្វឹកហាត់ប្រចាំថ្ងៃ',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ត្រៀមខ្លួនឲ្យរួចរាល់\nសម្រាប់ថ្ងៃប្រឡង',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'មានសំណួរសរុប ${kh(app.repo.totalQuestionCount)} សំណួរ ពី ១៣ ផ្នែកមេរៀនផ្លូវការ',
                style: const TextStyle(
                  color: Color(0xFFE6F1EB),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.emerald,
                        side: BorderSide.none,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const ExamConfigScreen(mode: ExamMode.practice),
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('កំណត់ការប្រឡង'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: selectedCount == 0
                          ? null
                          : () => _launch(context, app, totalQuestions),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('ចាប់ផ្ដើម'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'មុខវិជ្ជាសម្រាប់ហ្វឹកហាត់',
          subtitle: 'ជ្រើសមុខវិជ្ជាច្រើនក្នុងពេលតែមួយ',
          trailing: TextButton(
            onPressed: () => setState(() {
              _selected = _selected.length == available.length
                  ? {}
                  : available.map((p) => p.id).toSet();
            }),
            child: Text(
              _selected.length == available.length
                  ? 'ដកចេញទាំងអស់'
                  : 'ជ្រើសទាំងអស់',
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (var i = 0; i < parts.length; i++) ...[
                  SubjectTile(
                    part: parts[i],
                    selected: _selected.contains(parts[i].id),
                    accuracy: app.progress.statFor(parts[i].id).answered > 0
                        ? app.progress.statFor(parts[i].id).accuracy
                        : null,
                    onChanged: (v) => setState(() {
                      if (v) {
                        _selected.add(parts[i].id);
                      } else {
                        _selected.remove(parts[i].id);
                      }
                    }),
                  ),
                  if (i != parts.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            'បានជ្រើសរើស ${kh(selectedCount)} មុខវិជ្ជា • សរុប ${kh(totalQuestions)} សំណួរ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'ចំនួនសំណួរក្នុងវគ្គ',
          subtitle: 'ជ្រើសបរិមាណសម្រាប់ការហ្វឹកហាត់លើកនេះ',
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [10, 20, 30, 50, 0].map((n) {
                final label = n == 0 ? 'ទាំងអស់' : kh(n);
                final active = _count == n;
                return ChoiceChip(
                  label: Text(label),
                  selected: active,
                  onSelected: (_) => setState(() => _count = n),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: selectedCount == 0
                ? null
                : () => _launch(context, app, totalQuestions),
            child: Text(
              'ចាប់ផ្ដើមហ្វឹកហាត់ • ${_count == 0 ? kh(totalQuestions) : kh(_count.clamp(0, totalQuestions))} សំណួរ',
            ),
          ),
        ),
      ],
    );
  }

  void _launch(BuildContext context, AppState app, int totalQuestions) {
    final count = _count == 0 ? totalQuestions : _count;
    final config = ExamConfig(
      mode: ExamMode.practice,
      partIds: _selected,
      questionCount: count,
      timeLimit: null,
      shuffleQuestions: true,
      instantFeedback: true,
      presetLabel: 'ហ្វឹកហាត់សេរី',
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizSessionScreen(config: config)),
    );
  }
}
