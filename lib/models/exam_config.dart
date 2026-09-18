enum ExamMode { practice, mock }

/// Configuration chosen on the Exam Configuration / Mock Exam screens.
class ExamConfig {
  final ExamMode mode;
  final Set<int> partIds;
  final int questionCount; // 0 means "all available questions"
  final Duration? timeLimit; // null = untimed
  final bool shuffleQuestions;
  final bool instantFeedback; // practice: reveal correctness immediately
  final bool negativeMarking;
  final bool endAlert; // warn when 5 minutes remain
  final String presetLabel;

  const ExamConfig({
    required this.mode,
    required this.partIds,
    required this.questionCount,
    required this.timeLimit,
    this.shuffleQuestions = true,
    this.instantFeedback = false,
    this.negativeMarking = false,
    this.endAlert = true,
    this.presetLabel = '',
  });

  ExamConfig copyWith({
    ExamMode? mode,
    Set<int>? partIds,
    int? questionCount,
    Duration? timeLimit,
    bool clearTimeLimit = false,
    bool? shuffleQuestions,
    bool? instantFeedback,
    bool? negativeMarking,
    bool? endAlert,
    String? presetLabel,
  }) {
    return ExamConfig(
      mode: mode ?? this.mode,
      partIds: partIds ?? this.partIds,
      questionCount: questionCount ?? this.questionCount,
      timeLimit: clearTimeLimit ? null : (timeLimit ?? this.timeLimit),
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      instantFeedback: instantFeedback ?? this.instantFeedback,
      negativeMarking: negativeMarking ?? this.negativeMarking,
      endAlert: endAlert ?? this.endAlert,
      presetLabel: presetLabel ?? this.presetLabel,
    );
  }

  static const ExamConfig defaultPractice = ExamConfig(
    mode: ExamMode.practice,
    partIds: {},
    questionCount: 20,
    timeLimit: null,
    instantFeedback: true,
    presetLabel: 'ហ្វឹកហាត់សេរី',
  );

  static const ExamConfig defaultMock = ExamConfig(
    mode: ExamMode.mock,
    partIds: {},
    questionCount: 50,
    timeLimit: Duration(minutes: 40),
    instantFeedback: false,
    presetLabel: 'ស្តង់ដារផ្លូវការ',
  );
}
