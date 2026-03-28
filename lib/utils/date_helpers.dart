import 'package:intl/intl.dart';

/// Date and time helper utilities with Arabic support
class DateHelpers {
  DateHelpers._();

  /// Arabic day names
  static const List<String> arabicDays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  /// Arabic month names
  static const List<String> arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// Get relative date label (اليوم / غداً / أمس / etc.)
  static String getRelativeDate(DateTime? date) {
    if (date == null) return 'بدون تاريخ';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff == -1) return 'أمس';
    if (diff == 2) return 'بعد غد';
    if (diff > 0 && diff <= 7) {
      return arabicDays[date.weekday - 1];
    }
    if (diff < 0 && diff >= -7) {
      return 'قبل ${-diff} أيام';
    }

    return '${date.day} ${arabicMonths[date.month - 1]}';
  }

  /// Format time string (HH:MM) to Arabic display
  static String formatTime(String? time) {
    if (time == null || time.isEmpty) return '';

    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];

      if (hour == 0) return '12:$minute ص';
      if (hour < 12) return '$hour:$minute ص';
      if (hour == 12) return '12:$minute م';
      return '${hour - 12}:$minute م';
    } catch (_) {
      return time;
    }
  }

  /// Format DateTime to Arabic full date
  static String formatFullDate(DateTime date) {
    final day = arabicDays[date.weekday - 1];
    final month = arabicMonths[date.month - 1];
    return '$day، ${date.day} $month ${date.year}';
  }

  /// Format DateTime for display
  static String formatDateForDisplay(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء النور';
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if a date is in the past
  static bool isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }
}
