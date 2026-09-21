import 'package:flutter/material.dart';

import '../models/exam_part.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';
import 'level_chip.dart';

/// What tapping a [SubjectTile] does.
enum SubjectTileMode {
  /// The row is a doorway: one tap opens that subject and starts answering it.
  /// Used by the practice list, where subjects are taken one at a time.
  open,

  /// The row adds/removes the subject from a multi-subject selection. Used by
  /// the exam configuration screen, where a session mixes several subjects.
  select,
}

/// One subject row. Neither mode uses a [Switch]: in [SubjectTileMode.open]
/// the whole row is a button that leads into the questions, and in
/// [SubjectTileMode.select] the row itself toggles a check mark.
class SubjectTile extends StatelessWidget {
  final ExamPart part;
  final SubjectTileMode mode;

  /// Only meaningful in [SubjectTileMode.select].
  final bool selected;

  /// Fired on tap; ignored when the subject has no questions yet.
  final VoidCallback onTap;

  /// 0..1 mastery indicator, omitted when the subject was never answered.
  final double? accuracy;

  const SubjectTile({
    super.key,
    required this.part,
    required this.onTap,
    this.mode = SubjectTileMode.open,
    this.selected = false,
    this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = part.count == 0;
    final isSelect = mode == SubjectTileMode.select;
    final highlight = isSelect && selected && !disabled;

    return InkWell(
      onTap: disabled
          ? null
          : () {
              if (isSelect) {
                sfx.toggle(!selected);
              } else {
                sfx.tap();
              }
              onTap();
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
                color: disabled ? AppColors.line : AppColors.mint,
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
                      color: disabled
                          ? AppColors.muted
                          : highlight
                          ? AppColors.emerald
                          : AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Wrapped rather than a Row: the level names are long in
                  // Khmer and must fall onto a second line on a narrow phone
                  // instead of overflowing.
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (part.level != null && !disabled)
                        LevelChip(level: part.level!),
                      Text(
                        disabled
                            ? 'មិនទាន់មានទិន្នន័យ'
                            : '${kh(part.count)} សំណួរ',
                        style: TextStyle(fontSize: 11, color: AppColors.slate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (accuracy != null && !disabled)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _AccuracyChip(accuracy: accuracy!),
              ),
            _Trailing(mode: mode, selected: selected, disabled: disabled),
          ],
        ),
      ),
    );
  }
}

/// The affordance at the end of the row: a chevron that says "tap to open",
/// or a check mark that says "included in this exam".
class _Trailing extends StatelessWidget {
  final SubjectTileMode mode;
  final bool selected;
  final bool disabled;

  const _Trailing({
    required this.mode,
    required this.selected,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.lock_outline_rounded, size: 17, color: AppColors.muted),
      );
    }

    if (mode == SubjectTileMode.open) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: AppColors.emerald,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? AppColors.emerald : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.emerald : AppColors.line,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
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
