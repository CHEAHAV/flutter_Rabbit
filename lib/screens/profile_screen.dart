import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import '../widgets/readiness_gauge.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_box.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final progress = app.progress;
    final partsWithData = app.parts.where((p) => p.count > 0).toList();
    final readiness = progress.readinessIndex(partsWithData.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.isDark
                          ? const [Color(0xFF1B3327), Color(0xFF14261D)]
                          : const [Color(0xFFD8ECE0), Color(0xFFBCD9C7)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.card, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('🐇', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                Text(
                  progress.displayName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ចំណេះដឹងទូទៅ',
                  style: TextStyle(fontSize: 11.5, color: AppColors.slate),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amberBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '🔥 រៀនជាប់គ្នា ${kh(progress.streak)} ថ្ងៃ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.isDark
                          ? AppColors.amber
                          : const Color(0xFF865800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'រូបរាង',
          subtitle: 'ជ្រើសរបៀបបង្ហាញដែលអ្នកចូលចិត្ត',
        ),
        const SizedBox(height: 10),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              app.sound.toggle(!app.isDarkMode);
              app.setDarkMode(!app.isDarkMode);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: app.isDarkMode
                          ? AppColors.mint
                          : AppColors.amberBg,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: app.isDarkMode
                            ? AppColors.line
                            : AppColors.amberBorder,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        app.isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        key: ValueKey(app.isDarkMode),
                        color: app.isDarkMode
                            ? AppColors.emerald
                            : AppColors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ម៉ូដងងឹត (Dark Mode)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            app.isDarkMode
                                ? 'កំពុងបើក — ងាយស្រួលមើលពេលយប់'
                                : 'បិទ — កំពុងប្រើពន្លឺធម្មតា',
                            key: ValueKey(app.isDarkMode),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SmoothSwitchPill(
                    value: app.isDarkMode,
                    onIcon: Icons.dark_mode_rounded,
                    offIcon: Icons.light_mode_rounded,
                    onIconColor: AppColors.emeraldDeep,
                    offIconColor: AppColors.amber,
                    onChanged: (v) {
                      app.sound.toggle(v);
                      app.setDarkMode(v);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'សំឡេង',
          subtitle: 'សំឡេងពេលចុចប៊ូតុង ឆ្លើយត្រូវ និងឆ្លើយខុស',
        ),
        const SizedBox(height: 10),
        _SoundCard(app: app),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'សន្ទស្សន៍ត្រៀមប្រឡង',
          subtitle: 'គណនាពីភាពត្រឹមត្រូវ និងភាពគ្របដណ្តប់មេរៀន',
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ReadinessGauge(value: readiness),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: StatBox(
                        value: kh(app.progress.history.length),
                        label: 'វគ្គប្រឡងរួច',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatBox(
                        value: kh(progress.totalAnswered),
                        label: 'សំណួរបានឆ្លើយ',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatBox(
                        value: khPercent((progress.overallAccuracy * 100)),
                        label: 'ភាពត្រឹមត្រូវ',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'សមត្ថភាពតាមមុខវិជ្ជា',
          subtitle: 'ស្គាល់ចំណុចខ្លាំង និងចំណុចត្រូវពង្រឹង',
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _competencyRows(app),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'អំពីទិន្នន័យ',
          subtitle: 'ប្រភពសំណួរ និងកំណែកម្មវិធី',
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _infoRow(
                Icons.menu_book_rounded,
                'សំណួរទាំងអស់ដែលមាន',
                '${kh(app.repo.totalQuestionCount)} សំណួរ • ${kh(app.partsWithQuestions.length)} ផ្នែក',
              ),
              const Divider(height: 1),
              _infoRow(
                Icons.storage_rounded,
                'ការផ្ទុកទិន្នន័យ',
                'រក្សាទុកនៅលើឧបករណ៍ ក្នុងទម្រង់ Offline',
              ),
              const Divider(height: 1),
              _infoRow(
                Icons.info_outline_rounded,
                'កំណែកម្មវិធី',
                'Rabbit v1.0.0',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Per-subject mastery, broken by course. Twenty-six bars in a row tell the
  /// user nothing about where they are strong; under a course heading, and in
  /// order of rising level, the same bars show exactly how far up each course
  /// they have got.
  List<Widget> _competencyRows(AppState app) {
    final rows = <Widget>[];
    for (final track in app.tracks) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 20));
      rows.add(
        Row(
          children: [
            Text(track.icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                track.titleKm,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
      for (final part in app.partsIn(track).where((p) => p.count > 0)) {
        rows.add(const SizedBox(height: 14));
        rows.add(
          _CompetencyRow(
            title: part.titleKm,
            stat: app.progress.statFor(part.id),
          ),
        );
      }
    }
    return rows;
  }

  Widget _infoRow(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.emerald, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(fontSize: 10.5, color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetencyRow extends StatelessWidget {
  final String title;
  final dynamic stat; // PartStat
  const _CompetencyRow({required this.title, required this.stat});

  @override
  Widget build(BuildContext context) {
    final accuracy = (stat.accuracy as double);
    final answered = stat.answered as int;
    final pct = (accuracy * 100).round();
    final color = answered == 0
        ? AppColors.muted
        : accuracy >= 0.75
        ? AppColors.emerald
        : accuracy >= 0.5
        ? AppColors.amber
        : AppColors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              answered == 0 ? 'មិនទាន់ហ្វឹកហាត់' : '${kh(pct)}%',
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
            value: answered == 0 ? 0 : accuracy,
            minHeight: 8,
            backgroundColor: AppColors.line,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Sound settings: master on/off switch plus a volume slider with a mute
/// button and live percentage - the layout used by phone OS volume controls.
/// Not instantiated with `const` because it reads [AppColors].
class _SoundCard extends StatelessWidget {
  final AppState app;
  const _SoundCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final muted = app.soundMuted;
    final volume = app.soundVolume;
    final percent = (volume * 100).round();
    final accent = muted ? AppColors.muted : AppColors.emerald;
    final icon = muted
        ? Icons.volume_off_rounded
        : volume < 0.34
        ? Icons.volume_mute_rounded
        : volume < 0.67
        ? Icons.volume_down_rounded
        : Icons.volume_up_rounded;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              app.setSoundEnabled(muted);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: muted ? AppColors.line : AppColors.mint,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        icon,
                        key: ValueKey(icon),
                        color: accent,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'សំឡេងកម្មវិធី (Sound)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            muted
                                ? 'បិទ — គ្មានសំឡេង'
                                : 'កំពុងបើក — កម្រិត ${khPercent(percent)}',
                            key: ValueKey(muted ? -1 : percent),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SmoothSwitchPill(
                    value: !muted,
                    onIcon: Icons.volume_up_rounded,
                    offIcon: Icons.volume_off_rounded,
                    onIconColor: AppColors.emeraldDeep,
                    offIconColor: AppColors.slate,
                    onChanged: (on) => app.setSoundEnabled(on),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.volume_mute_rounded,
                    size: 20,
                    color: AppColors.slate,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: accent,
                      inactiveTrackColor: AppColors.line,
                      thumbColor: accent,
                      overlayColor: accent.withValues(alpha: 0.14),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 11,
                        elevation: 2,
                      ),
                    ),
                    child: Slider(
                      value: volume,
                      divisions: 20,
                      semanticFormatterCallback: (v) =>
                          'កម្រិតសំឡេង ${(v * 100).round()} ភាគរយ',
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        app.setSoundVolume(v, persist: false);
                      },
                      onChangeEnd: (v) {
                        app.setSoundVolume(v);
                        // Let the user hear the new level (like iOS/Android).
                        app.sound.select();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 44,
                  child: Text(
                    khPercent(percent),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: muted ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmoothSwitchPill extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData onIcon;
  final IconData offIcon;
  final Color onIconColor;
  final Color offIconColor;

  const _SmoothSwitchPill({
    required this.value,
    required this.onChanged,
    required this.onIcon,
    required this.offIcon,
    required this.onIconColor,
    required this.offIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value
              ? AppColors.emerald
              : (AppColors.isDark
                    ? const Color(0xFF23342B)
                    : const Color(0xFFE2EBE5)),
          border: Border.all(
            color: value ? AppColors.emerald : AppColors.line,
            width: 1.2,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  value ? onIcon : offIcon,
                  key: ValueKey(value),
                  size: 13,
                  color: value ? onIconColor : offIconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
