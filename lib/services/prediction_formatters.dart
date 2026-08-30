String formatYen(double price) {
  final rounded = price.round().toString();
  final withSeparators = rounded.replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+$)'),
    (_) => ',',
  );
  return '¥$withSeparators';
}

String formatDate(DateTime date, {bool includeYear = true}) => includeYear
    ? '${date.year.toString().padLeft(4, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}'
    : '${date.month}/${date.day}';
