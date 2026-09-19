import 'package:flutter/material.dart';

import '../models/exam_part.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';

class SubjectTile extends StatelessWidget {
  final ExamPart part;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final double? accuracy; // 0..1, optional mastery indicator

  const SubjectTile({
    super.key,
    required this.part,
    required this.selected,
    required this.onChanged,
    this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = part.count == 0;
    return InkWell(
      onTap: disabled
          ? null
          : () {
              sfx.toggle(!selected);
              onChanged(!selected);
            },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(part.icon, style: const TextStyle(fontSize: 19)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part.titleKm,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: disabled ? AppColors.muted : AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    disabled ? 'មិនទាន់មានទិន្នន័យ' : '${kh(part.count)} សំណួរ',
                    style: TextStyle(fontSize: 11, color: AppColors.slate),
                  ),
                ],
              ),
            ),
            if (accuracy != null && !disabled) ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _AccuracyChip(accuracy: accuracy!),
              ),
            ],
            Switch(
              value: selected && !disabled,
              onChanged: disabled
                  ? null
                  : (v) {
                      sfx.toggle(v);
                      onChanged(v);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _AccuracyChip extends StatelessWidget {
  final double accuracy;
  const _AccuracyChip({required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final pct = (accuracy * 100).round();
    final color = accuracy >= 0.75
        ? AppColors.emerald
        : accuracy >= 0.5
        ? AppColors.amber
        : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${kh(pct)}%',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
