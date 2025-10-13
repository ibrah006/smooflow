extension CustomDurationFormatting on Duration {
  String get formatTime {
    final int hours = inHours;
    final int minutes = inMinutes.remainder(60);
    final int seconds = inSeconds.remainder(60);
    return '${hours > 0 ? '${hours.toString()}h' : ''} ${minutes == 0 && hours > 0 ? '' : '${minutes}m'} ${hours > 0 ? '' : '${seconds.toString().padLeft(2, '0')}s'}';
  }
}
