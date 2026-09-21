import 'package:flutter/material.dart';

import '../models/exam_part.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';

/// The heading above one course's subjects.
///
/// The bank mixes a Khmer civil-service syllabus with three English courses.
/// Listed flat they read as one syllabus of twenty-six unrelated subjects, so
/// every list of subjects in the app is broken by course and carries this
/// heading, which names the course and says how much is in it.
class TrackHeader extends StatelessWidget {
  final PartTrack track;
  final int subjectCount;
  final int questionCount;

  /// Optional action on the right, such as "select all in this course".
  final Widget? trailing;

  const TrackHeader({
    super.key,
    required this.track,
    required this.subjectCount,
    required this.questionCount,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.mintSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(track.icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.titleKm,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${kh(subjectCount)} មុខវិជ្ជា • ${kh(questionCount)} សំណួរ',
                  style: TextStyle(fontSize: 10.5, color: AppColors.slate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
