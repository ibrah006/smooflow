import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/user.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/notifiers/stream/event_notifier.dart';
import 'package:smooflow/repositories/work_activity_log_repo.dart';

class WorkActivityLogNotifier extends StateNotifier<List<WorkActivityLog>> {
  WorkActivityLogNotifier(this._repo) : super([]) {
    _activeLog = Future.delayed(Duration.zero).then((val) {
      return null;
    });
  }

  final WorkActivityLogRepo _repo;

  late Future<WorkActivityLog?> _activeLog;

  // duration in seconds
  EventNotifier<int>? _activeLogDurationNotifier;

  EventNotifier<int>? get activeLogDurationNotifier =>
      _activeLogDurationNotifier;

  set __activeLogDurationNotifier(EventNotifier<int>? newVal) {
    _activeLogDurationNotifier = newVal;
  }

  set activeLog(Future<WorkActivityLog?> log) {
    _activeLog = log;
  }

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
          .where((log) => log.taskId == taskId)
          .map((log) => log.user)
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

  bool _activeActivityLogInitialized = false;

  // Get Current user active work-activity-log
  // value assigned to [_activeLog]
  // Accessed from getter activeLog
  Future<WorkActivityLog?> get activeLog async {
    if (!_activeActivityLogInitialized) {
      _activeLog = _repo.getActiveLog();

      if ((await _activeLog) != null) {
        __activeLogDurationNotifier = EventNotifier<int>();
      }

      _activeActivityLogInitialized = true;
    }

    return _activeLog;
  }

  // Start work session
  Future<void> startWorkSession({
    required int newLogId,
    required int taskId,
  }) async {
    if (await activeLog != null) {
      throw "Failed to start work activity session: An active log already exists!\nEnd it before starting another";
    }

    activeLog = Future.delayed(
      Duration.zero,
    ).then((val) => WorkActivityLog.create(id: newLogId, taskId: taskId));

    __activeLogDurationNotifier = EventNotifier<int>();

    state = [...state, (await activeLog)!];
  }

  /// End an active work session
  Future<void> endWorkSession() async {
    final aaLog = await activeLog;

    if (aaLog == null) {
      throw "Failed to end work activity session: No Active log to end!";
    }

    final endedLog = WorkActivityLog.end(aaLog);

    await activeLogDurationNotifier!.dispose();

    __activeLogDurationNotifier = null;

    // Replace the old log entry with the updated one
    state = [
      for (final log in state)
        if (log.id == aaLog.id) endedLog else log,
    ];

    activeLog = Future.delayed(Duration.zero).then((val) => null);
  }
}
