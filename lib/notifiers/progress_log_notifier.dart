import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/enums/progress_issue.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/repositories/progress_log_repo.dart';

class ProgressLogNotifier extends StateNotifier<List<ProgressLog>> {
  final ProgressLogRepo _repo;

  ProgressLogNotifier(this._repo) : super([]);

  // load progress logs
  // Future<void> load() async {
  //   final logs = await _repo.();
  //   state = logs;
  // }

  // create progress log
  Future<void> createProgressLog({
    required String projectId,
    required ProgressLog newLog,
  }) async {
    await _repo.createProgressLog(projectId, newLog);

    state = [...state, newLog];
  }

  // Get Log by Id
  Future<ProgressLog> getLog(String id) async {
    late final ProgressLog log;
    try {
      log = state.firstWhere((l) => l.id == id);
    } catch (e) {
      // not found in memory search, search in database
      log = await _repo.getProgressLog(id);
      // add the log to memory
      state.add(log);
    }

    return log;
  }

  Future<List<ProgressLog>> getLogsByProject(
    Project project, {
    bool ensureLatestLogDetails = true,
  }) async {
    final DateTime? progressLogLastModifiedAt =
        !ensureLatestLogDetails
            ? null
            : await _repo.getProjectProgressLogLastModified(project.id);

    final localUpdateNeeded =
        ensureLatestLogDetails
            ? progressLogLastModifiedAt?.isAfter(
              project.progressLogLastModifiedAt,
            )
            : false;

    late final bool mustGetLogData;
    if (localUpdateNeeded == true) {
      mustGetLogData = true;
    } else {
      // MUST GET LOCAL DATA (this boolean overrides ensureLatestLogDetails [whether t or f])
      mustGetLogData =
          // Although the latest info is not needed, what if the actual progress logs are not even loaded into the memory yet?
          // We can check to see if the reference progress log (IDs) that are in memory (through project model), is having an actual instance of it in memory
          !project.progressLogs.every(
            (item) => (state.map((log) {
              if (log.projectId == project.id) return log.id;
            })).toSet().contains(item),
          );
    }

    if (localUpdateNeeded == true || mustGetLogData) {
      final updatedProjectProgressLogs = await _repo.getProgressLogByProject(
        projectId: project.id,
        since: mustGetLogData ? null : project.progressLogLastModifiedAt,
      );

      // Remove the updated progress logs from memory (state)
      final logsIds = updatedProjectProgressLogs.map((log) => log.id);
      state.removeWhere((log) => logsIds.contains(log.id));

      // Add the updated progress logs to memory (state)
      state = [...state, ...updatedProjectProgressLogs];

      return updatedProjectProgressLogs;
    } else {
      return state.where((log) => log.projectId == project.id).toList();
    }
  }

  // update progress log
  Future<void> _updateProgressLog({
    required String updateLogId,
    required bool markAsCompleted,
    required ProgressIssue? issue,
    required String? description,
  }) async {
    // This Api call function will return completedAt datetime if the request was to mark this log as completed
    final completedAt = await _repo.updateProgressLog(
      updateLogId,
      update: {
        'description': description,
        'issue': issue?.name,
        'isCompleted': markAsCompleted,
      },
    );

    state =
        state.map((log) {
          if (log.id == updateLogId) {
            return log
              ..description = description
              ..issue = issue
              ..isCompleted = markAsCompleted
              ..completedAt = completedAt;
          } else {
            return log;
          }
        }).toList();
  }

  /// Update Progress log: use this function to mark the log as completed
  Future<void> markAsCompleted(ProgressLog log) async {
    await _updateProgressLog(
      updateLogId: log.id,
      markAsCompleted: true,
      issue: log.issue,
      description: log.description,
    );
  }

  /// Update Progress log: use this function to update issue and description of progress log
  Future<void> updateProgressLog(
    ProgressLog log, {
    required String updateDescription,
    required ProgressIssue updatedIssue,
  }) async {
    await _updateProgressLog(
      updateLogId: log.id,
      markAsCompleted: log.isCompleted,
      issue: updatedIssue,
      description: updateDescription,
    );
  }
}
