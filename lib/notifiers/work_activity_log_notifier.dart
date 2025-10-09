import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/user.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/repositories/work_activity_log_repo.dart';

class WorkActivityLogNotifier extends StateNotifier<List<WorkActivityLog>> {
  WorkActivityLogNotifier(this._repo) : super([]);

  final WorkActivityLogRepo _repo;

  WorkActivityLog? _activeLog;

  WorkActivityLog? get activeLog => _activeLog;

  set activeLog(WorkActivityLog? log) => _activeLog = log;

  double getTotalLogDurationSeconds(int taskId) {
    double seconds = 0;
    for (WorkActivityLog log in state) {
      if (log.taskId == taskId) {
        seconds += log.end?.difference(log.start).inSeconds ?? 0;
      }
    }
    return seconds;
  }

  /// Load all logs for a specific task
  /// returns the users for these work-activity-logs
  /// returns null if no call to the server is made
  Future<List<User>?> loadTaskActivityLogs({
    required int taskId,
    bool forceReload = false,
    // Pass in the local task work-activity-log last modified
    // This is the datetime of the last modified work-activity-log of [taskId]
    required DateTime? taskActivityLogsLastModifiedLocal,
    // Task work-activity-log Ids (ensure all the ids are included)
    required List<int> taskActivityLogIds,
  }) async {
    // try {
    final DateTime? taskActivityLogsLastModifiedServer =
        !forceReload
            ? null
            : await _repo.getTaskActivityLogsLastModified(taskId);

    final localUpdateNeeded =
        forceReload && taskActivityLogsLastModifiedLocal != null
            ? taskActivityLogsLastModifiedServer?.isAfter(
              taskActivityLogsLastModifiedLocal,
            )
            : false;

    late final bool mustGetLogData;
    if (localUpdateNeeded == true) {
      mustGetLogData = true;
    } else {
      // MUST GET LOCAL DATA (this boolean overrides ensureLatestLogDetails [whether t or f])
      mustGetLogData =
          // Although the latest info is not needed, what if the actual work-activity-logs are not even loaded into the memory yet?
          // We can check to see if the reference work-activity-logs (IDs) that are in memory (through task model), is having an actual instance of it in memory
          !taskActivityLogIds.every(
            (item) => (state.map((workActivityLog) {
              if (workActivityLog.taskId == taskId) return workActivityLog.id;
            })).toSet().contains(item),
          );
    }

    if (localUpdateNeeded == true || mustGetLogData) {
      final updatedTaskWorkActivityLogs = await _repo.getLogsByTask(
        taskId,
        since: mustGetLogData ? null : taskActivityLogsLastModifiedLocal,
      );

      // Remove the updated work-activity-logs from memory (state)
      final tasksIds = updatedTaskWorkActivityLogs.map((log) => log.id);
      state.removeWhere((log) => tasksIds.contains(log.id));

      // Add the updated work-activity-logs to memory (state)
      state = [
        ...state,
        ...updatedTaskWorkActivityLogs.cast<WorkActivityLog>(),
      ];

      // return the users who's work activity log is updated
      // This includes all the users who have an updated work-activity-log in this task
      // NOTE: below may NOT include every user who have a work activity log in this task
      return updatedTaskWorkActivityLogs
          .map((log) => log.user)
          .toList()
          // To ensure no duplicates
          .toSet()
          .toList();
    } else {
      // No need to call the server, all the work-activity-logs of this task exist in memory
      // But the user instances of these work-activity-logs may or may not exist in memory
      return null;
    }
    // } catch (e) {
    //   debugPrint("Error loading project tasks,\nerror: $e");
    //   // state = state.copyWith(error: e.toString());
    //   return state;
    // }
  }

  /// End an active work session by its ID
  Future<void> endWorkSession(WorkActivityLog endedLog) async {
    if (activeLog == null) {
      throw "Failed to end work activity session: No Active log to end!";
    }

    // Replace the old log entry with the updated one
    state = [
      for (final log in state)
        if (log.id == activeLog!.id) endedLog else log,
    ];

    activeLog = null;
  }
}
