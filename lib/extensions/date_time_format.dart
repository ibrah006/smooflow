import 'package:intl/intl.dart';

extension CustomDateTimeFormatting on DateTime? {
  String? get formatDisplay {
    if (this == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final inputDate = DateTime(this!.year, this!.month, this!.day);

    final timeFormat = DateFormat('hh:mm a'); // e.g. 03:15 PM

    if (inputDate == today) {
      return 'Today ${timeFormat.format(this!)}';
    } else if (inputDate == tomorrow) {
      return 'Tomorrow ${timeFormat.format(this!)}';
    } else {
      final dateFormat = DateFormat('MMM dd'); // e.g. Sep 13
      return '${dateFormat.format(this!)}, ${timeFormat.format(this!)}';
    }
  }
}

extension EventIn on DateTime {
  String get eventIn {
    final now = DateTime.now();
    final target = this;

    final diff = target.difference(now);

    // Time formatter with AM/PM
    String formatTime(DateTime dt) {
      int hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');

      final suffix = hour >= 12 ? "PM" : "AM";

      hour = hour % 12;
      if (hour == 0) hour = 12;

      return "$hour:$minute $suffix";
    }

    // "Now" if within ±15 minutes
    if (diff.inMinutes < 15 && diff.inMinutes > -15) {
      return "Now";
    }

    // ===== DATE BOUNDARIES =====
    DateTime strip(DateTime dt) =>
        DateTime(dt.year, dt.month, dt.day);

    final today = strip(now);
    final targetDay = strip(target);

    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    // ===== PAST RULES =====
    if (targetDay.isBefore(today)) {
      // Yesterday
      if (targetDay == yesterday) {
        return "Yesterday";
      }

      // Earlier than yesterday → X days ago
      final pastDays = today.difference(targetDay).inDays;
      return "${pastDays} days ago";
    }

    // ===== TODAY RULES =====
    if (targetDay == today) {
      // < 1 hour
      if (diff.inMinutes < 60) {
        return formatTime(target);
      }

      // >= 1 hour
      return "In ${diff.inHours} hours";
    }

    // ===== FUTURE RULES =====

    // Tomorrow
    if (targetDay == tomorrow) {
      return "Tomorrow";
    }

    // Beyond tomorrow → "In N days"
    final futureDays = targetDay.difference(today).inDays;
    return "In ${futureDays} days";
  }
}
