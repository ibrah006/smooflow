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
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/states/filtered_task_cache.dart';
import 'package:smooflow/states/task.dart';

class TaskCacheNotifier
    extends FamilyNotifier<FilteredTaskCacheState, TaskFilter> {
  late final TaskRepo _repo;
  late final TaskWebSocketClient _client;

  Task? _activelyWorkingTask;
  bool _loading = false;

  bool get loading => _loading;
  Task? get activeTask => _activelyWorkingTask;
  ConnectionStatus get connectionStatus => state.connectionStatus;

  @override
  FilteredTaskCacheState build(TaskFilter arg) {
    // 1. Trigger the socket/listeners here.
    // `ref` and `_element` are completely initialized and safe to use at this point.
    _repo = ref.watch(taskRepoProvider);
    _client = ref.watch(taskWebSocketClientProvider);
    _initializeSocket();

    Future.microtask(() => fetchMetadataCounts());

    // 2. Return your initial state setup
    return const FilteredTaskCacheState.empty();
  }

  // final Ref ref;
  // TaskCacheNotifier() : super() {
  // _repo = ref.watch(taskRepoProvider);
  // _client = ref.watch(taskWebSocketClientProvider);
  //   _initializeSocket();
  // }

  bool mounted = true;

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

    final t =
        state.cachedTasks.values
            .expand((statusMap) => statusMap.values)
            .firstWhere((task) => task.id == taskId)
          ..workActivityLogs.add(workActivityLog.id)
          ..activityLogLastModified = DateTime.now()
          ..status = getTaskStartStatus;

    _activelyWorkingTask = t;

    if (_activelyWorkingTask == null)
      throw "Task to activate not found in memory, unexpected exception";

    state = state;

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

      state.cachedTasks.update(_activelyWorkingTask!.status, (statusMap) {
        statusMap[_activelyWorkingTask!.id] = _activelyWorkingTask!;
        return statusMap;
      });

      state = state;
    }

    _activelyWorkingTask = null;
  }

  /// Assumes the task is already in memory
  Future<void> _assignPrinter({
    required Task task,
    required String printerId,
  }) async {
    await _repo.assignPrinter(task.id, printerId);

    try {
      state.cachedTasks[task.status]?.update(task.id, (t) {
        return t
          ..printerId = printerId
          ..status = TaskStatus.printing;
      });
    } catch (e) {
      // Task status changed fallback
      final taskStatus = state.getLocalTaskStatus(task.id);

      state.cachedTasks[taskStatus]?.update(task.id, (t) {
        return t
          ..printerId = printerId
          ..status = TaskStatus.printing;
      });
    }
    state = state;
  }

  /// Assumes the task is already in memory
  Future<void> _unassignPrinter({
    required Task task,
    required TaskStatus status,
  }) async {
    await _repo.unassignPrinter(task.id, status);

    try {
      state.cachedTasks[task.status]?.update(task.id, (t) {
        return t
          ..printerId = null
          ..status = status;
      });
    } catch (e) {
      // Task status changed fallback
      final taskStatus = state.getLocalTaskStatus(task.id);

      state.cachedTasks[taskStatus]?.update(task.id, (t) {
        return t
          ..printerId = null
          ..status = status;
      });
    }

    state = state;
  }

  Future<Task?> getTaskById(int taskId) async {
    try {
      final t = state.getLocalTask(taskId);
      if (t != null) return t;

      // 1. Fetch the absolute fresh entity from your database repository
      final fetchedTask = await _repo.getTaskById(taskId: taskId);
      if (fetchedTask == null) return null;

      // 2. Clone the nested collections using map structures to maintain strict immutability rules
      final updatedCachedTasks = state.cachedTasks.map((status, indexMap) {
        return MapEntry(status, Map<int, Task>.from(indexMap));
      });

      final updatedTotalCounts = state.totalCounts.map((status, filterMap) {
        return MapEntry(status, Map<String, int>.from(filterMap));
      });

      // Ensure our targets are initialized inside the copies
      updatedCachedTasks.putIfAbsent(fetchedTask.status, () => {});
      updatedTotalCounts.putIfAbsent(fetchedTask.status, () => {});

      TaskStatus? detectedOldStatus;
      int? detectedOldIndex;

      // 3. Scan the index matrix across all status blocks to check if the item is warm in memory
      for (final statusEntry in state.cachedTasks.entries) {
        final status = statusEntry.key;
        final indexMap = statusEntry.value;

        for (final indexEntry in indexMap.entries) {
          if (indexEntry.value.id == taskId) {
            detectedOldStatus = status;
            detectedOldIndex = indexEntry.key;
            break;
          }
        }
        if (detectedOldIndex != null) break;
      }

      bool stateDidMutate = false;

      if (detectedOldIndex != null && detectedOldStatus != null) {
        if (detectedOldStatus == fetchedTask.status) {
          // SCENARIO 1: Warm Update (In-place swap)
          // Completely idempotent. Overwrite the exact integer slot position.
          updatedCachedTasks[detectedOldStatus]?[detectedOldIndex] =
              fetchedTask;
          stateDidMutate = true;
        } else {
          // SCENARIO 2: Column Move / Structural Status Shift
          // The task changed columns. This modifies database row sequencing for both states.
          // Purge memory ranges for both target columns to protect scroll alignment.
          updatedCachedTasks[detectedOldStatus] = {};
          updatedCachedTasks[fetchedTask.status] = {};

          // Invalidate structural metric counts to force real-time window recalculation
          updatedTotalCounts[detectedOldStatus] = {};
          updatedTotalCounts[fetchedTask.status] = {};

          stateDidMutate = true;
        }
      } else {
        // SCENARIO 3: Cold Fetch
        // The task isn't tracked in any current viewport windows.
        // Do NOT insert at an arbitrary key position. Let the lazy scroll load it naturally later.
      }

      // 4. Update the notifier state if a structural layout mutation occurred
      if (stateDidMutate) {
        state = state.copyWith(
          cachedTasks: updatedCachedTasks,
          totalCounts: updatedTotalCounts,
        );
      }

      // Always return the fresh dataset so detailing components can absorb updates instantly
      return fetchedTask;
    } catch (e, st) {
      print('Error loading task by ID: $e\n$st');
      rethrow;
    }
  }

  Future<void> progressStage({
    required Task task,
    required TaskStatus newStatus,
    String? printerId,
    bool isStageForward = true,
  }) async {
    if (printerId == null && newStatus == TaskStatus.printing) {
      throw "Printer ID must be provided when progressing task to printing status";
    }

    final taskId = task.id;

    await _repo.progressStage(
      taskId,
      newStatus,
      isStageForward: isStageForward,
    );

    if (newStatus == TaskStatus.printing) {
      await _assignPrinter(task: task, printerId: printerId!);

      print("$taskId to printing status and assigned printer $printerId");
    } else {
      try {
        if (task.printerId != null && printerId == null) {
          await _unassignPrinter(task: task, status: newStatus);
          print(
            "Progressed task $taskId to $newStatus status and unassigned printer",
          );
        }
      } catch (e) {}
    }

    try {
      state.cachedTasks.update(task.status, (statusMap) {
        statusMap[taskId] = task..status = newStatus;
        return statusMap;
      });

      state = state;
    } catch (e) {
      print(
        "Error updating task status in memory after progressing stage\nFetching task from database to update in-memory state",
      );
      await getTaskById(taskId);
    }
  }

  // Returns stock out transaction, if committed
  Future<StockTransaction?> schedulePrint({
    required Task task,
    required String printerId,
    required String materialId,
    String progressStage = 'production',
    int runs = 1,
    required int productionQuantity,
    required String barcode,
  }) async {
    final stockOutTransaction = await _repo.schedulePrint(
      taskId: task.id,
      printerId: printerId,
      materialId: materialId,
      progressStage: progressStage,
      runs: runs,
      productionQuantity: productionQuantity,
      barcode: barcode,
    );

    state.cachedTasks.update(task.status, (tasks) {
      tasks[task.id]!
        ..printerId = printerId
        ..status = TaskStatus.printing
        ..materialId = materialId
        ..actualProductionStartTime = DateTime.now()
        ..runs = runs
        ..productionQuantity = productionQuantity.toDouble()
        // ..stockTransactionBarcode = barcode
        ..stockTransactionIds.add(stockOutTransaction!.id);

      return tasks;
    });

    state = state;

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
    try {
      // Checking to see if task exists in memory
      // If not - throws an error
      state.cachedTasks.values
          .expand((statusMap) => statusMap.values)
          .firstWhere((task) => task.id == taskId);

      final lastMessageForTask = ref
          .read(messageNotifierProvider)
          .lastMessageForTask(taskId);

      if (lastMessageForTask == null) {
        // No messages for this task loaded in memory, so need to update read status
        return null;
      }

      // Update local state first
      state
          .cachedTasks
          .values
          .expand((statusMap) => statusMap.values)
          .firstWhere((task) => task.id == taskId)
          .unreadCount = 0;

      state = state;

      await _repo.updateMessageReadStatus(
        taskId: taskId,
        lastSeenMessageId: lastMessageForTask.id,
      );
    } catch (e) {
      // No unread messages, no need to call the API
      return;
    }
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
    _client.taskChanges.listen((event) => _handleTaskChange(event));

    /// Listen to task list updates
    /// Suspended for now
    // _client.taskList.listen((tasks) {
    //   if (mounted) {
    //     // state = state.copyWith(tasks: tasks, isLoading: false, error: null);
    //   }
    // });

    // Listen to errors
    _client.errors.listen((error) {
      if (mounted) {
        state = state.copyWith(error: error, isLoadingCounts: false);
      }
    });
  }

  /// Handle task change events from WebSocket
  void _handleTaskChange(TaskChangeEvent event) {
    print(
      '[TaskNotifier] _handleTaskChange: ${event.type}, taskId: ${event.taskId}, mounted: $mounted',
    );

    if (!mounted) {
      print('[TaskNotifier] Notifier not mounted, ignoring change');
      return;
    }

    // 0. PROJECT ISOLATION GUARD
    // If this notifier is filtered to a specific project, smoothly ignore events from other projects
    final String targetProjectId = event.task!.projectId;
    // REMOVED project isolation guard because the event.task.projectId metadata doesn't mean the task is filtered in our implementations

    // Deep copy maps to ensure strict Riverpod immutability rules and trigger UI repaints
    final updatedCachedTasks = state.cachedTasks.map((status, idMap) {
      return MapEntry(status, Map<int, Task>.from(idMap));
    });

    final updatedTotalCounts = state.totalCounts.map((status, projMap) {
      return MapEntry(
        status,
        Map<String, int>.from(projMap),
      ); // ✅ FIXED: inner map typed to String project ID
    });

    // Highly optimized O(1) key check per status lane to see if the task is actively loaded in memory
    TaskStatus? detectedOldStatus;
    for (final entry in state.cachedTasks.entries) {
      if (entry.value.containsKey(event.taskId)) {
        detectedOldStatus = entry.key;
        break;
      }
    }

    bool stateDidMutate = false;
    Task? nextSelectedTask = state.selectedTask;

    // ✅ FIXED: String projectId mapping tracker with clamp protection to prevent integer underflows
    void modifyCount(TaskStatus status, String projectId, int delta) {
      updatedTotalCounts.putIfAbsent(status, () => {});
      final currentCount = updatedTotalCounts[status]![projectId] ?? 0;
      updatedTotalCounts[status]![projectId] = (currentCount + delta).clamp(
        0,
        999999,
      );
    }

    switch (event.type) {
      case TaskChangeType.created:
        // RULE B: New Task Created -> Adjust Counters & Purge Column
        if (event.task != null && detectedOldStatus == null) {
          final targetStatus = event.task!.status;

          modifyCount(targetStatus, targetProjectId, 1);

          // Clear active status lane completely so infinite scroller pulls fresh realigned payload bounds
          updatedCachedTasks[targetStatus] = {};
          stateDidMutate = true;
          print(
            '[TaskNotifier] Task created. Count bumped. Evicted $targetStatus lane.',
          );
        }

        if (event.task != null) {
          ref.read(projectByIdProvider(event.task!.projectId))!.tasksCount++;
        }
        break;

      case TaskChangeType.updated:
      case TaskChangeType.statusChanged:
      case TaskChangeType.assigneeAdded:
      case TaskChangeType.assigneeRemoved:
      case TaskChangeType.nameUpdated:
        // RULE A: Updates are Sparse Mutations. If NOT found in memory, discard the payload.
        if (detectedOldStatus != null) {
          final currentMemoryTask =
              updatedCachedTasks[detectedOldStatus]![event.taskId]!;

          // Re-assemble the new task data object
          final newTaskData =
              event.task != null
                  ? event.task!
                  : _applyChanges(currentMemoryTask, event.changes ?? {});

          if (detectedOldStatus == newTaskData.status) {
            // SCENARIO 1: Status Unchanged (Warm Update)
            // Perfectly idempotent in-place map overwrite via ID key conversion
            updatedCachedTasks[detectedOldStatus]![event.taskId!] = newTaskData;
            stateDidMutate = true;
            print(
              '[TaskNotifier] Idempotent in-place ID update completed for task ${event.taskId}',
            );
          } else {
            // SCENARIO 2: Column Move / Structural Status Shift (RULE B & Idempotency Race Solver)
            // Recalculate bounds cleanly across both targets to avoid visual duplicated line fragments
            modifyCount(detectedOldStatus, targetProjectId, -1);
            modifyCount(newTaskData.status, targetProjectId, 1);

            // Wipe out both lanes entirely so infinite viewports sync atomic alignments cleanly
            updatedCachedTasks[detectedOldStatus] = {};
            updatedCachedTasks[newTaskData.status] = {};
            stateDidMutate = true;
            print(
              '[TaskNotifier] Status sync mismatch solved. Evicted lanes: $detectedOldStatus -> ${newTaskData.status}',
            );
          }

          // Sync active viewing modal reference if this is the chosen node
          if (state.selectedTask?.id == event.taskId) {
            nextSelectedTask = newTaskData;
            stateDidMutate = true;
          }
        } else {
          print(
            '[TaskNotifier] Task ${event.taskId} resides in an unrendered dead region. Discarding payload.',
          );
        }

        // Side-effects not related to list memory (Metrics / Selected Task)
        if (event.changes?["status"] != null &&
            event.task?.status == TaskStatus.completed) {
          ref
              .read(projectByIdProvider(event.task!.projectId))!
              .completedTasksCount++;
        } else if (event.changes?["newPrintSpec"] != null &&
            event.task != null) {
          state.initializeCurrentlyCreatingSpec(
            event.task!.id,
            event.changes!["newPrintSpec"]["tempLocalId"],
            event.changes!["newPrintSpec"]["id"],
          );
          stateDidMutate = true;
        }
        break;

      case TaskChangeType.deleted:
        // RULE A: Deletions are Sparse Mutations. Only act if tracked in memory.
        if (detectedOldStatus != null) {
          // RULE B: Adjust Total Counters Immediately & Evict Cache Column
          modifyCount(detectedOldStatus, targetProjectId, -1);

          // Deletions shift underlying records. Purge lane to let scroller fetch new clean offsets.
          updatedCachedTasks[detectedOldStatus] = {};
          stateDidMutate = true;
          print(
            '[TaskNotifier] Task deleted. Count reduced. Evicted $detectedOldStatus lane.',
          );
        }

        if (state.selectedTask?.id == event.taskId) {
          nextSelectedTask = null;
          stateDidMutate = true;
        }

        if (event.task != null) {
          ref.read(projectByIdProvider(event.task!.projectId))!.tasksCount--;
        }
        break;

      case TaskChangeType.newProject:
        print("new project event, ${event.project!.name}");
        ref
            .read(projectNotifierProvider.notifier)
            .loadProjectToMemory(event.project!);
        break;

      case TaskChangeType.deleteProject:
        print("delete project event, ${event.project!.name}");
        ref
            .read(projectNotifierProvider.notifier)
            .deleteProject(event.project!.id);
        break;
    }

    if (stateDidMutate) {
      state = state.copyWith(
        cachedTasks: updatedCachedTasks,
        totalCounts: updatedTotalCounts,
        selectedTask: nextSelectedTask,
      );
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
    state = state.copyWith(isLoadingCounts: true, error: null);
    try {
      await _repo.delete(id);

      // Remove task from state
      state.cachedTasks.forEach((status, tasks) {
        if (tasks.remove(id) != null) {
          return;
        }
      });

      state = state.copyWith(isLoadingCounts: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete task: $e',
        isLoadingCounts: false,
      );
    }
  }

  /// Load a specific task
  Future<void> loadTask(int taskId) async {
    state = state.copyWith(isLoadingCounts: true, error: null);
    try {
      _client.subscribeToTask(taskId);
      _client.getTask(taskId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load task: $e',
        isLoadingCounts: false,
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
