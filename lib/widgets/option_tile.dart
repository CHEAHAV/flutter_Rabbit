import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';

enum OptionState { neutral, selected, correct, wrong }

class OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  const OptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.line;
    Color bg = Colors.white;
    Color keyBg = Colors.white;
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
        keyFg = Colors.white;
        keyBorder = AppColors.emerald;
        break;
      case OptionState.correct:
        border = AppColors.emerald;
        bg = AppColors.mint;
        keyBg = AppColors.emerald;
        keyFg = Colors.white;
        keyBorder = AppColors.emerald;
        trailingIcon = Icons.check_circle_rounded;
        trailingColor = AppColors.emerald;
        break;
      case OptionState.wrong:
        border = AppColors.red;
        bg = AppColors.redBg;
        keyBg = AppColors.red;
        keyFg = Colors.white;
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
              border: Border.all(color: border, width: state == OptionState.neutral ? 1 : 2),
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
                    khmerOptionLabels[index],
                    style: TextStyle(fontWeight: FontWeight.w800, color: keyFg, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(text, style: const TextStyle(fontSize: 14, height: 1.55)),
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
