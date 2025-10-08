import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/repositories/work_activity_log_repo.dart';

class WorkActivityLogNotifier extends StateNotifier<List<WorkActivityLog>> {
  WorkActivityLogNotifier(this._repo) : super([]);

  final WorkActivityLogRepo _repo;

  WorkActivityLog? _activeLog;

  WorkActivityLog? get activeLog => _activeLog;

  set activeLog(WorkActivityLog? log) => _activeLog = log;

  /// Load all logs for a specific task
  Future<void> loadLogsByTask(int taskId) async {
    final logs = await _repo.getLogsByTask(taskId);

    // Remove previous logs of the same task
    final filtered = state.where((log) => log.taskId != taskId).toList();

    // Add the new logs
    state = [...filtered, ...logs];
  }

  /// Start a work session for a given user and task
  Future<void> startWorkSession(WorkActivityLog log) async {
    _activeLog = log;
    state = [...state, log];
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
