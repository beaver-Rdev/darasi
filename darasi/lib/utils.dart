// أدوات التاريخ والأرقام (بدون الاعتماد على intl لتفادي مشاكل اللغة).

/// الأسبوع يبدأ يوم السبت.
const arabicDays = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
const dayInitials = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
const arabicMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

/// ترتيب اليوم داخل الأسبوع (السبت = 0 ... الجمعة = 6).
int satIndex(DateTime d) => (d.weekday + 1) % 7;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
DateTime weekStart(DateTime d) => addDays(dateOnly(d), -satIndex(d));
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String two(int n) => n.toString().padLeft(2, '0');
String dayKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
String formatDate(DateTime d) => '${d.day} ${arabicMonths[d.month - 1]} ${d.year}';
String formatShort(DateTime d) => '${d.day} ${arabicMonths[d.month - 1]}';
String formatMinutesOfDay(int m) => '${two(m ~/ 60)}:${two(m % 60)}';

String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '$h س $m د';
  if (m > 0) return '$m د';
  return '$seconds ث';
}

String formatClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

String fmtNum(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// يحوّل الأرقام العربية (٠١٢...) إلى 0123 ليقبلها double.tryParse.
String toWesternDigits(String s) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final sb = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    final i = arabic.indexOf(ch);
    if (i >= 0) {
      sb.write(i);
    } else if (ch == '٫' || ch == ',' || ch == '،') {
      sb.write('.');
    } else {
      sb.write(ch);
    }
  }
  return sb.toString();
}

double? parseNum(String s) => double.tryParse(toWesternDigits(s).trim());
