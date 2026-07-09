import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/models/print_spec.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/models/work_activity_log.dart';
import 'package:smooflow/core/repositories/task_repo.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/billing_status.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/message_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/states/task.dart';

class TaskCacheNotifier
    extends FamilyNotifier<FilteredTaskCacheState, TaskFilter> {
  final TaskRepo _repo;
  late final TaskWebSocketClient _client;

  Task? _activelyWorkingTask;
  bool _loading = false;

  bool get loading => _loading;
  Task? get activeTask => _activelyWorkingTask;
  ConnectionStatus get connectionStatus => state.connectionStatus;

  // final Ref ref;
  TaskCacheNotifier(
    this._repo,
    this._client,
    // this.ref
  ) : super() {
    _initializeSocket();
  }

  bool mounted = true;

  @override
  FilteredTaskCacheState build(TaskFilter arg) {
    // 1. 'arg' is passed directly into the build method here.
    // 2. Initialize your default pristine state structure for this specific filter.
    return FilteredTaskCacheState.empty();
  }

  /// Example: Accessing 'arg' to query filtered parameters from your API
  Future<void> fetchMetadataCounts() async {
    // Set a loading state locally using current cache mappings
    state = FilteredTaskCacheState(
      totalCounts: state.totalCounts,
      cachedTasks: state.cachedTasks,
      isLoadingCounts: true,
    );

    // Using 'arg' to supply filter criteria to the backend call
    final counts = await _repo.getCounts(
      projectId: arg.projectId,
      assigneeId: arg.assigneeId,
      searchQuery: arg.searchQuery,
    );

    // Update the state with the returned values
    state = FilteredTaskCacheState(
      totalCounts: counts,
      cachedTasks: state.cachedTasks,
      isLoadingCounts: false,
    );
  }

  Future<void> loadPage({
    required TaskStatus status,
    required int indexWithinStatus,
  }) async {
    const int pageSize = 50;
    final int virtualPage = indexWithinStatus ~/ pageSize;
    final int offset = virtualPage * pageSize;

    // Check 'state' to see if this slot is already warm in memory
    final statusMap =
        state.cachedTasks[status]; // <--- Reading FilteredTaskCache
    if (statusMap != null && statusMap.containsKey(offset)) {
      return; // Already loaded! Short-circuit network request.
    }

    // Hit backend using specific filters tracked by 'arg'
    final incomingTasks = await _repo.fetchV2(
      status: status,
      limit: pageSize,
      offset: offset,
      projectId: arg.projectId,
    );

    // Deep copy and mutate the map structure safely
    final Map<TaskStatus, Map<int, Task>> updatedCache = {
      for (final entry in state.cachedTasks.entries)
        entry.key: Map.of(entry.value),
    };

    final currentStatusMap = updatedCache.putIfAbsent(status, () => {});
    for (int i = 0; i < incomingTasks.length; i++) {
      currentStatusMap[offset + i] = incomingTasks[i];
    }

    // Trigger UI repaint by dispatching completely renewed state object
    state = FilteredTaskCacheState(
      totalCounts: state.totalCounts,
      cachedTasks: updatedCache,
    );
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
    _activelyWorkingTask = await _repo.fetchActiveTask();
    activeTaskInitialized = true;

    return _activelyWorkingTask;
  }

  TaskStatus get getTaskStartStatus {
    final currentUser = LoginService.currentUser;
    switch (currentUser?.role) {
      case 'production':
        return TaskStatus.printing;
      case 'design':
        return TaskStatus.designing;
      case 'finishing':
        return TaskStatus.finishing;
      case 'application':
        return TaskStatus.installing;
      case 'admin':
        return TaskStatus.printing;
      default:
        throw "Your role doesn't have priveleges to start Task";
    }
  }

  /// Start a task
  Future<WorkActivityLog> startWorkingTask(int taskId) async {
    final workActivityLog = await _repo.startTask(taskId);

    // Update local state

    state.copyWith(
      tasks:
          state.tasks.map((t) {
            if (t.id == taskId) {
              // Update task state - add work activity log and update status
              t.workActivityLogs.add(workActivityLog.id);
              t.activityLogLastModified = DateTime.now();
              t.status = getTaskStartStatus;
              _activelyWorkingTask = t;
            }
            return t;
          }).toList(),
    );

    if (_activelyWorkingTask == null)
      throw "Task to activate not found in memory, unexpected exception";

    return workActivityLog;
  }

  /// End currently active task
  Future<void> endActivelyWorkingTask({
    TaskStatus? status,
    bool isCompleted = false,
  }) async {
    await _repo.endTask(status: status, isCompleted: isCompleted);

    if (_activelyWorkingTask != null) {
      _activelyWorkingTask!.status = status ?? _activelyWorkingTask!.status;
      _activelyWorkingTask!.dateCompleted = isCompleted ? DateTime.now() : null;

      // Replace in the list
      state = state.copyWith(
        tasks: [
          for (final t in state.tasks)
            if (t.id == _activelyWorkingTask!.id) _activelyWorkingTask! else t,
        ],
      );
    }

    _activelyWorkingTask = null;
  }

  TaskStatus getTaskStatus(int taskId) {
    try {
    final task = state.cachedTasks.values
        .expand((statusMap) => statusMap.values)
        .firstWhere((task) => task.id == taskId);
    
    return task.status;
    }catch(e) {
      throw "Task with ID $taskId not found in memory";
    }
  }
  
  /// Assumes the task is already in memory
  Future<void> _assignPrinter({
    required Task task,
    required String printerId,
  }) async {
    await _repo.assignPrinter(task.id, printerId);

    state.cachedTasks[task.status]?.update(task.id, (t) {
      return t
        ..printerId = printerId
        ..status = TaskStatus.printing;
    });
    state = state;
  }

  /// Assumes the task is already in memory
  Future<void> _unassignPrinter({
    required Task task,
    required TaskStatus status,
  }) async {
    await _repo.unassignPrinter(task.id, status);

    state.cachedTasks[task.status]?.update(task.id, (t) {
      return t
        ..printerId = printerId
        ..status = TaskStatus.printing;
    })

    state = state.copyWith(
      tasks:
          state.tasks.map((task) {
            if (task.id == taskId) {
              task.printerId = null;
              task.status = status;
            }
            return task;
          }).toList(),
    );
  }

  Future<void> progressStage({
    required int taskId,
    required TaskStatus newStatus,
    String? printerId,
    bool isStageForward = true,
  }) async {
    if (printerId == null && newStatus == TaskStatus.printing) {
      throw "Printer ID must be provided when progressing task to printing status";
    }

    await _repo.progressStage(
      taskId,
      newStatus,
      isStageForward: isStageForward,
    );

    if (newStatus == TaskStatus.printing) {
      await _assignPrinter(taskId: taskId, printerId: printerId!);

      print("$taskId to printing status and assigned printer $printerId");
    } else {
      try {
        final task = state.taskById(taskId);
        if (task!.printerId != null && printerId == null) {
          await _unassignPrinter(taskId: taskId, status: newStatus);
          print(
            "Progressed task $taskId to $newStatus status and unassigned printer",
          );
        }
      } catch (e) {}
    }

    try {
      state.tasks.firstWhere((task) => task.id == taskId).status = newStatus;
    } catch (e) {
      print(
        "Error updating task status in memory after progressing stage\nFetching task from database to update in-memory state",
      );
      await getTaskById(taskId, forceReload: true);
    }
  }

  // Returns stock out transaction, if committed
  Future<StockTransaction?> schedulePrint({
    required int taskId,
    required String printerId,
    required String materialId,
    String progressStage = 'production',
    int runs = 1,
    required int productionQuantity,
    required String barcode,
  }) async {
    final stockOutTransaction = await _repo.schedulePrint(
      taskId: taskId,
      printerId: printerId,
      materialId: materialId,
      progressStage: progressStage,
      runs: runs,
      productionQuantity: productionQuantity,
      barcode: barcode,
    );

    state = state.copyWith(
      tasks:
          state.tasks.map((task) {
            if (task.id == taskId) {
              task.printerId = printerId;
              task.status = TaskStatus.printing;
              task.materialId = materialId;
              task.actualProductionStartTime = DateTime.now();
              task.runs = runs;
              task.productionQuantity = productionQuantity.toDouble();
              // task.stockTransactionBarcode = barcode;
              task.stockTransactionIds.add(stockOutTransaction!.id);
            }
            return task;
          }).toList(),
    );

    return stockOutTransaction;
  }

  // IF any of the fields to be updated is to be reset to a null value, just pass in empty string or default value like (empty string or 0)
  Future<void> update({
    required Task task,
    required BillingStatus? billingStatus,
    @deprecated required String? ref,
    @deprecated required int? quantity,
    @deprecated required String? size,
    required String? name,
    required DateTime? date,
    required List<PrintSpec>? updatedPrintSpecs,
    required PrintSpec? newPrintSpec,
    required int? deletePrintSpecId,
    required TaskPriority? priority,
  }) async {
    int? localTaskNameChangeEventId;
    if (name != null) {
      final canUpdateName = state.canUpdateName(taskId: task.id, newName: name);

      if (canUpdateName) {
        // Add to the list of name change events underway to prevent other updates with the same name until this one is resolved
        localTaskNameChangeEventId = state.newNameChangeEvent(
          taskId: task.id,
          newName: name,
          oldName: task.name,
        );
      } else {
        name = null;
      }
    }

    print(
      "[TaskNotifier] update called with - billingStatus: $billingStatus, ref: $ref, quantity: $quantity, size: $size, name: $name, date: $date",
    );

    if (billingStatus == null &&
        ref == null &&
        quantity == null &&
        size == null &&
        name == null &&
        date == null &&
        updatedPrintSpecs == null &&
        newPrintSpec == null &&
        deletePrintSpecId == null &&
        priority == null) {
      // Nothing to update
      return;
    }

    if (newPrintSpec != null) {
      state.addCurrentlyCreatingSpec(task.id, newPrintSpec.id);
    }

    if (deletePrintSpecId != null) {
      state.addCurrentlyCreatingSpec(task.id, deletePrintSpecId);
    }

    await _repo.update(
      task: task,
      billingStatus: billingStatus,
      ref: ref,
      quantity: quantity,
      size: size,
      name: name,
      date: date,
      updatedPrintSpecs: updatedPrintSpecs,
      newPrintSpec: newPrintSpec,
      deletePrintSpecId: deletePrintSpecId,
      priority: priority,
    );

    if (localTaskNameChangeEventId != null) {
      state.removeTaskNameChangeEvent(localTaskNameChangeEventId);
    }

    if (deletePrintSpecId != null) {
      state.specDeleted(deletePrintSpecId);
    }

    // state = state.updateTask(task);
  }

  Future<void> updateMessageReadStatus(WidgetRef ref, int taskId) async {
    final task = state.taskById(taskId);

    if (task?.unreadCount == 0) {
      // No unread messages, no need to call the API
      return;
    }

    final lastMessageForTask = ref
        .read(messageNotifierProvider)
        .lastMessageForTask(taskId);

    if (lastMessageForTask == null) {
      // No messages for this task loaded in memory, so need to update read status
      return null;
    }

    // Update local state first
    state = state.copyWith(
      tasks:
          state.tasks.map((task) {
            if (task.id == taskId) {
              task.unreadCount = 0;
            }
            return task;
          }).toList(),
    );

    await _repo.updateMessageReadStatus(
      taskId: taskId,
      lastSeenMessageId: lastMessageForTask.id,
    );
  }

  void updateUnreadCount({
    required int taskId,

    /// Message id of the new message that triggered the unread count update
    required int messageId,
    int? unreadCount,
    int? incrementUnreadCount,
  }) {
    state = state.updateUnreadCount(
      taskId: taskId,
      messageId: messageId,
      unreadCount: unreadCount,
      incrementCount: incrementUnreadCount,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // WEBSOCKET FUNCTIONALITY
  // ─────────────────────────────────────────────────────────────────────────────

  /// Initialize WebSocket and setup listeners
  void _initializeSocket() {
    _initialize();
  }

  void _initialize() {
    // Listen to connection status
    _client.connectionStatus.listen((status) {
      if (mounted) {
        state = state.copyWith(connectionStatus: status);
      }
    });

    // Listen to task changes
    _client.taskChanges.listen((event) => _handleTaskChange(ref, event));

    // Listen to task list updates
    _client.taskList.listen((tasks) {
      if (mounted) {
        state = state.copyWith(tasks: tasks, isLoading: false, error: null);
      }
    });

    // Listen to errors
    _client.errors.listen((error) {
      if (mounted) {
        state = state.copyWith(error: error, isLoading: false);
      }
    });
  }

  /// Handle task change events from WebSocket
  void _handleTaskChange(Ref ref, TaskChangeEvent event) {
    print(
      '[TaskNotifier] _handleTaskChange: ${event.type}, taskId: ${event.taskId}, mounted: $mounted',
    );

    if (!mounted) {
      print('[TaskNotifier] Notifier not mounted, ignoring change');
      return;
    }

    final tasks = List<Task>.from(state.tasks);

    switch (event.type) {
      case TaskChangeType.created:
        if (event.task != null && !tasks.any((t) => t.id == event.taskId)) {
          if (!tasks.contains(event.task)) {
            tasks.add(event.task!);

            state = state.copyWith(tasks: tasks);
            print('[TaskNotifier] Task created, new count: ${tasks.length}');
          }
        }

        ref.read(projectByIdProvider(event.task!.projectId))!.tasksCount++;

        break;

      case TaskChangeType.updated:
        print(
          "[Task Notifier] BEFORE currently creating specs: ${state.currentlyCreatingSpecs}",
        );
        state = state.copyWith(
          tasks:
              tasks.map((t) {
                if (t.id == event.taskId && event.task != null) {
                  return event.task!;
                }
                return t;
              }).toList(),
          currentlyCreatingSpecs: state.currentlyCreatingSpecs,
        );

        print(
          "[Task Notifier] AFTER currently creating specs: ${state.currentlyCreatingSpecs}",
        );

        print('[Task Notifier] new task event changes: ${event.changes}');

        // Check if task has just been marked as completed
        if (
        // This means that it's a status update event
        event.changes?["status"] != null &&
            // And that the new status is completed
            event.task!.status == TaskStatus.completed) {
          ref
              .read(projectByIdProvider(event.task!.projectId))!
              .completedTasksCount++;
        } else if (event.changes?["newPrintSpec"] != null) {
          // This means that it's a new print spec event

          state.initializeCurrentlyCreatingSpec(
            event.task!.id,
            event.changes!["newPrintSpec"]["tempLocalId"],
            event.changes!["newPrintSpec"]["id"],
          );

          // ref.read(taskNotifierProvider).currentlyCreatingSpecs[event
          //         .task!
          //         .id] =
          //     ref
          //         .read(taskNotifierProvider)
          //         .currentlyCreatingSpecs[event.taskId]
          //         ?.map((spec) {
          //           print(
          //             "[Task Notifier] new print spec tempLocalId: ${event.changes!["newPrintSpec"]["tempLocalId"]}",
          //           );
          //           if (spec.tempLocalId ==
          //               event.changes!["newPrintSpec"]["tempLocalId"]) {
          //             spec.initializeId(event.changes!["newPrintSpec"]["id"]);
          //           }

          //           return spec;
          //         })
          //         .toList() ??
          //     [];
        }

        break;
      case TaskChangeType.statusChanged:
        final index = tasks.indexWhere((t) => t.id == event.taskId);
        print(
          '[TaskNotifier] Looking for task ${event.taskId}, found at index: $index',
        );

        // If task already exists in memory
        if (index != -1) {
          if (event.task != null) {
            tasks[index] = event.task!;
            print("event task: ${event.task?.toJson()}");
            print(
              '[TaskNotifier] Updated task at index $index with new object',
            );
          } else if (event.changes != null) {
            // Partial update
            tasks[index] = _applyChanges(tasks[index], event.changes!);
            print(
              '[TaskNotifier] Applied partial changes to task at index $index',
            );
          }
          state = state.copyWith(tasks: tasks);
        } else {
          print(
            '[TaskNotifier] Task ${event.taskId} NOT FOUND in state (count: ${tasks.length})',
          );
        }

        // Update selected task if it's the one that changed
        if (state.selectedTask?.id == event.taskId && event.task != null) {
          state = state.copyWith(selectedTask: event.task);
        }
        break;

      case TaskChangeType.deleted:
        tasks.removeWhere((t) => t.id == event.taskId);
        state = state.copyWith(tasks: tasks);

        // Clear selected task if it was deleted
        if (state.selectedTask?.id == event.taskId) {
          state = state.copyWith(selectedTask: null);
        }

        ref.read(projectByIdProvider(event.task!.projectId))!.tasksCount--;

        break;

      case TaskChangeType.assigneeAdded:
        break;
      case TaskChangeType.assigneeRemoved:
        final index = tasks.indexWhere((t) => t.id == event.taskId);
        if (index != -1 && event.task != null) {
          tasks[index] = event.task!;
          state = state.copyWith(tasks: tasks);
        }
        break;
      case TaskChangeType.nameUpdated:
        final index = tasks.indexWhere((t) => t.id == event.taskId);
        if (index != -1 && event.task != null) {
          tasks[index] = event.task!;
          state = state.copyWith(tasks: tasks);
        }
        break;
      case TaskChangeType.newProject:
        print("new project event, ${event.project!.name}");
        ref
            .read(projectNotifierProvider.notifier)
            .loadProjectToMemory(event.project!);
      case TaskChangeType.deleteProject:
        print("new project event, ${event.project!.name}");
        ref
            .read(projectNotifierProvider.notifier)
            .deleteProject(event.project!.id);
    }
  }

  /// Apply partial changes to a task
  Task _applyChanges(Task task, Map<String, dynamic> changes) {
    return task.copyWith(
      name: changes['name']?['new'] ?? task.name,
      description: changes['description']?['new'] ?? task.description,
      status: changes['status']?['new'] ?? task.status,
      priority: changes['priority']?['new'] ?? task.priority,
      dueDate:
          changes['dueDate']?['new'] != null
              ? DateTime.parse(changes['dueDate']['new'])
              : task.dueDate,
      dateCompleted:
          changes['completedAt']?['new'] != null
              ? DateTime.parse(changes['completedAt']['new'])
              : task.dateCompleted,
    );
  }

  Future<void> delete(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.delete(id);

      state.tasks.removeWhere((task) => task.id == id);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete task: $e',
        isLoading: false,
      );
    }
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
        isLoading: false,
      );
    }
  }

  /// Subscribe to a task
  void subscribeToTask(int taskId) {
    _client.subscribeToTask(taskId);
  }

  /// Unsubscribe from a task
  void unsubscribeFromTask(int taskId) {
    _client.unsubscribeFromTask(taskId);
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
      state = state.copyWith(selectedTask: null);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // @override
  // void dispose() {
  //   _client.dispose();
  //   super.dispose();
  // }
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
