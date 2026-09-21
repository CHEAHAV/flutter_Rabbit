// Re-cutting the English bank renumbered parts 14-24 into parts 14-26, so any
// progress saved against the old numbering now points at questions that are no
// longer there. ProgressService drops exactly that and nothing else.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rabbit/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Progress as an install from before the re-cut would have left it: no
  /// revision marker, stats and notes for both banks.
  Map<String, Object> oldInstall() => {
    'rabbit.partStats': jsonEncode({
      '3': {'answered': 40, 'correct': 30},
      '14': {'answered': 80, 'correct': 20},
      '24': {'answered': 10, 'correct': 9},
    }),
    'rabbit.mistakes': ['3-7', '14-102', '24-5'],
    'rabbit.bookmarks': ['5-1', '19-44'],
    'rabbit.goalPartId': 20,
    'rabbit.totalAnswered': 130,
    'rabbit.totalCorrect': 59,
  };

  Future<ProgressService> load(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final progress = ProgressService.instance;
    progress.resetForTesting();
    await progress.init();
    return progress;
  }

  test('progress from the old English numbering is dropped', () async {
    final progress = await load(oldInstall());

    expect(
      progress.partStats.keys,
      [3],
      reason: 'only the Khmer subject keeps its stats',
    );
    expect(progress.mistakeUids, {'3-7'});
    expect(progress.bookmarkUids, {'5-1'});
    expect(
      progress.goalPartId,
      isNull,
      reason: 'a goal pointing at a renumbered subject is meaningless',
    );
  });

  test('lifetime totals survive the re-cut', () async {
    // They record what the user answered, which re-filing the bank does not
    // undo - wiping them would tell an established user they had done nothing.
    final progress = await load(oldInstall());
    expect(progress.totalAnswered, 130);
    expect(progress.totalCorrect, 59);
  });

  test('the drop happens once and is not repeated', () async {
    final first = await load(oldInstall());
    expect(first.partStats.keys, [3]);

    // Second launch: the marker is stored, and progress made since - including
    // on the new English parts - must survive.
    SharedPreferences.setMockInitialValues({
      'rabbit.bankRevision': ProgressService.bankRevision,
      'rabbit.partStats': jsonEncode({
        '14': {'answered': 12, 'correct': 11},
      }),
      'rabbit.mistakes': ['26-3'],
      'rabbit.bookmarks': ['18-2'],
    });
    final progress = ProgressService.instance;
    progress.resetForTesting();
    await progress.init();

    expect(progress.partStats.keys, [14]);
    expect(progress.mistakeUids, {'26-3'});
    expect(progress.bookmarkUids, {'18-2'});
  });

  test('a fresh install is marked as current without losing anything', () async {
    final progress = await load({});
    expect(progress.partStats, isEmpty);
    expect(progress.mistakeUids, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('rabbit.bankRevision'), ProgressService.bankRevision);
  });
}
