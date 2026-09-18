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
  bool _isDarkMode = false;

  bool get booting => _booting;
  String? get bootError => _bootError;

  /// The user's saved light/dark preference. Defaults to light until the
  /// on-device preference has loaded (see [bootstrap]). `app.dart` watches
  /// this and animates the theme toward it with a [TweenAnimationBuilder]
  /// whenever it changes, so the switch crossfades instead of snapping.
  bool get isDarkMode => _isDarkMode;

  List<ExamPart> get parts => repo.parts;
  List<ExamPart> get partsWithQuestions =>
      repo.parts.where((p) => p.count > 0).toList();

  Future<void> bootstrap() async {
    try {
      await Future.wait([repo.load(), progress.init()]);
      _isDarkMode = progress.isDarkMode;
    } catch (e) {
      _bootError = e.toString();
    } finally {
      _booting = false;
      notifyListeners();
    }
  }

  /// Switches the app's theme (smoothly, see [isDarkMode]) and persists the
  /// choice on-device.
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    await progress.setDarkMode(value);
  }

  void refresh() => notifyListeners();
}
