extension CustomDurationFormatting on Duration {
  String get formatHoursMinutes {
    final int hours = inHours;
    final int minutes = inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}h ${minutes == 0 ? '' : '${minutes}m'}';
  }
}
