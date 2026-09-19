/// Renders Arabic digits as Khmer numeral glyphs (០-៩), matching how
/// dates, scores and counts are written throughout the source material.
String kh(Object value) {
  const digits = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
  final s = value.toString();
  final buffer = StringBuffer();
  for (final ch in s.split('')) {
    final d = int.tryParse(ch);
    buffer.write(d == null ? ch : digits[d]);
  }
  return buffer.toString();
}

String khPercent(num value, {int fractionDigits = 0}) =>
    '${kh(value.toStringAsFixed(fractionDigits))}%';

String khDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) {
    final h = d.inHours.toString();
    return '${kh(h)}:${kh(m)}:${kh(s)}';
  }
  return '${kh(m)}:${kh(s)}';
}

/// Option letters for the Khmer question bank (parts 1-13).
const List<String> khmerOptionLabels = ['ក', 'ខ', 'គ', 'ឃ', 'ង'];

/// Option letters for the English parts, which keep the A-E lettering of the
/// book they were extracted from rather than being transliterated.
const List<String> latinOptionLabels = ['A', 'B', 'C', 'D', 'E'];
