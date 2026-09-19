import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_config.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/section_header.dart';
import '../widgets/subject_tile.dart';
import 'quiz_session_screen.dart';

class _Preset {
  final String label;
  final String sub;
  final int count;
  final Duration? time;
  final bool instantFeedback;
  const _Preset(
    this.label,
    this.sub,
    this.count,
    this.time,
    this.instantFeedback,
  );
}

const _practicePresets = [
  _Preset('ស្តង់ដារ', 'Official Standard', 50, null, false),
  _Preset('ហ្វឹកហាត់រហ័ស', 'Speed Drill', 20, null, true),
  _Preset('តឹងតែង', 'Deep Review', 100, null, false),
];

const _mockPresets = [
  _Preset('រហ័ស', 'Quick • 20 នាទី', 20, Duration(minutes: 20), false),
  _Preset('ស្តង់ដារ', 'Standard • 40 នាទី', 50, Duration(minutes: 40), false),
  _Preset('ពេញលេញ', 'Full • 90 នាទី', 100, Duration(minutes: 90), false),
];

class ExamConfigScreen extends StatefulWidget {
  final ExamMode mode;
  const ExamConfigScreen({super.key, required this.mode});

  @override
  State<ExamConfigScreen> createState() => _ExamConfigScreenState();
}

class _ExamConfigScreenState extends State<ExamConfigScreen> {
  late Set<int> _selected;
  int _count = 50;
  Duration? _time = const Duration(minutes: 40);
  bool _shuffle = true;
  bool _instantFeedback = false;
  bool _negativeMarking = false;
  bool _endAlert = true;
  int _presetIndex = 1;
  bool _initialized = false;

  List<_Preset> get _presets =>
      widget.mode == ExamMode.mock ? _mockPresets : _practicePresets;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final parts = app.parts;
    final available = parts.where((p) => p.count > 0).toList();

    if (!_initialized) {
      _selected = available.map((p) => p.id).toSet();
      if (widget.mode == ExamMode.mock) {
        _count = 50;
        _time = const Duration(minutes: 40);
      } else {
        _count = 50;
        _time = null;
        _instantFeedback = false;
      }
      _initialized = true;
    }

    final selectedCount = _selected.length;
    final maxQuestions = parts
        .where((p) => _selected.contains(p.id))
        .fold<int>(0, (s, p) => s + p.count);
    final effectiveCount = _count.clamp(
      0,
      maxQuestions == 0 ? 0 : maxQuestions,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == ExamMode.mock ? 'កំណត់ Mock Exam' : 'កំណត់ការប្រឡង',
        ),
        actions: [
          IconButton(
            onPressed: () {
              sfx.tap();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        children: [
          SectionHeader(
            title: 'Preset ប្រើឆាប់',
            subtitle: 'ចាប់ផ្ដើមលឿនជាមួយការកំណត់ស្រាប់',
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_presets.length, (i) {
              final p = _presets[i];
              final active = _presetIndex == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == _presets.length - 1 ? 0 : 8,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      sfx.select();
                      setState(() {
                        _presetIndex = i;
                        _count = p.count;
                        _time = p.time;
                        _instantFeedback = p.instantFeedback;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.mintSoft : AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: active ? AppColors.emerald : AppColors.line,
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            p.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.sub,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: AppColors.slate,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'ជ្រើសមុខវិជ្ជា',
            subtitle: 'ចុចលើមុខវិជ្ជា ដើម្បីបញ្ចូល ឬដកចេញ',
            trailing: TextButton(
              onPressed: () {
                sfx.tap();
                setState(() {
                  _selected = _selected.length == available.length
                      ? {}
                      : available.map((p) => p.id).toSet();
                });
              },
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
                      mode: SubjectTileMode.select,
                      selected: _selected.contains(parts[i].id),
                      onTap: () => setState(() {
                        if (!_selected.remove(parts[i].id)) {
                          _selected.add(parts[i].id);
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
              'បានជ្រើសរើស ${kh(selectedCount)} មុខវិជ្ជា • សរុប ${kh(maxQuestions)} សំណួរ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'រយៈពេល',
            subtitle: 'កំណត់ពេលវេលាសម្រាប់វគ្គប្រឡង',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _timeChip('៣០ នាទី', const Duration(minutes: 30)),
              _timeChip('៤០ នាទី', const Duration(minutes: 40)),
              _timeChip('៦០ នាទី', const Duration(minutes: 60)),
              _timeChip('៩០ នាទី', const Duration(minutes: 90)),
              _timeChip('គ្មានកំណត់ពេល', null),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'ចំនួនសំណួរ',
            subtitle: 'ទំហំក្រុមសំណួរសម្រាប់វគ្គនេះ',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [20, 30, 50, 100, 0].map((n) {
              final label = n == 0 ? 'ទាំងអស់' : kh(n);
              return ChoiceChip(
                label: Text(label),
                selected: _count == n,
                onSelected: (_) {
                  sfx.select();
                  setState(() => _count = n);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'លក្ខខណ្ឌប្រឡង',
            subtitle: 'កំណត់ឥរិយាបថក្នុងពេលធ្វើតេស្ត',
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  _toggleRow(
                    'ច្របល់លំដាប់សំណួរ',
                    'Shuffle Questions',
                    _shuffle,
                    (v) => setState(() => _shuffle = v),
                  ),
                  const Divider(height: 1),
                  _toggleRow(
                    'បង្ហាញចម្លើយភ្លាមៗ',
                    'Instant Feedback (មុខវិជ្ជាហ្វឹកហាត់)',
                    _instantFeedback,
                    (v) => setState(() => _instantFeedback = v),
                  ),
                  const Divider(height: 1),
                  _toggleRow(
                    'ដកពិន្ទុពេលឆ្លើយខុស',
                    'Negative Marking',
                    _negativeMarking,
                    (v) => setState(() => _negativeMarking = v),
                  ),
                  const Divider(height: 1),
                  _toggleRow(
                    'ប្រកាសព្រមានសល់ ៥ នាទី',
                    'End-time alert',
                    _endAlert,
                    (v) => setState(() => _endAlert = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 110),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_time == null ? "គ្មានកំណត់ពេល" : "${kh(_time!.inMinutes)} នាទី"} • ${kh(effectiveCount)} សំណួរ • ${kh(selectedCount)} មុខវិជ្ជា',
                style: TextStyle(fontSize: 11, color: AppColors.slate),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedCount == 0 || maxQuestions == 0
                      ? null
                      : () {
                          sfx.tap();
                          final config = ExamConfig(
                            mode: widget.mode,
                            partIds: _selected,
                            questionCount: effectiveCount == 0
                                ? maxQuestions
                                : effectiveCount,
                            timeLimit: _time,
                            shuffleQuestions: _shuffle,
                            instantFeedback: _instantFeedback,
                            negativeMarking: _negativeMarking,
                            endAlert: _endAlert,
                            presetLabel: _presets[_presetIndex].label,
                          );
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => QuizSessionScreen(config: config),
                            ),
                          );
                        },
                  child: const Text('រក្សាទុក និងចាប់ផ្ដើម →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeChip(String label, Duration? value) {
    return ChoiceChip(
      label: Text(label),
      selected: _time == value,
      onSelected: (_) {
        sfx.select();
        setState(() => _time = value);
      },
    );
  }

  Widget _toggleRow(
    String title,
    String sub,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  style: TextStyle(fontSize: 10.5, color: AppColors.slate),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              sfx.toggle(v);
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
