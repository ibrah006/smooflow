import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/models/work_activity_log.dart';
import 'package:smooflow/core/repositories/task_repo.dart';
import 'package:smooflow/core/services/login_service.dart';

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier(this._repo) : super([]);

  final TaskRepo _repo;

  static const _dataReloadMinInterval = Duration(seconds: 30);

  Task? _activeTask;
  bool _loading = false;

  bool get loading => _loading;
  Task? get activeTask => _activeTask;

  List<Task> get todaysProductionTasks {
    return state.where((task) {
      final startDate = task.productionStartTime;
      if (startDate != null) {
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final tomorrowStart = todayStart.add(Duration(days: 1));

        if (startDate.isAfter(todayStart) && startDate.isBefore(tomorrowStart)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  loadTaskToMemory(Task task) {
    state = [...state, task];
  }

  List<Task> byStatus({required TaskStatus? status}) {
    return status==null?
      state
      : state.where((task)=> status == task.status).toList();
  }

  int countByStatus({required TaskStatus? status}) {
    return byStatus(status: status).length;
  }

  List<Task> getTasks({required List<int> taskIds, TaskStatus? taskStatus}) {
    return state.where((task) {
      return taskIds.contains(task.id) && (taskStatus == null || task.status == taskStatus);
    }).toList();
  }

  /// Load all tasks (admin or global list)
  Future<void> loadAll() async {
    _loading = true;
    // What's the purpose of this?
    // state = [];
    try {
      final tasks = await _repo.fetchAllTasks();
      if (tasks == state) {
        // To prevent unessary state updates and widget rebuilds if the fetched tasks are the same as the current state
        return;
      }
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
    // print(
    //   "tasksLastModifiedAtLocal: ${projectTasksLastModifiedLocal}, update needed: ${projectTasksLastModifiedServer?.isAfter(projectTasksLastModifiedLocal!)}",
    // );

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

  TaskStatus get getTaskStartStatus  {
    final currentUser = LoginService.currentUser;
    switch (currentUser?.role) {
      case 'production': return TaskStatus.printing;
      case 'design': return TaskStatus.designing;
      case 'finishing': return TaskStatus.finishing;
      case 'application': return TaskStatus.installing;
      case 'admin': return TaskStatus.printing;
      default: throw "Your role doesn't have priveleges to start Task";
    }
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
            t.status = getTaskStartStatus;
            _activeTask = t;
          }
          return t;
        }).toList();

    if (_activeTask == null)
      throw "Task to activate not found in memory, unexpected exception";

    return workActivityLog;
  }

  /// End currently active task
  Future<void> endActiveTask({TaskStatus? status, bool isCompleted = false}) async {
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

  /// Fetch today's production team's schedules
  Future<void> fetchProductionScheduleToday({TaskStatus? status, bool isCompleted = false}) async {
    final tasksToday = await _repo.getProductionScheduleToday();

    final tasksTodayIds = tasksToday.map((task)=> task.id);

    state.removeWhere((task)=> tasksTodayIds.contains(task.id));

    state = [
      ...state,
      ...tasksToday
    ];
  }

  Future<void> _assignPrinter({required int taskId, required String printerId}) async {
    await _repo.assignPrinter(taskId, printerId);

    state = state.map((task) {
      if (task.id == taskId) {
        task.printerId = printerId;
        task.status = TaskStatus.printing;
      }
      return task;
    }).toList();
  }

  Future<void> _unassignPrinter({required int taskId, required TaskStatus status}) async {
    await _repo.unassignPrinter(taskId, status);

    state = state.map((task) {
      if (task.id == taskId) {
        task.printerId = null;
        task.status = status;
      }
      return task;
    }).toList();
  }

  Future<void> progressStage({required int taskId, required TaskStatus newStatus, String? printerId}) async {

    if (printerId == null && newStatus == TaskStatus.printing) {
      throw "Printer ID must be provided when progressing task to printing status";
    }

    await _repo.progressStage(taskId, newStatus);

    if (newStatus == TaskStatus.printing) {
      await _assignPrinter(
        taskId: taskId,
        printerId: printerId!,
      );

      print("Progressed task $taskId to printing status and assigned printer $printerId");
    } else {
      try {
        final task = state.firstWhere((task)=> task.id == taskId);
        if (task.printerId != null) {
          if (task.status != newStatus) await _unassignPrinter(taskId: taskId, status: newStatus);
          print("Progressed task $taskId to $newStatus status and unassigned printer");
        }
      } catch(e) {}
    }

    try {
      state.firstWhere((task)=> task.id == taskId).status = newStatus;
    } catch(e) {
      print("Error updating task status in memory after progressing stage\nFetching task from database to update in-memory state");
      await getTaskById(taskId, forceReload: true);
    }
  }

  Future<void> schedulePrint({
    required int taskId,
    required String printerId,
    required String materialId,
    String progressStage = 'production',
    int runs = 1,
    required int productionQuantity,
    required String barcode
  }) async {
    await _repo.schedulePrint(
      taskId: taskId,
      printerId: printerId,
      materialId: materialId,
      progressStage: progressStage,
      runs: runs,
      productionQuantity: productionQuantity,
      barcode: barcode
    );

    state = state.map((task) {
      if (task.id == taskId) {
        task.printerId = printerId;
        task.status = TaskStatus.printing;
        task.materialId = materialId;
        task.actualProductionStartTime = DateTime.now();
        task.runs = runs;
        task.productionQuantity = productionQuantity.toDouble();
        task.stockTransactionBarcode = barcode;
      }
      return task;
    }).toList();
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
