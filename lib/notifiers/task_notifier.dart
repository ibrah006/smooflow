import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/repositories/task_repo.dart';

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier(this._repo) : super([]);

  final TaskRepo _repo;

  static const _dataReloadMinInterval = Duration(seconds: 30);

  Task? _activeTask;
  bool _loading = false;

  bool get loading => _loading;
  Task? get activeTask => _activeTask;

  loadTaskToMemory(Task task) {
    state = [...state, task];
  }

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

  Future<Task?> getTaskById(int taskId, {bool forceReload = false}) async {
    try {
      // Find the local version of the task (if any)
      late final Task? localTask;
      try {
        localTask = state.firstWhere((task) => task.id == taskId);
      } catch (e) {
        localTask = null;
      }

      // Prepare timestamps for delta-based sync
      final updatedAt = !forceReload ? localTask?.updatedAt : null;
      final activityLogLastModified =
          !forceReload ? localTask?.activityLogLastModified : null;
      final assigneeLastAdded =
          !forceReload ? localTask?.assigneeLastAdded : null;

      if (localTask != null) {
        final now = DateTime.now();
        final sampleFuture = now.add(Duration(days: 1));

        if (now.difference(updatedAt ?? sampleFuture) <
                _dataReloadMinInterval &&
            now.difference(activityLogLastModified ?? sampleFuture) <
                _dataReloadMinInterval &&
            now.difference(assigneeLastAdded ?? sampleFuture) <
                _dataReloadMinInterval) {
          // Preventing too frequent calls to server
          return localTask;
        }
      }

      // Call the backend repo function
      final fetchedTask = await _repo.getTaskById(
        taskId: taskId,
        updatedAt: updatedAt,
        activityLogLastModified: activityLogLastModified,
        assigneeLastAdded: assigneeLastAdded,
      );

      // If backend says everything is up-to-date
      if (fetchedTask == null) {
        return localTask; // No update needed
      }

      // Update in-memory state (replace or insert)
      final updatedList = [...state];
      final index = updatedList.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        updatedList[index].replaceWith(fetchedTask);
      } else {
        updatedList.add(fetchedTask);
      }

      state = updatedList;
      return fetchedTask;
    } catch (e, st) {
      print('Error loading task by ID: $e\n$st');
      rethrow;
    }
  }

  /// Load all tasks for a given project
  /// update local tasksLastModifiedAt
  Future<TasksResponse> loadProjectTasks({
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

    // Debug
    print(
      "tasksLastModifiedAtLocal: ${projectTasksLastModifiedLocal}, update needed: ${projectTasksLastModifiedServer?.isAfter(projectTasksLastModifiedLocal!)}",
    );

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

      return TasksResponse(
        tasks: updatedProjectTasks,
        isUpdatedFromDatabase: true,
        tasksLastModifiedAt: projectTasksLastModifiedServer,
      );
    } else {
      return TasksResponse(
        tasks: state.where((task) => task.projectId == projectId).toList(),
        isUpdatedFromDatabase: false,
        tasksLastModifiedAt: projectTasksLastModifiedServer,
      );
    }
    // } catch (e) {
    //   debugPrint("Error loading project tasks,\nerror: $e");
    //   // state = state.copyWith(error: e.toString());
    //   return state;
    // }
  }

  bool activeTaskInitialized = false;

  /// Get user’s currently active task
  Future<Task?> loadActiveTask(
    // {
    // This is not really required, but if the active task is already in memory it helps us save some time without having need to call to the api endpoint
    // depreacted
    // required int taskId,
    // }
  ) async {
    _activeTask = await _repo.fetchActiveTask();
    activeTaskInitialized = true;

    return _activeTask;
  }

  /// Start a task
  Future<WorkActivityLog> startTask(int taskId) async {
    final workActivityLog = await _repo.startTask(taskId);

    // Update local state
    state =
        state.map((t) {
          if (t.id == taskId) {
            // Update task state - add work activity log and update status
            t.workActivityLogs.add(workActivityLog.id);
            t.activityLogLastModified = DateTime.now();
            t.status = "in-progress";
            _activeTask = t;
          }
          return t;
        }).toList();

    if (_activeTask == null)
      throw "Task to activate not found in memory, unexpected exception";

    return workActivityLog;
  }

  /// End currently active task
  Future<void> endActiveTask({String? status, bool isCompleted = false}) async {
    await _repo.endTask(status: status, isCompleted: isCompleted);

    if (_activeTask != null) {
      _activeTask!.status = status ?? _activeTask!.status;
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

class TasksResponse {
  final List<Task> tasks;
  final bool isUpdatedFromDatabase;
  // for a specific project
  final DateTime? tasksLastModifiedAt;
  TasksResponse({
    required this.tasks,
    required this.isUpdatedFromDatabase,
    this.tasksLastModifiedAt,
  });
}
