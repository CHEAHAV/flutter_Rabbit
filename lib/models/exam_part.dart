import 'question.dart';

/// One of the 13 subject sections ("ផ្នែកទី") of the QCM question bank.
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
  ];
}
