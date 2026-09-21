import 'question.dart';

/// The course a subject belongs to. Tracks are the top level of the subject
/// browser: the bank holds a Khmer civil-service syllabus and three English
/// courses, and showing all of them as one flat list of subjects made the two
/// look like one syllabus.
enum PartTrack {
  civilService('ចំណេះដឹងទូទៅ', 'General Knowledge', '🇰🇭'),
  teaching('វិជ្ជាជីវៈគ្រូបង្រៀន', 'Teacher Recruitment', '🎓'),
  grammar('វេយ្យាករណ៍អង់គ្លេស', 'English Grammar', '📘'),
  vocabulary('វាក្យសព្ទអង់គ្លេស', 'English Vocabulary', '🔤'),
  englishSkills('ភាសាអង់គ្លេសអនុវត្ត', 'English in Use', '💬');

  const PartTrack(this.titleKm, this.titleEn, this.icon);

  final String titleKm;
  final String titleEn;

  /// Emoji glyph, used as a lightweight icon the way [ExamPart.icon] is.
  final String icon;
}

/// How demanding a subject is, on the ladder the source book itself prints in
/// the running head of nearly every page.
///
/// [allLevels] is not a rung: it marks the sets the book calls "multi-level",
/// where one test deliberately mixes easy and hard items. Those are kept as
/// they are rather than graded, because splitting them would mean inventing a
/// difficulty the book never assigned.
enum PartLevel {
  elementary('កម្រិតដំបូង', 'Elementary'),
  preIntermediate('កម្រិតមធ្យមដំបូង', 'Pre-Intermediate'),
  intermediate('កម្រិតមធ្យម', 'Intermediate'),
  upperIntermediate('កម្រិតមធ្យមខ្ពស់', 'Upper-Intermediate'),
  advanced('កម្រិតខ្ពស់', 'Advanced'),
  allLevels('គ្រប់កម្រិត', 'All levels');

  const PartLevel(this.titleKm, this.titleEn);

  final String titleKm;
  final String titleEn;

  /// The short form used on the level badge. The badge already says it is a
  /// level, so the "កម្រិត" prefix is redundant there - and on a 320px screen
  /// the full name does not fit beside the question count.
  String get badgeKm => switch (this) {
    elementary => 'ដំបូង',
    preIntermediate => 'មធ្យមដំបូង',
    intermediate => 'មធ្យម',
    upperIntermediate => 'មធ្យមខ្ពស់',
    advanced => 'ខ្ពស់',
    allLevels => 'គ្រប់កម្រិត',
  };

  /// Position on the ladder, 1-5, or null for [allLevels], which sits beside
  /// the ladder rather than on it.
  int? get step => this == allLevels ? null : index + 1;

  /// 0-1, for drawing the rung as a filled bar. [allLevels] reads as full.
  double get intensity => (step ?? 5) / 5;
}

/// Static description of one subject, before its questions are loaded.
class PartMeta {
  final String titleKm;
  final String titleEn;
  final String icon;
  final PartTrack track;

  /// Null for the Khmer civil-service subjects, which the source syllabus
  /// does not grade.
  final PartLevel? level;

  /// Whether the options are lettered A/B/C/D/E instead of ក/ខ/គ/ឃ. It follows
  /// the language of the questions, not one app-wide convention.
  final bool latinLabels;

  const PartMeta({
    required this.titleKm,
    required this.titleEn,
    required this.icon,
    required this.track,
    this.level,
    this.latinLabels = false,
  });
}

/// One subject of the question bank: parts 1-13 are the Khmer civil-service
/// bank from QCM.pdf, parts 14-26 the English bank from grammar.pdf, and part
/// 27 the teacher-ethics collection.
class ExamPart {
  final int id;
  final String titleKm;
  final String titleEn;
  final String icon; // emoji glyph used as a lightweight icon
  final PartTrack track;
  final PartLevel? level;
  final List<Question> questions;

  const ExamPart({
    required this.id,
    required this.titleKm,
    required this.titleEn,
    required this.icon,
    required this.track,
    this.level,
    required this.questions,
  });

  int get count => questions.length;

  ExamPart copyWith({List<Question>? questions}) => ExamPart(
    id: id,
    titleKm: titleKm,
    titleEn: titleEn,
    icon: icon,
    track: track,
    level: level,
    questions: questions ?? this.questions,
  );

  /// The catalog, in the order the subject browser shows it: the Khmer
  /// syllabus first, then each English course from its easiest rung upwards.
  ///
  /// Part N here is `assets/data/part_NN.json`, so this list must stay in the
  /// same order as the `PARTS` table in `tools/extract_grammar_pdf.py`.
  static const List<PartMeta> catalog = [
    PartMeta(
      titleKm: 'អំពីប្រវត្តិសាស្ត្រ',
      titleEn: 'History',
      icon: '🏺',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីវប្បធម៌ និងអរិយធម៌',
      titleEn: 'Culture & Civilization',
      icon: '🎭',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីភូមិសាស្ត្រ និងប្រជាសាស្ត្រ',
      titleEn: 'Geography & Demography',
      icon: '🗺️',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីរដ្ឋបាលសាធារណៈ',
      titleEn: 'Public Administration',
      icon: '🏛️',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីសេដ្ឋកិច្ច ហិរញ្ញវត្ថុ និងវិនិយោគ',
      titleEn: 'Economy & Finance',
      icon: '📈',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីមុខងារសាធារណៈ និងធនធានមនុស្ស',
      titleEn: 'Public Function & HR',
      icon: '🧑‍💼',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីអាស៊ាន',
      titleEn: 'ASEAN',
      icon: '🌏',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីអន្តរជាតិ',
      titleEn: 'International Affairs',
      icon: '🌐',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីច្បាប់ គោលនយោបាយ និងនយោបាយ',
      titleEn: 'Law & Policy',
      icon: '⚖️',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីសាសនា ក្រមសីលធម៌ និងសុភាសិត',
      titleEn: 'Religion & Ethics',
      icon: '🙏',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីវិទ្យាសាស្ត្រ បច្ចេកវិទ្យា និងនវានុវត្តន៍',
      titleEn: 'Science & Technology',
      icon: '💡',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីល្បែងប្រាជ្ញា តក្កវិទ្យា និងករណីសិក្សា',
      titleEn: 'Logic & Case Studies',
      icon: '🧩',
      track: PartTrack.civilService,
    ),
    PartMeta(
      titleKm: 'អំពីវិស័យយុត្តិធម៌',
      titleEn: 'Justice Sector',
      icon: '🧑‍⚖️',
      track: PartTrack.civilService,
    ),
    // Parts 14-26 come from assets/pdf/grammar.pdf, filed by the level the
    // book prints for them rather than by its Part A-E lettering: a learner
    // can tell whether "Elementary" is for them, but not whether "Part C" is.
    PartMeta(
      titleKm: 'វេយ្យាករណ៍ កម្រិតដំបូង',
      titleEn: 'Grammar - Elementary',
      icon: '🌱',
      track: PartTrack.grammar,
      level: PartLevel.elementary,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'វេយ្យាករណ៍ កម្រិតមធ្យមដំបូង',
      titleEn: 'Grammar - Pre-Intermediate',
      icon: '🌿',
      track: PartTrack.grammar,
      level: PartLevel.preIntermediate,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'វេយ្យាករណ៍ កម្រិតមធ្យម',
      titleEn: 'Grammar - Intermediate',
      icon: '🌳',
      track: PartTrack.grammar,
      level: PartLevel.intermediate,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'វេយ្យាករណ៍ កម្រិតមធ្យមខ្ពស់',
      titleEn: 'Grammar - Upper-Intermediate',
      icon: '🏔️',
      track: PartTrack.grammar,
      level: PartLevel.upperIntermediate,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'វេយ្យាករណ៍ កម្រិតខ្ពស់',
      titleEn: 'Grammar - Advanced',
      icon: '🚀',
      track: PartTrack.grammar,
      level: PartLevel.advanced,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'វេយ្យាករណ៍តាមប្រធានបទ',
      titleEn: 'Grammar by Topic',
      icon: '🧭',
      track: PartTrack.grammar,
      level: PartLevel.allLevels,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'តេស្តវាយតម្លៃវេយ្យាករណ៍',
      titleEn: 'Grammar Assessment Tests',
      icon: '📝',
      track: PartTrack.grammar,
      level: PartLevel.allLevels,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'វាក្យសព្ទ កម្រិតដំបូង',
      titleEn: 'Vocabulary - Elementary',
      icon: '🔤',
      track: PartTrack.vocabulary,
      level: PartLevel.elementary,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'វាក្យសព្ទ កម្រិតមធ្យម',
      titleEn: 'Vocabulary - Intermediate',
      icon: '🔡',
      track: PartTrack.vocabulary,
      level: PartLevel.intermediate,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'វាក្យសព្ទ កម្រិតមធ្យមខ្ពស់',
      titleEn: 'Vocabulary - Upper-Intermediate',
      icon: '📚',
      track: PartTrack.vocabulary,
      level: PartLevel.upperIntermediate,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'វាក្យសព្ទ កម្រិតខ្ពស់',
      titleEn: 'Vocabulary - Advanced',
      icon: '🔁',
      track: PartTrack.vocabulary,
      level: PartLevel.advanced,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'កិរិយាសព្ទឃ្លា',
      titleEn: 'Phrasal Verbs',
      icon: '🔗',
      track: PartTrack.vocabulary,
      level: PartLevel.allLevels,
      latinLabels: true,
    ),
    PartMeta(
      titleKm: 'ភាសាអង់គ្លេសប្រើប្រាស់',
      titleEn: 'English in Use',
      icon: '💬',
      track: PartTrack.englishSkills,
      level: PartLevel.allLevels,
      latinLabels: true,
    ),
    // Part 27 comes from assets/pdf/ក្រមសីលធម៌វិជ្ជាជីវៈគ្រូបង្រៀន.pdf. It sits
    // in a course of its own because it prepares a different exam: dropping it
    // into the civil-service syllabus would put teacher ethics into a
    // general-knowledge mock paper it does not belong in.
    PartMeta(
      titleKm: 'ក្រមសីលធម៌វិជ្ជាជីវៈគ្រូបង្រៀន',
      titleEn: 'Teacher Professional Ethics',
      icon: '🧑‍🏫',
      track: PartTrack.teaching,
    ),
  ];
}
