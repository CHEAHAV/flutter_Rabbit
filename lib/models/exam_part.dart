import 'question.dart';

/// One subject section ("ផ្នែកទី") of the QCM question bank: parts 1-13 are the
/// Khmer civil-service bank, parts 14-24 the English bank from grammar.pdf,
/// one part per part of that book.
class ExamPart {
  final int id;
  final String titleKm;
  final String titleEn;
  final String icon; // emoji glyph used as a lightweight icon
  final List<Question> questions;

  const ExamPart({
    required this.id,
    required this.titleKm,
    required this.titleEn,
    required this.icon,
    required this.questions,
  });

  int get count => questions.length;

  ExamPart copyWith({List<Question>? questions}) => ExamPart(
    id: id,
    titleKm: titleKm,
    titleEn: titleEn,
    icon: icon,
    questions: questions ?? this.questions,
  );

  static const List<Map<String, String>> catalog = [
    {'title': 'អំពីប្រវត្តិសាស្ត្រ', 'en': 'History', 'icon': '🏺'},
    {
      'title': 'អំពីវប្បធម៌ និងអរិយធម៌',
      'en': 'Culture & Civilization',
      'icon': '🎭',
    },
    {
      'title': 'អំពីភូមិសាស្ត្រ និងប្រជាសាស្ត្រ',
      'en': 'Geography & Demography',
      'icon': '🗺️',
    },
    {
      'title': 'អំពីរដ្ឋបាលសាធារណៈ',
      'en': 'Public Administration',
      'icon': '🏛️',
    },
    {
      'title': 'អំពីសេដ្ឋកិច្ច ហិរញ្ញវត្ថុ និងវិនិយោគ',
      'en': 'Economy & Finance',
      'icon': '📈',
    },
    {
      'title': 'អំពីមុខងារសាធារណៈ និងធនធានមនុស្ស',
      'en': 'Public Function & HR',
      'icon': '🧑‍💼',
    },
    {'title': 'អំពីអាស៊ាន', 'en': 'ASEAN', 'icon': '🌏'},
    {'title': 'អំពីអន្តរជាតិ', 'en': 'International Affairs', 'icon': '🌐'},
    {
      'title': 'អំពីច្បាប់ គោលនយោបាយ និងនយោបាយ',
      'en': 'Law & Policy',
      'icon': '⚖️',
    },
    {
      'title': 'អំពីសាសនា ក្រមសីលធម៌ និងសុភាសិត',
      'en': 'Religion & Ethics',
      'icon': '🙏',
    },
    {
      'title': 'អំពីវិទ្យាសាស្ត្រ បច្ចេកវិទ្យា និងនវានុវត្តន៍',
      'en': 'Science & Technology',
      'icon': '💡',
    },
    {
      'title': 'អំពីល្បែងប្រាជ្ញា តក្កវិទ្យា និងករណីសិក្សា',
      'en': 'Logic & Case Studies',
      'icon': '🧩',
    },
    {'title': 'អំពីវិស័យយុត្តិធម៌', 'en': 'Justice Sector', 'icon': '🧑‍⚖️'},
    // Parts 14-24 come from assets/pdf/grammar.pdf. They follow the book's own
    // division - Book 1 Parts A-E, Book 2 Parts A-E and Book 3 - rather than
    // one part per book, so no single section holds thousands of questions.
    // They are lettered A-E as the book prints them; 'labels': 'latin' selects
    // that. Keep this list in the same order as the PARTS table in
    // tools/extract_grammar_pdf.py: part N here is assets/data/part_NN.json.
    {
      'title': 'វេយ្យាករណ៍អង់គ្លេស ផ្នែក A',
      'en': 'Book 1 Grammar - Part A',
      'icon': '📘',
      'labels': 'latin',
    },
    {
      'title': 'វេយ្យាករណ៍អង់គ្លេស ផ្នែក B',
      'en': 'Book 1 Grammar - Part B',
      'icon': '📗',
      'labels': 'latin',
    },
    {
      'title': 'វេយ្យាករណ៍អង់គ្លេស ផ្នែក C',
      'en': 'Book 1 Grammar - Part C',
      'icon': '📙',
      'labels': 'latin',
    },
    {
      'title': 'វេយ្យាករណ៍អង់គ្លេស ផ្នែក D',
      'en': 'Book 1 Grammar - Part D',
      'icon': '📕',
      'labels': 'latin',
    },
    {
      'title': 'វេយ្យាករណ៍អង់គ្លេស ផ្នែក E',
      'en': 'Book 1 Grammar - Part E',
      'icon': '📓',
      'labels': 'latin',
    },
    {
      'title': 'វាក្យសព្ទអង់គ្លេស ផ្នែក A',
      'en': 'Book 2 Vocabulary - Part A',
      'icon': '🔤',
      'labels': 'latin',
    },
    {
      'title': 'វាក្យសព្ទអង់គ្លេស ផ្នែក B',
      'en': 'Book 2 Vocabulary - Part B',
      'icon': '🔡',
      'labels': 'latin',
    },
    {
      'title': 'កិរិយាសព្ទឃ្លា ផ្នែក C',
      'en': 'Book 2 Phrasal Verbs - Part C',
      'icon': '🔗',
      'labels': 'latin',
    },
    {
      'title': 'វាក្យសព្ទកម្រិតខ្ពស់ ផ្នែក D',
      'en': 'Book 2 Vocabulary - Part D',
      'icon': '📚',
      'labels': 'latin',
    },
    {
      'title': 'ពាក្យមានន័យដូច ផ្នែក E',
      'en': 'Book 2 Synonyms - Part E',
      'icon': '🔁',
      'labels': 'latin',
    },
    {
      'title': 'ភាសាអង់គ្លេសទូទៅ',
      'en': 'Book 3 - Miscellaneous',
      'icon': '💬',
      'labels': 'latin',
    },
  ];
}
