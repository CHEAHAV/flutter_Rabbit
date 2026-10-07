import 'question.dart';

/// The course a subject belongs to. Tracks are the top level of the subject
/// browser: the bank holds two Khmer syllabuses and three English courses, and
/// showing all of them as one flat list of subjects made them look like one
/// syllabus.
///
/// **The order they are declared in is the order they are shown in**, from the
/// Khmer exams to the English ones - see [AppState.tracks]. It cannot be taken
/// from [ExamPart.catalog], because that has to follow the part numbering.
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

  /// The id of the part this subject is listed directly under, or null to
  /// keep its place in catalog order. A new subject can only be appended to
  /// the catalog, so this is how one that belongs beside an older subject is
  /// shown there.
  final int? shownAfter;

  const PartMeta({
    required this.titleKm,
    required this.titleEn,
    required this.icon,
    required this.track,
    this.level,
    this.latinLabels = false,
    this.shownAfter,
  });
}

/// One subject of the question bank: parts 1-13 are the Khmer civil-service
/// bank from QCM.pdf, parts 14-26 the English bank from grammar.pdf, and parts
/// 27-29 the papers filed under the teacher course, and parts 30-38 the
/// papers on the border war, the Funan Techo canal, Techo airport, the
/// Ministry of Interior and the 32nd SEA Games, listed under History.
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

  /// The catalog, in part-number order: part N here is
  /// `assets/data/part_NN.json`, so this list must stay in the same order as
  /// the `PARTS` table in `tools/extract_grammar_pdf.py`, and a new subject
  /// can only ever be appended.
  ///
  /// This is *not* the order the browser shows: courses are ordered by
  /// [PartTrack], and only the subjects within one course are shown in the
  /// order they appear here (for the English courses, easiest rung upwards),
  /// except that a subject with [PartMeta.shownAfter] is moved up under the
  /// subject it names.
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
    // Parts 27-28 prepare the teacher-recruitment exam, so they sit in a
    // course of their own rather than in the civil-service syllabus: dropping
    // them there would put teacher ethics and the ICT paper into a
    // general-knowledge mock paper they do not belong in. The course is
    // declared after the civil-service one in [PartTrack], so it is the second
    // course the browser lists, under General Knowledge.
    //
    // Part 27 comes from assets/pdf/ក្រមសីលធម៌វិជ្ជាជីវៈគ្រូបង្រៀន.pdf.
    PartMeta(
      titleKm: 'ក្រមសីលធម៌វិជ្ជាជីវៈគ្រូបង្រៀន',
      titleEn: 'Teacher Professional Ethics',
      icon: '🧑‍🏫',
      track: PartTrack.teaching,
    ),
    // Part 28 comes from the 300-question ICT paper in assets/pdf/, via
    // tools/extract_ict_pdf.py.
    PartMeta(
      titleKm: 'ព័ត៌មានវិទ្យា (ICT)',
      titleEn: 'ICT for Teachers',
      icon: '💻',
      track: PartTrack.teaching,
    ),
    // Part 29 is the National Police and prison-officer paper in assets/pdf/,
    // via tools/extract_police_pdf.py. It prepares a different exam, but it is
    // filed under the teacher course because that is where the app's users
    // asked to find it.
    PartMeta(
      titleKm: 'នគរបាលជាតិ និងពន្ធនាគារ',
      titleEn: 'National Police & Prisons',
      icon: '👮',
      track: PartTrack.teaching,
    ),
    // Parts 30-32 are the three 50-question papers in assets/pdf/ on recent
    // national events, listed directly under History, where the app's users
    // asked for them.
    //
    // Part 30 is សង្គ្រាមជម្លោះព្រំដែនកម្ពុជា-សៀម.pdf, read from its text layer
    // and its answer key.
    PartMeta(
      titleKm: 'អំពីសង្គ្រាមជម្លោះព្រំដែនកម្ពុជា-សៀម',
      titleEn: 'Cambodia-Siam Border War',
      icon: '🛡️',
      track: PartTrack.civilService,
      shownAfter: 1,
    ),
    // Part 31 is ព្រែកជីកហ្វូណនតេជោ.pdf. Its text layer is garbled, so it was
    // transcribed from the page images. Its answer key is cut off after
    // question 20, so the answers to 21-50 were judged from the options, and
    // question 31, whose answer could not be established, was left out.
    PartMeta(
      titleKm: 'អំពីព្រែកជីកហ្វូណនតេជោ',
      titleEn: 'Funan Techo Canal',
      icon: '🚢',
      track: PartTrack.civilService,
      shownAfter: 1,
    ),
    // Part 32 is អាកាសយានដ្ឋានអន្តរជាតិតេជោ.pdf, read from its text layer and
    // its answer key.
    PartMeta(
      titleKm: 'អំពីអាកាសយានដ្ឋានអន្តរជាតិតេជោ',
      titleEn: 'Techo International Airport',
      icon: '✈️',
      track: PartTrack.civilService,
      shownAfter: 1,
    ),
    // Part 33 is ក្រសួងមហាផ្ទៃកម្ពុជា.pdf, 200 questions read from its text
    // layer. Its answer key leaves nearly every answer on ក, so the answers
    // were checked against the options: nine were corrected, and questions 2
    // and 8 were left out (one cannot be answered from its options, the other
    // prints its answer in the stem). It follows parts 30-32 under History.
    PartMeta(
      titleKm: 'អំពីក្រសួងមហាផ្ទៃកម្ពុជា',
      titleEn: 'Ministry of Interior',
      icon: '🏢',
      track: PartTrack.civilService,
      shownAfter: 1,
    ),
    // Part 34 is ស៊ីហ្គេមលើកទី៣២ នៅកម្ពុជា.pdf, 50 questions read from its
    // text layer and its answer key. It follows part 33 under History.
    PartMeta(
      titleKm: 'អំពីស៊ីហ្គេមលើកទី៣២ នៅកម្ពុជា',
      titleEn: 'The 32nd SEA Games in Cambodia',
      icon: '🏅',
      track: PartTrack.civilService,
      shownAfter: 1,
    ),
    // Part 35 is សម្បត្តិវប្បធម៌ខ្មែរក្នុងបញ្ជីយូណេស្កូ.pdf, 21 questions read
    // from its text layer and its answer key. It follows part 34 under History.
    PartMeta(
      titleKm: 'អំពីសម្បត្តិវប្បធម៌ខ្មែរក្នុងបញ្ជីយូណេស្កូ',
      titleEn: 'Khmer Heritage on the UNESCO Lists',
      icon: '🏯',
      track: PartTrack.civilService,
      shownAfter: 1,
    ),
    // Part 36 is ឩទ្យានជាតិនៃប្រទេសកម្ពុជា.pdf, 20 questions read from its
    // text layer and its answer key. It follows part 35 under History.
    PartMeta(
      titleKm: 'អំពីឧទ្យានជាតិនៃប្រទេសកម្ពុជា',
      titleEn: 'National Parks of Cambodia',
      icon: '🌲',
      track: PartTrack.civilService,
      shownAfter: 1,
    ),
    // Part 37 is សម័យកាលរបស់ប្រទេសកម្ពុជា.pdf, 20 questions read from its
    // text layer and its answer key. It follows part 36 under History.
    PartMeta(
      titleKm: 'អំពីសម័យកាលរបស់ប្រទេសកម្ពុជា',
      titleEn: 'The Eras of Cambodian History',
      icon: '⏳',
      track: PartTrack.civilService,
      shownAfter: 1,
    ),
    // Part 38 is ព្រឹត្តិការន៏សំខាន់ៗ.pdf, a 26-page timeline of facts with no
    // questions and no text layer (the Khmer is drawn as outlines). It was
    // transcribed from the page images and each fact turned into a question
    // whose answer is the fact as printed. Facts the PDF contradicts elsewhere
    // or repeats were left out. It follows part 37 under History.
    PartMeta(
      titleKm: 'អំពីព្រឹត្តិការណ៍សំខាន់ៗ',
      titleEn: 'Key Events in History',
      icon: '📜',
      track: PartTrack.civilService,
      shownAfter: 1,
    ),
  ];
}
