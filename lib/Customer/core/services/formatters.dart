import 'package:intl/intl.dart';

class Formatters {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    final formatted = DateFormat('hh:mm a').format(date);
    return formatted.replaceAll('AM', 'ص').replaceAll('PM', 'م');
  }

  static String formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(thatDay).inDays;
    final dateLabel = (diff == 0)
        ? 'اليوم'
        : (diff == 1)
        ? 'أمس'
        : formatDate(date);
    return '$dateLabel - ${formatTime(date)}';
  }
}
