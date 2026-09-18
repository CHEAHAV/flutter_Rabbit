import 'package:flutter/material.dart';
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
                    gradient: const LinearGradient(colors: [Color(0xFFD8ECE0), Color(0xFFBCD9C7)]),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  alignment: Alignment.center,
                  child: const Text('🐇', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                Text(progress.displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('សិស្សត្រៀមប្រឡងមន្ត្រីរាជការ', style: TextStyle(fontSize: 11.5, color: AppColors.slate)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: const Color(0xFFFFF7E7), borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    '🔥 រៀនជាប់គ្នា ${kh(progress.streak)} ថ្ងៃ',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF865800)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'សន្ទស្សន៍ត្រៀមប្រឡង', subtitle: 'គណនាពីភាពត្រឹមត្រូវ និងភាពគ្របដណ្តប់មេរៀន'),
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
                    Expanded(child: StatBox(value: kh(app.progress.history.length), label: 'វគ្គប្រឡងរួច')),
                    const SizedBox(width: 8),
                    Expanded(child: StatBox(value: kh(progress.totalAnswered), label: 'សំណួរបានឆ្លើយ')),
                    const SizedBox(width: 8),
                    Expanded(child: StatBox(value: khPercent((progress.overallAccuracy * 100)), label: 'ភាពត្រឹមត្រូវ')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'សមត្ថភាពតាមមុខវិជ្ជា', subtitle: 'ស្គាល់ចំណុចខ្លាំង និងចំណុចត្រូវពង្រឹង'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                for (final part in partsWithData) ...[
                  _CompetencyRow(title: part.titleKm, stat: progress.statFor(part.id)),
                  if (part != partsWithData.last) const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'អំពីទិន្នន័យ', subtitle: 'ប្រភពសំណួរ និងកំណែកម្មវិធី'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _infoRow(Icons.menu_book_rounded, 'ធនាគារសំណួរ', '${kh(app.repo.totalQuestionCount)} សំណួរ • ១៣ ផ្នែក'),
              const Divider(height: 1),
              _infoRow(Icons.storage_rounded, 'ការផ្ទុកទិន្នន័យ', 'រក្សាទុកនៅលើឧបករណ៍ ក្នុងទម្រង់ Offline'),
              const Divider(height: 1),
              _infoRow(Icons.info_outline_rounded, 'កំណែកម្មវិធី', 'Rabbit v1.0.0'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.emerald, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 10.5, color: AppColors.slate)),
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
              child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Text(
              answered == 0 ? 'មិនទាន់ហ្វឹកហាត់' : '${kh(pct)}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: answered == 0 ? 0 : accuracy,
            minHeight: 8,
            backgroundColor: const Color(0xFFE7EEEA),
            color: color,
          ),
        ),
      ],
    );
  }
}
