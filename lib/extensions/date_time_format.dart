import 'package:intl/intl.dart';

extension CustomDateTimeFormatting on DateTime {
  String get formatDisplay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final inputDate = DateTime(year, month, day);

    final timeFormat = DateFormat('hh:mm a'); // e.g. 03:15 PM

    if (inputDate == today) {
      return 'Today ${timeFormat.format(this)}';
    } else if (inputDate == tomorrow) {
      return 'Tomorrow ${timeFormat.format(this)}';
    } else {
      final dateFormat = DateFormat('MMM dd'); // e.g. Sep 13
      return '${dateFormat.format(this)}, ${timeFormat.format(this)}';
    }
  }
}
