import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_config.dart';
import '../models/exam_part.dart';
import '../services/sound_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/section_header.dart';
import '../widgets/subject_tile.dart';
import '../widgets/track_header.dart';
import 'exam_config_screen.dart';
import 'quiz_session_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  /// Questions per session; 0 means "every question in the subject".
  int _count = 20;

  /// Which course the subject list is narrowed to; null shows them all.
  PartTrack? _track;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final available = app.partsWithQuestions;
    final totalAvailable = available.fold<int>(0, (sum, p) => sum + p.count);
    // What is actually still on offer: a session never repeats a question the
    // user has answered, so this - not the raw total - is what the page counts.
    final totalRemaining = app.remainingInParts(available);
    final tracks = app.tracks;
    final shownTracks = _track == null
        ? tracks
        : tracks.where((t) => t == _track).toList();

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
                    'ចំណេះដឹងទូទៅ និងភាសាអង់គ្លេស',
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
              onPressed: () => sfx.tap(),
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
                totalRemaining == totalAvailable
                    ? 'មានសំណួរសរុប ${kh(app.repo.totalQuestionCount)} សំណួរ ក្នុង ${kh(tracks.length)} វគ្គសិក្សា • ${kh(available.length)} មុខវិជ្ជា'
                    : 'នៅសល់ ${kh(totalRemaining)} សំណួរថ្មី ក្នុងចំណោម ${kh(totalAvailable)} • ${kh(available.length)} មុខវិជ្ជា',
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
                      onPressed: () {
                        sfx.tap();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ExamConfigScreen(mode: ExamMode.practice),
                          ),
                        );
                      },
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
                      onPressed: totalRemaining == 0
                          ? null
                          : () => _launchMixed(context, available),
                      icon: const Icon(Icons.shuffle_rounded),
                      label: const Text('ចម្រុះ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'ចំនួនសំណួរក្នុងវគ្គ',
          subtitle: 'អនុវត្តនៅពេលអ្នកចុចលើមុខវិជ្ជាណាមួយ',
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
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'មុខវិជ្ជាសម្រាប់ហ្វឹកហាត់',
          subtitle: 'ជ្រើសវគ្គសិក្សា រួចចុចលើកម្រិតណាមួយ ដើម្បីចូលឆ្លើយភ្លាម',
        ),
        const SizedBox(height: 10),
        _trackFilter(tracks),
        const SizedBox(height: 14),
        for (final track in shownTracks) ...[
          _trackBlock(context, app, track),
          const SizedBox(height: 18),
        ],
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            'មាន ${kh(available.length)} មុខវិជ្ជាត្រៀមរួច • នៅសល់ ${kh(totalRemaining)}/${kh(totalAvailable)} សំណួរ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
        ),
      ],
    );
  }

  /// The course switcher. "ទាំងអស់" is first and selected by default, so the
  /// browser still opens on everything the app has; the other chips narrow it
  /// to one course rather than hiding anything permanently.
  Widget _trackFilter(List<PartTrack> tracks) {
    // Wrapped, not scrolled sideways: a horizontal strip inside this vertical
    // list would hide courses off the right edge and put a second Scrollable
    // in the page.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('គ្រប់វគ្គសិក្សា'),
          selected: _track == null,
          onSelected: (_) {
            sfx.select();
            setState(() => _track = null);
          },
        ),
        for (final track in tracks)
          ChoiceChip(
            avatar: Text(track.icon, style: const TextStyle(fontSize: 13)),
            label: Text(track.titleKm),
            selected: _track == track,
            onSelected: (_) {
              sfx.select();
              setState(() => _track = track);
            },
          ),
      ],
    );
  }

  /// One course: its heading, then its subjects in order of rising level.
  Widget _trackBlock(BuildContext context, AppState app, PartTrack track) {
    final parts = app.partsIn(track);
    final ready = parts.where((p) => p.count > 0).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrackHeader(
          track: track,
          subjectCount: ready.length,
          questionCount: ready.fold<int>(0, (sum, p) => sum + p.count),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (var i = 0; i < parts.length; i++) ...[
                  SubjectTile(
                    part: parts[i],
                    accuracy: app.progress.statFor(parts[i].id).answered > 0
                        ? app.progress.statFor(parts[i].id).accuracy
                        : null,
                    remaining: app.remainingIn(parts[i]),
                    onTap: () => _launchPart(context, app, parts[i]),
                  ),
                  if (i != parts.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Opens a single subject straight into the question screen — the one-tap
  /// path this list is built around. [SubjectTile] already played the tap
  /// sound and blocks subjects with no questions.
  ///
  /// The session is sized by what is *left* in the subject, never by its raw
  /// total: a subject of 200 with 50 answered offers the other 150. Once none
  /// are left the subject cannot start at all, so the tap offers to clear that
  /// subject's answered memory instead of opening an empty session.
  void _launchPart(BuildContext context, AppState app, ExamPart part) {
    final remaining = app.remainingIn(part);
    if (remaining == 0) {
      _offerRestart(context, app, part);
      return;
    }
    _start(context, {part.id}, remaining, part.titleKm);
  }

  /// Every available subject mixed into one session, again only over the
  /// questions that are still unanswered.
  void _launchMixed(BuildContext context, List<ExamPart> available) {
    sfx.tap();
    final app = context.read<AppState>();
    _start(
      context,
      available.map((p) => p.id).toSet(),
      app.remainingInParts(available),
      'ហ្វឹកហាត់ចម្រុះ',
    );
  }

  /// Asked when a finished subject is tapped: answering it again means going
  /// back over questions already seen, so it is never done silently.
  Future<void> _offerRestart(
    BuildContext context,
    AppState app,
    ExamPart part,
  ) async {
    final restart = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${part.titleKm} — ឆ្លើយគ្រប់ហើយ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'អ្នកបានឆ្លើយសំណួរទាំង ${kh(part.count)} ក្នុងមុខវិជ្ជានេះរួចហើយ។ '
              'បើចាប់ផ្ដើមឡើងវិញ កម្មវិធីនឹងបង្ហាញសំណួរទាំងនោះម្តងទៀត។ '
              'ពិន្ទុ និងប្រវត្តិការឆ្លើយរបស់អ្នកមិនបាត់ទេ។',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.slate,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      sfx.tap();
                      Navigator.of(ctx).pop(false);
                    },
                    child: const Text('ចាកចេញ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      sfx.tap();
                      Navigator.of(ctx).pop(true);
                    },
                    child: const Text('ចាប់ផ្ដើមឡើងវិញ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (restart != true || !context.mounted) return;
    await app.progress.resetAnswered({part.id});
    app.refresh();
    if (!context.mounted) return;
    _start(context, {part.id}, part.count, part.titleKm);
  }

  void _start(
    BuildContext context,
    Set<int> partIds,
    int poolSize,
    String label,
  ) {
    if (poolSize == 0) return;
    final count = _count == 0 ? poolSize : _count.clamp(1, poolSize);
    final config = ExamConfig(
      mode: ExamMode.practice,
      partIds: partIds,
      questionCount: count,
      timeLimit: null,
      shuffleQuestions: true,
      instantFeedback: true,
      presetLabel: label,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizSessionScreen(config: config)),
    );
  }
}
