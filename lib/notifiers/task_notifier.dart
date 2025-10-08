import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/repositories/task_repo.dart';

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier(this._repo) : super([]);

  final TaskRepo _repo;

  Task? _activeTask;
  bool _loading = false;

  bool get loading => _loading;
  Task? get activeTask => _activeTask;

  /// Load all tasks (admin or global list)
  Future<void> loadAll() async {
    _loading = true;
    state = [];
    try {
      final tasks = await _repo.fetchAllTasks();
      state = tasks;
    } finally {
      _loading = false;
    }
  }

  /// Load only current user’s tasks
  Future<void> loadMyTasks() async {
    _loading = true;
    try {
      final tasks = await _repo.fetchMyTasks();
      state = tasks;
    } finally {
      _loading = false;
    }
  }

  /// Load all tasks for a given project
  Future<List<Task>> loadProjectTasks({
    required String projectId,
    bool forceReload = false,
    // Pass in the local project tasks last modified
    // This is the datetime of the last modified task of [projectId]
    required DateTime? projectTasksLastModifiedLocal,
    // project task Ids (ensure all the ids are included)
    required List<int> projectTaskIds,
  }) async {
    // try {
    final DateTime? projectTasksLastModifiedServer =
        !forceReload
            ? null
            : await _repo.getProjectTasksLastModified(projectId);

    final localUpdateNeeded =
        forceReload && projectTasksLastModifiedLocal != null
            ? projectTasksLastModifiedServer?.isAfter(
              projectTasksLastModifiedLocal,
            )
            : false;

    late final bool mustGetLogData;
    if (localUpdateNeeded == true) {
      mustGetLogData = true;
    } else {
      // MUST GET LOCAL DATA (this boolean overrides ensureLatestLogDetails [whether t or f])
      mustGetLogData =
          // Although the latest info is not needed, what if the actual tasks are not even loaded into the memory yet?
          // We can check to see if the reference tasks (IDs) that are in memory (through project model), is having an actual instance of it in memory
          !projectTaskIds.every(
            (item) => (state.map((task) {
              if (task.projectId == projectId) return task.id;
            })).toSet().contains(item),
          );
    }

    if (localUpdateNeeded == true || mustGetLogData) {
      final updatedProjectTasks = await _repo.getTasksByProject(
        projectId,
        since: mustGetLogData ? null : projectTasksLastModifiedLocal,
      );

      // Remove the updated tasks from memory (state)
      final tasksIds = updatedProjectTasks.map((task) => task.id);
      state.removeWhere((task) => tasksIds.contains(task.id));

      // Add the updated tasks to memory (state)
      state = [...state, ...updatedProjectTasks];

      return updatedProjectTasks;
    } else {
      return state.where((task) => task.projectId == projectId).toList();
    }
    // } catch (e) {
    //   debugPrint("Error loading project tasks,\nerror: $e");
    //   // state = state.copyWith(error: e.toString());
    //   return state;
    // }
  }

  /// Get user’s currently active task
  Future<void> loadActiveTask() async {
    _activeTask = await _repo.fetchActiveTask();
  }

  /// Start a task
  Future<void> startTask(Task task) async {
    await _repo.startTask(task.id);

    // Update local state
    task.status = "in-progress";
    final updated = [
      for (final t in state)
        if (t.id == task.id) _activeTask! else t,
    ];
    state = updated;
  }

  /// End currently active task
  Future<void> endActiveTask({String? status, bool isCompleted = false}) async {
    await _repo.endTask(status: status, isCompleted: isCompleted);

    if (_activeTask != null) {
      _activeTask!.status = status ?? "";
      _activeTask!.dateCompleted = isCompleted ? DateTime.now() : null;

      // Replace in the list
      state = [
        for (final t in state)
          if (t.id == _activeTask!.id) _activeTask! else t,
      ];
    }

    _activeTask = null;
  }
}
