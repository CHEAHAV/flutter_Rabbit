import 'package:flutter/material.dart';

import '../models/exam_part.dart';
import '../theme/app_theme.dart';

/// The rung a subject sits on, drawn as a small pill: five bars filled up to
/// the level, then its Khmer name.
///
/// [PartLevel.allLevels] is not on the ladder, so it gets no bars and an amber
/// pill instead of an emerald one - the point is that it is beside the ladder,
/// not above or below it.
class LevelChip extends StatelessWidget {
  final PartLevel level;

  /// Drops the name and keeps only the bars, for rows too narrow for both.
  final bool barsOnly;

  const LevelChip({super.key, required this.level, this.barsOnly = false});

  @override
  Widget build(BuildContext context) {
    final step = level.step;
    final onLadder = step != null;
    final fg = onLadder ? AppColors.emerald : AppColors.amber;
    final bg = onLadder ? AppColors.mint : AppColors.amberBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onLadder)
            for (var i = 0; i < 5; i++)
              Padding(
                padding: EdgeInsets.only(right: i == 4 ? 0 : 1.5),
                child: Container(
                  width: 2.5,
                  height: 4.0 + i * 1.5,
                  decoration: BoxDecoration(
                    color: i < step
                        ? fg
                        : fg.withValues(alpha: AppColors.isDark ? 0.3 : 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )
          else
            Icon(Icons.all_inclusive_rounded, size: 11, color: fg),
          if (!barsOnly) ...[
            const SizedBox(width: 5),
            // Flexible so the badge gives way on a narrow screen rather than
            // pushing past the edge of the row it sits in.
            Flexible(
              child: Text(
                level.badgeKm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
