/// Turkish, human-friendly plan times: "Bugün 21:00", "Yarın 20:30",
/// "Cuma 21:00" (within a week), "12 Eki 21:00" further out.
const _days = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];
const _months = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

String formatPlanTime(DateTime when) {
  final time =
      '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
  final days = _day(when).difference(_day(DateTime.now())).inDays;
  if (days == 0) return 'Bugün $time';
  if (days == 1) return 'Yarın $time';
  if (days == -1) return 'Dün $time';
  if (days > 1 && days < 7) return '${_days[when.weekday - 1]} $time';
  return '${when.day} ${_months[when.month - 1]} $time';
}

/// Short weekday for the "Bu Hafta" strip: "Pzt", "Sal"…
String shortWeekday(DateTime d) =>
    const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][d.weekday - 1];

/// "2 gün 5 saat kaldı", "3 saat 10 dk kaldı", "12 dk kaldı", "Başladı".
String countdown(DateTime when) {
  final left = when.difference(DateTime.now());
  if (left.isNegative) return 'Başladı';
  if (left.inDays > 0) {
    return '${left.inDays} gün ${left.inHours % 24} saat kaldı';
  }
  if (left.inHours > 0) {
    return '${left.inHours} saat ${left.inMinutes % 60} dk kaldı';
  }
  return '${left.inMinutes.clamp(1, 59)} dk kaldı';
}

bool isSameDay(DateTime a, DateTime b) => _day(a) == _day(b);
