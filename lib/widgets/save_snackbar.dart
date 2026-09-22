import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Confirms that a question has just been put on - or taken off - the
/// notebook's saved shelf, and offers the two choices the change deserves:
/// **ត្រឡប់វិញ** puts it back the way it was, **មិនត្រឡប់វិញ** keeps the change.
///
/// Shown as a floating card rather than a plain snackbar: the bar's own
/// background and padding are switched off and the whole thing is drawn here,
/// in the app's card language - surface, hairline border, rounded corners, a
/// tinted icon chip and the same two-button footer the exit and submit sheets
/// use. A snackbar's `action` slot holds exactly one button anyway, so a
/// second choice has to be built into the content regardless.
///
/// It floats rather than blocks on purpose: saving a question is not a
/// decision worth freezing the screen for, and the user can ignore the card
/// and read on. Every screen that can save a question calls this one function,
/// so the wording, the look and the two choices are identical in the quiz, the
/// notebook and the review.
void showSaveChoiceSnackBar(
  BuildContext context, {
  required bool saved,
  required VoidCallback onUndo,
}) {
  final messenger = ScaffoldMessenger.of(context);
  // One card at a time: saving twice in a row should replace the note, not
  // queue a second one behind it whose undo is already out of date.
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      // Long enough to read two lines of Khmer and make a choice, and the
      // card is dismissible by swipe before then.
      duration: const Duration(seconds: 8),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      content: _SaveCard(
        saved: saved,
        onUndo: () {
          sfx.tap();
          messenger.hideCurrentSnackBar();
          onUndo();
        },
        onKeep: () {
          sfx.tap();
          messenger.hideCurrentSnackBar();
        },
      ),
    ),
  );
}

/// The card itself. Never instantiate it with `const`: its build reads
/// [AppColors], the palette the theme switch mutates in place, and a const
/// instance would keep the colours of the theme it was first built under.
class _SaveCard extends StatelessWidget {
  final bool saved;
  final VoidCallback onUndo;
  final VoidCallback onKeep;

  const _SaveCard({
    required this.saved,
    required this.onUndo,
    required this.onKeep,
  });

  @override
  Widget build(BuildContext context) {
    final accent = saved ? AppColors.gold : AppColors.red;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.5 : 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: saved ? AppColors.amberBg : AppColors.redBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: saved ? AppColors.amberBorder : AppColors.redBorder,
                  ),
                ),
                child: Icon(
                  saved
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_remove_rounded,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saved ? 'បានរក្សាទុកសំណួរ' : 'បានដកសំណួរចេញ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      saved
                          ? 'សំណួរ និងចម្លើយនេះនៅក្នុង សៀវភៅកត់ត្រា › បានរក្សាទុក រហូតដល់អ្នកដកវាចេញ។'
                          : 'សំណួរនេះលែងនៅក្នុងបញ្ជីរក្សាទុកទៀតហើយ។',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.55,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onUndo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: AppColors.line, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: _label('ត្រឡប់វិញ'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onKeep,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: _label('មិនត្រឡប់វិញ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shrinks rather than overflows: the two Khmer labels are not the same
  /// length, and half of a 320px card is not much room for the longer one.
  Widget _label(String text) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      text,
      maxLines: 1,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );
}
