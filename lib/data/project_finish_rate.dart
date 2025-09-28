import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/project.dart';

@Deprecated("")
class ProjectFinishRate {
  @deprecated
  static double calculateProjectCompletionRate(
    Project project,
    List<ProgressLog> progressLogs,
  ) {
    final now = DateTime.now();
    final List<double> progressRates = [];

    for (final log in progressLogs) {
      final start = log.startDate;
      final end = log.dueDate;

      // Ignore invalid logs
      if (start == null || end == null || start.isAfter(end)) continue;

      // Expected progress = time passed in the stage
      final totalDuration = end.difference(start).inSeconds;
      final timePassed =
          now.isBefore(start)
              ? 0
              : now.isAfter(end)
              ? totalDuration
              : now.difference(start).inSeconds;

      final expected =
          totalDuration == 0
              ? 1.0
              : (timePassed / totalDuration).clamp(0.0, 1.0);

      // Get tasks linked to this progress log
      final tasks =
          project.tasks.where((t) => t.progressLogId == log.id).toList();

      // Actual progress = task completion or isCompleted
      double actual;
      if (tasks.isNotEmpty) {
        final completedCount =
            tasks.where((t) => t.status.toLowerCase() == "completed").length;
        actual = completedCount / tasks.length;
      } else {
        actual = log.isCompleted ? 1.0 : 0.0;
      }

      // Final progress rate for this stage
      final progressRate =
          expected == 0 ? 0.0 : (actual / expected).clamp(0.0, 1.0);
      progressRates.add(progressRate);
    }

    if (progressRates.isEmpty) return 0.0;

    // Average of all progress rates
    final sum = progressRates.reduce((a, b) => a + b);
    return (sum / progressRates.length).clamp(0.0, 1.0);
  }
}
