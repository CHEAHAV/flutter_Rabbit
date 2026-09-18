import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/exam_part.dart';
import '../models/question.dart';

/// Loads the bundled Khmer QCM question bank (13 parts) from
/// assets/data/part_XX.json and exposes it in memory for the rest of the app.
class QuestionRepository {
  QuestionRepository._();
  static final QuestionRepository instance = QuestionRepository._();

  List<ExamPart> _parts = const [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<ExamPart> get parts => _parts;

  int get totalQuestionCount => _parts.fold(0, (sum, p) => sum + p.count);

  ExamPart partById(int id) => _parts.firstWhere((p) => p.id == id);

  Question? questionByUid(String uid) {
    final parts = uid.split('-');
    if (parts.length != 2) return null;
    final partId = int.tryParse(parts[0]);
    final qId = int.tryParse(parts[1]);
    if (partId == null || qId == null) return null;
    for (final q in partById(partId).questions) {
      if (q.id == qId) return q;
    }
    return null;
  }

  Future<void> load() async {
    if (_loaded) return;
    final loaded = <ExamPart>[];
    for (var i = 0; i < ExamPart.catalog.length; i++) {
      final partId = i + 1;
      final meta = ExamPart.catalog[i];
      final fileName = 'assets/data/part_${partId.toString().padLeft(2, '0')}.json';
      List<Question> questions = const [];
      try {
        final raw = await rootBundle.loadString(fileName);
        final list = jsonDecode(raw) as List;
        questions = list
            .map((e) => Question.fromJson(e as Map<String, dynamic>, partId))
            .toList();
      } catch (_) {
        // Missing/empty data file for this part — treat as not-yet-available.
        questions = const [];
      }
      loaded.add(ExamPart(
        id: partId,
        titleKm: meta['title']!,
        titleEn: meta['en']!,
        icon: meta['icon']!,
        questions: questions,
      ));
    }
    _parts = loaded;
    _loaded = true;
  }
}
