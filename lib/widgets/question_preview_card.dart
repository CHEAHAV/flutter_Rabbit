import 'package:flutter/material.dart';

import '../models/question.dart';
import '../theme/app_theme.dart';

/// One saved/mistaken question as it appears in the notebook: the question,
/// every option with the right one marked, and the bookmark toggle that puts
/// it on - or takes it off - the saved shelf.
///
/// Never instantiate it with `const`: [AppColors] is the app's mutable palette
/// and a const instance would keep whichever theme it was first built under.
class QuestionPreviewCard extends StatelessWidget {
  final Question question;
  final String partTitle;
  final bool saved;
  final VoidCallback onToggleSave;

  const QuestionPreviewCard({
    super.key,
    required this.question,
    required this.partTitle,
    required this.saved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        partTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: saved ? 'ដកចេញពីបញ្ជីរក្សាទុក' : 'រក្សាទុក',
                    onPressed: onToggleSave,
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                question.text,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.55,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < question.options.length; i++) _option(i),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '✓ ចម្លើយត្រឹមត្រូវ៖ ${question.correctOptionText}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Option [i], with the correct one in emerald so the card can be studied
  /// from without opening a session.
  Widget _option(int i) {
    final isAnswer = i == question.answerIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Unlettered: in a session these options come in a shuffled
            // order, so a letter here would not match what the quiz shows.
            '•  ',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isAnswer ? FontWeight.w800 : FontWeight.w500,
              color: isAnswer ? AppColors.emerald : AppColors.slate,
            ),
          ),
          Expanded(
            child: Text(
              question.options[i],
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                fontWeight: isAnswer ? FontWeight.w800 : FontWeight.w500,
                color: isAnswer ? AppColors.emerald : AppColors.ink,
              ),
            ),
          ),
          if (isAnswer)
            Icon(
              Icons.check_circle_rounded,
              size: 15,
              color: AppColors.emerald,
            ),
        ],
      ),
    );
  }
}
