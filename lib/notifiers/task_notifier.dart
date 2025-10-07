import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/task.dart';
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

  /// Get user’s currently active task
  Future<void> loadActiveTask() async {
    _activeTask = await _repo.fetchActiveTask();
  }

  /// Start a task
  Future<void> startTask(Task task) async {
    await _repo.startTask(task.id);

    // Update state locally
    _activeTask = task.copyWithSafe(status: 'In Progress');
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
      final updatedTask = _activeTask!.copyWithSafe(
        status: status ?? 'Stopped',
        dateCompleted: isCompleted ? DateTime.now() : null,
      );

      // Replace in the list
      state = [
        for (final t in state)
          if (t.id == updatedTask.id) updatedTask else t,
      ];
    }

    _activeTask = null;
  }
}
