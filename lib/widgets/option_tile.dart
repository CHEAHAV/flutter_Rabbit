import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
    Color bg = AppColors.card;
    Color keyBg = AppColors.card;
    Color keyFg = AppColors.ink;
    Color keyBorder = AppColors.line;

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
        break;
      case OptionState.wrong:
        border = AppColors.red;
        bg = AppColors.redBg;
        keyBg = AppColors.red;
        keyFg = AppColors.onRed;
        keyBorder = AppColors.red;
        break;
    }

    // Options are never lettered - they are shuffled every session, so a
    // ក/ខ/គ/ឃ or A-E would name a different answer each time. The key is a
    // radio-style marker instead: an empty ring, a dot once chosen, and a tick
    // or a cross once checked.
    final Widget marker = switch (state) {
      OptionState.neutral => const SizedBox.shrink(),
      OptionState.selected => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: keyFg, shape: BoxShape.circle),
      ),
      OptionState.correct => Icon(Icons.check_rounded, size: 16, color: keyFg),
      OptionState.wrong => Icon(Icons.close_rounded, size: 16, color: keyFg),
    };

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
                // A 24px ring in the 30px slot the option text is aligned to.
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.all(3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: keyBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: state == OptionState.neutral
                          ? AppColors.muted
                          : keyBorder,
                      width: 2,
                    ),
                  ),
                  child: marker,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
