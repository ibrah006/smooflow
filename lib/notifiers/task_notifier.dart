import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/local_http.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/models/work_activity_log.dart';
import 'package:smooflow/core/repositories/task_repo.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/states/task.dart';

class TaskNotifier extends StateNotifier<TaskState> {
  TaskNotifier(this._repo) : super(TaskState());

  final TaskRepo _repo;

  static const _dataReloadMinInterval = Duration(seconds: 30);

  Task? _activeTask;
  bool _loading = false;

  bool get loading => _loading;
  Task? get activeTask => _activeTask;

  late final TaskWebSocketClient _client;

  List<Task> get todaysProductionTasks {
    return state.tasks.where((task) {
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
    state = state.add(task);
  }

  List<Task> byStatus({required TaskStatus? status}) {
    return status==null?
      state.tasks
      : state.tasks.where((task)=> status == task.status).toList();
  }

  int countByStatus({required TaskStatus? status}) {
    return byStatus(status: status).length;
  }

  List<Task> getTasks({required List<int> taskIds, TaskStatus? taskStatus}) {
    return state.tasks.where((task) {
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
      if (tasks == state.tasks) {
        // To prevent unessary state updates and widget rebuilds if the fetched tasks are the same as the current state
        return;
      }
      state = state.copyWith(tasks: tasks);
    } finally {
      _loading = false;
    }
  }

  /// Load only current user’s tasks
  Future<void> loadMyTasks() async {
    _loading = true;
    try {
      final tasks = await _repo.fetchMyTasks();
      state = state.copyWith(tasks: tasks);
    } finally {
      _loading = false;
    }
  }

  Future<Task?> getTaskById(int taskId, {bool forceReload = false}) async {
    try {
      // Find the local version of the task (if any)
      late final Task? localTask = state.taskById(taskId);

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
      final updatedList = [...state.tasks];

      final index = updatedList.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        updatedList[index].replaceWith(fetchedTask);
      } else {
        updatedList.add(fetchedTask);
      }

      state = state.copyWith(tasks: updatedList);

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
            (item) => (state.tasks.map((task) {
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
      state.tasks.removeWhere((task) => tasksIds.contains(task.id));

      // Add the updated tasks to memory (state)
      state = state.copyWith(
        tasks: updatedProjectTasks
      );

      return TasksResponse(
        tasks: updatedProjectTasks,
        isUpdatedFromDatabase: true,
        tasksLastModifiedAt: projectTasksLastModifiedServer,
      );
    } else {
      return TasksResponse(
        tasks: state.tasks.where((task) => task.projectId == projectId).toList(),
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

    state.copyWith(
      tasks: state.tasks.map((t) {
          if (t.id == taskId) {
            // Update task state - add work activity log and update status
            t.workActivityLogs.add(workActivityLog.id);
            t.activityLogLastModified = DateTime.now();
            t.status = getTaskStartStatus;
            _activeTask = t;
          }
          return t;
        }).toList()
    );

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
      state = state.copyWith(
        tasks: [
          for (final t in state.tasks)
            if (t.id == _activeTask!.id) _activeTask! else t,
        ] 
      );
    }

    _activeTask = null;
  }

  /// Fetch today's production team's schedules
  Future<void> fetchProductionScheduleToday({TaskStatus? status, bool isCompleted = false}) async {
    final tasksToday = await _repo.getProductionScheduleToday();

    final tasksTodayIds = tasksToday.map((task)=> task.id);

    state.tasks.removeWhere((task)=> tasksTodayIds.contains(task.id));

    // Update Tasks
    state = state.copyWith(
      tasks: tasksToday
    );
  }

  Future<void> _assignPrinter({required int taskId, required String printerId}) async {
    await _repo.assignPrinter(taskId, printerId);

    state = state.copyWith(
      tasks: state.tasks.map((task) {
        if (task.id == taskId) {
          task.printerId = printerId;
          task.status = TaskStatus.printing;
        }
        return task;
      }).toList()
    );
  }

  Future<void> _unassignPrinter({required int taskId, required TaskStatus status}) async {
    await _repo.unassignPrinter(taskId, status);

    state = state.copyWith(
      tasks: state.tasks.map((task) {
        if (task.id == taskId) {
          task.printerId = null;
          task.status = status;
        }
        return task;
      }).toList()
    );
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

      print("$taskId to printing status and assigned printer $printerId");
    } else {
      try {
        final task = state.taskById(taskId);
        if (task!.printerId != null && printerId == null) {
          await _unassignPrinter(taskId: taskId, status: newStatus);
          print("Progressed task $taskId to $newStatus status and unassigned printer");
        }
      } catch(e) {}
    }

    try {
      state.tasks.firstWhere((task)=> task.id == taskId).status = newStatus;
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

    state = state.copyWith(
      tasks: state.tasks.map((task) {
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
      }).toList()
    );
  }

  // ---------------------------------------------------------------------
  // LISTENING TO WEB SCOKET UPDATES
  // ---------------------------------------------------------------------

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  /// Initialize WebSocket and setup listeners
  Future<void> _initializeSocket() async {

    final jwtToken = LocalHttp.prefs.get(SharedStorageOptions.jwtToken.name) as String;

    _client = TaskWebSocketClient(authToken: jwtToken);

    // Listen to connection status
    _client.connectionStatus.listen((status) {
      _connectionStatus = status;
    });

    // Listen to task changes
    _client.taskChanges.listen(_handleTaskChange);

    // Listen to task list updates
    _client.taskList.listen((tasks) {
      state = state.copyWith(tasks: tasks, isLoading: false);
    });

    // Listen to errors
    _client.errors.listen((error) {
      
      state = state.copyWith(
        error: error,
        isLoading: false
      );
    });

    // Connect to WebSocket
    try {
      await _client.connect();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to connect: $e',
      );
    }
  }

  /// Handle task change events
  void _handleTaskChange(TaskChangeEvent event) {
    switch (event.type) {
      case TaskChangeType.created:
        if (event.task != null && !state.tasks.any((t) => t.id == event.taskId)) {
          state = state.insert(0, event.task!);
        }
        break;

      case TaskChangeType.updated:
      case TaskChangeType.statusChanged:
      case TaskChangeType.assigneeAdded:
      case TaskChangeType.assigneeRemoved:
        final index = state.tasks.indexWhere((t) => t.id == event.taskId);
        if (index != -1 && event.task != null) {
          state.tasks[index] = event.task!;
        }
        
        // Update selected task if it's the one that changed
        if (state.selectedTask?.id == event.taskId && event.task != null) {
          state.selectedTask = event.task;
        }
        break;

      case TaskChangeType.deleted:
        state.tasks.removeWhere((t) => t.id == event.taskId);
        if (state.selectedTask?.id == event.taskId) {
          state.selectedTask = null;
        }
        // To notify about change
        state = state;
        break;
    }
  }

  /// Load all tasks
  Future<void> loadTasks({Map<String, dynamic>? filters}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      _client.listTasks(filters: filters);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load tasks: $e',
        isLoading: false
      );
    }
  }

  /// Refresh tasks
  Future<void> refreshTasks() async {
    state = state.copyWith(
      isLoading: true
    );
    _client.refreshTasks();
  }

  /// Load a specific task
  Future<void> loadTask(int taskId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      _client.subscribeToTask(taskId);
      _client.getTask(taskId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load task: $e',
        isLoading: false
      );
    }
  }

  /// Select a task
  void selectTask(Task task) {
    state = state.copyWith(selectedTask: task);
    _client.subscribeToTask(task.id);
  }

  /// Deselect task
  void deselectTask() {
    if (state.selectedTask != null) {
      _client.unsubscribeFromTask(state.selectedTask!.id);
      state.selectedTask = null;
      state = state.copyWith(
        selectedTask: null
      );
    }
  }

  /// Filter tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return state.tasks.where((task) => task.status == status).toList();
  }

  /// Get tasks sorted by priority
  List<Task> getTasksByPriority() {
    final sortedTasks = List<Task>.from(state.tasks);
    sortedTasks.sort((a, b) => b.priority.compareTo(a.priority));
    return sortedTasks;
  }

  /// Get overdue tasks
  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    return state.tasks.where((task) {
      return task.dueDate != null && 
             task.dueDate!.isBefore(now) && 
             task.status != 'completed';
    }).toList();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(
      error: null
    );
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
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
