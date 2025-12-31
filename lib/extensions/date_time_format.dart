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

extension EventAgo on DateTime {
  String get eventAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    // Handle future events
    if (difference.isNegative) {
      final futureMinutes = (-difference).inMinutes;
      if (futureMinutes < 5) return "Happening soon";
      return "In $futureMinutes minute${futureMinutes > 1 ? 's' : ''}";
    }

    final minutes = difference.inMinutes;
    final hours = difference.inHours;

    // Less than 5 minutes
    if (minutes < 5) return "Just now";

    // 5–8 minutes
    if (minutes >= 5 && minutes <= 8) return "5 minutes ago";

    // 9–59 minutes, round to nearest 5
    if (minutes < 60) {
      int rounded = (minutes / 5).round() * 5;
      if (rounded >= 55) return "an hour ago";
      return "$rounded minute${rounded == 1 ? '' : 's'} ago";
    }

    // 1 hour or more, round minutes to nearest 15
    int remainingMinutes = minutes % 60;
    int roundedMinutes = (remainingMinutes / 15).round() * 15;
    int displayHours = hours;

    if (roundedMinutes == 60) {
      displayHours += 1;
      roundedMinutes = 0;
    }

    if (roundedMinutes == 0) {
      return displayHours == 1 ? "1hr ago" : "${displayHours}hrs ago";
    } else if (roundedMinutes == 15 || roundedMinutes == 30 || roundedMinutes == 45) {
      return "${displayHours}hr${displayHours == 1 ? '' : 's'} ${roundedMinutes}min${roundedMinutes == 1 ? '' : 's'} ago";
    } else {
      // fallback, just in case
      return "${displayHours}hr${displayHours == 1 ? '' : 's'} ago";
    }
  }
}
