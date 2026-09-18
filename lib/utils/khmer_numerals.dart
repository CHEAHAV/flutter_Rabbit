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

const List<String> khmerOptionLabels = ['ក', 'ខ', 'គ', 'ឃ'];
