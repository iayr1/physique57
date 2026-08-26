import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFullDate(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date); // e.g. 26 August 2026
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date); // e.g. 26 Aug 2026
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy • hh:mm a').format(date); // e.g. 26 Aug 2026 • 10:30 AM
  }

  static String formatTimeOnly(DateTime date) {
    return DateFormat('hh:mm a').format(date); // e.g. 10:30 AM
  }

  static int calculateDaysBetween(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }
}
