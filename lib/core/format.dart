import 'package:flutter/material.dart';

/// Small formatting helpers: times, greetings, department colours.
abstract final class GFormat {
  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  static String greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// "Saturday, 31 October".
  static String longDate(DateTime d) => '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

  static String month(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  static String weekdayShort(DateTime d) => _days[d.weekday - 1].substring(0, 3);

  static String weekdayLetter(DateTime d) => _days[d.weekday - 1].substring(0, 1);

  /// "10:30 AM".
  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "45m", "1h", "1h 10m".
  static String minutes(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60, r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }

  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Today", "Tomorrow", "Yesterday" or "Thu 5 Nov".
  static String dayName(DateTime d, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${weekdayShort(d)} ${d.day} ${_months[d.month - 1].substring(0, 3)}';
  }

  /// A muted colour per department, used only as a small dot.
  static Color dept(String dept) => switch (dept) {
    'Sales' => const Color(0xFF3579D7),
    'Product' => const Color(0xFF7C5CFF),
    'Operations' => const Color(0xFF1F9D8A),
    'Finance' => const Color(0xFFC98500),
    'Human Resources' => const Color(0xFFD9577A),
    'Marketing' => const Color(0xFFE0703A),
    'Leadership' => const Color(0xFF5C5C61),
    _ => const Color(0xFF9A9AA0),
  };

  static String shortDept(String dept) => dept == 'Human Resources' ? 'HR' : dept;
}
