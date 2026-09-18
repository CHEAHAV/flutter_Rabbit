import 'package:flutter/foundation.dart';

import '../data/question_repository.dart';
import '../models/exam_part.dart';
import '../services/progress_service.dart';

/// Root application state: bootstraps the question bank + local progress
/// store, and exposes them to the widget tree via Provider.
class AppState extends ChangeNotifier {
  final QuestionRepository repo = QuestionRepository.instance;
  final ProgressService progress = ProgressService.instance;

  bool _booting = true;
  String? _bootError;

  bool get booting => _booting;
  String? get bootError => _bootError;

  List<ExamPart> get parts => repo.parts;
  List<ExamPart> get partsWithQuestions => repo.parts.where((p) => p.count > 0).toList();

  Future<void> bootstrap() async {
    try {
      await Future.wait([repo.load(), progress.init()]);
    } catch (e) {
      _bootError = e.toString();
    } finally {
      _booting = false;
      notifyListeners();
    }
  }

  void refresh() => notifyListeners();
}
