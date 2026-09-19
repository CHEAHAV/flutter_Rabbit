import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';

enum OptionState { neutral, selected, correct, wrong }

class OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  /// The alphabet the option key is drawn from - ក/ខ/គ/ឃ for the Khmer parts,
  /// A/B/C/D/E for the English ones. See [Question.optionLabels].
  final List<String> labels;

  const OptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.state,
    this.onTap,
    this.labels = khmerOptionLabels,
  });

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.line;
    Color bg = AppColors.card;
    Color keyBg = AppColors.card;
    Color keyFg = AppColors.ink;
    Color keyBorder = AppColors.line;
    IconData? trailingIcon;
    Color trailingColor = AppColors.emerald;

    switch (state) {
      case OptionState.neutral:
        break;
      case OptionState.selected:
        border = AppColors.emerald;
        bg = AppColors.mintSoft;
        keyBg = AppColors.emerald;
        keyFg = AppColors.onEmerald;
        keyBorder = AppColors.emerald;
        break;
      case OptionState.correct:
        border = AppColors.emerald;
        bg = AppColors.mint;
        keyBg = AppColors.emerald;
        keyFg = AppColors.onEmerald;
        keyBorder = AppColors.emerald;
        trailingIcon = Icons.check_circle_rounded;
        trailingColor = AppColors.emerald;
        break;
      case OptionState.wrong:
        border = AppColors.red;
        bg = AppColors.redBg;
        keyBg = AppColors.red;
        keyFg = AppColors.onRed;
        keyBorder = AppColors.red;
        trailingIcon = Icons.cancel_rounded;
        trailingColor = AppColors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: border,
                width: state == OptionState.neutral ? 1 : 2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: keyBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: keyBorder),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: keyFg,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: trailingColor, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
