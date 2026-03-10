import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/notifiers/task_notifier.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/work_activity_log_providers.dart';
import 'package:smooflow/core/repositories/task_repo.dart';
import 'package:smooflow/states/task.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EXISTING PROVIDERS (kept for backward compatibility)
// ─────────────────────────────────────────────────────────────────────────────

final taskRepoProvider = Provider<TaskRepo>((ref) => TaskRepo());

final taskNotifierProvider = StateNotifierProvider<TaskNotifier, TaskState>((
  ref,
) {
  final repo = ref.watch(taskRepoProvider);
  return TaskNotifier(repo);
});

/// pass in projectId as input
@Deprecated(
  "Just do the same from the same component/screen widget you want this functionality/access",
)
final tasksByProjectProvider = Provider.family<Future<TasksResponse>, String>((
  ref,
  projectId,
) async {
  final project = ref.watch(projectByIdProvider(projectId));

  if (project == null) throw "Project not found";

  return await ref
      .watch(taskNotifierProvider.notifier)
      .loadProjectTasks(
        projectId: projectId,
        projectTasksLastModifiedLocal: project.progressLogLastModifiedAt,
        projectTaskIds: project.tasks,
      );
});

// This ensures we get an instance of task with the latest info
final taskByIdProvider = Provider.family<Future<Task?>, int>((
  ref,
  taskId,
) async {
  // TODO: Ensure latest task and its relations from database

  return await ref
      .watch(taskNotifierProvider.notifier)
      .getTaskById(taskId, forceReload: true);
});

// When calling this, make sure the task is already loaded in memory
@Deprecated(
  "taskByIdProviderSimple (-> Task) is deprecated and will be completely replaced by taskByIdProvider (-> Future<Task?>) in future commits",
)
final taskByIdProviderSimple = Provider.family<Task?, int>((ref, taskId) {
  final tasks = ref.watch(taskNotifierProvider).tasks;
  try {
    return tasks.firstWhere((task) => task.id == taskId);
  } catch (e) {
    return null;
  }
});

final createTaskActivityLogProvider = Provider.family<Future<void>, int>((
  ref,
  taskId,
) async {
  // Update task status
  final workActivityLog = await ref
      .read(taskNotifierProvider.notifier)
      .startTask(taskId);

  // Add Work activity log
  await ref
      .read(workActivityLogNotifierProvider.notifier)
      .startWorkSession(taskId: taskId, newLogId: workActivityLog.id);
});

/// ----- DEPRECATED, DO NOT USE -----
@Deprecated("DEPRECATED, DO NOT USE. Use TaskProvider.setTaskState instead")
final setTaskStateProvider = Provider.family<Future<void>, TaskStateParams>((
  ref,
  taskStateParams,
) async {
  // Assign/Unassign printer to task
  if (taskStateParams.printerId != null) {
    print("about to start print job\nassigning printer");
    await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: taskStateParams.id, newStatus: taskStateParams.newTaskStatus, printerId: taskStateParams.printerId!);
    ref.watch(printerNotifierProvider.notifier).assignTask(printerId: taskStateParams.printerId!, taskId: taskStateParams.id);

    // Commit stock out transaction
    if (taskStateParams.stockTransactionBarcode!=null){
      // ref.watch(materialNotifierProvider.notifier).commitStockOutTransaction(transactionBarcode: taskStateParams.stockTransactionBarcode!);
    }
  } else {
    await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: taskStateParams.id, newStatus: taskStateParams.newTaskStatus);
    ref.watch(printerNotifierProvider.notifier).unassignTask(taskId: taskStateParams.id);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// WEBSOCKET PROVIDERS (new real-time functionality)
// ─────────────────────────────────────────────────────────────────────────────

/// WebSocket client provider
final taskWebSocketClientProvider = Provider<TaskWebSocketClient>((ref) {
  // Get auth token from your auth provider
  final authToken = ref.watch(authTokenProvider);
  
  final client = TaskWebSocketClient(
    authToken: authToken,
  );

  client.connect();

  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

/// Connection status stream provider
final taskConnectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final client = ref.watch(taskWebSocketClientProvider);
  return client.connectionStatus;
});

/// Task changes stream provider
final taskChangesStreamProvider = StreamProvider<TaskChangeEvent>((ref) {
  final client = ref.watch(taskWebSocketClientProvider);
  return client.taskChanges;
});

/// Task list state notifier (real-time WebSocket integration)
final taskListProvider = StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final client = ref.watch(taskWebSocketClientProvider);
  return TaskListNotifier(client, ref);
});

/// Selected task provider
final selectedTaskProvider = StateProvider<Task?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// STATE CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class TaskListState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final ConnectionStatus connectionStatus;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.connectionStatus = ConnectionStatus.disconnected,
  });

  TaskListState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    ConnectionStatus? connectionStatus,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskWebSocketClient _client;
  final Ref _ref;

  TaskListNotifier(this._client, this._ref) : super(const TaskListState()) {
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
    _client.taskChanges.listen(_handleTaskChange);

    // Listen to task list
    _client.taskList.listen((tasks) {
      if (mounted) {
        state = state.copyWith(
          tasks: tasks,
          isLoading: false,
          error: null,
        );
      }
    });

    // Listen to errors
    _client.errors.listen((error) {
      if (mounted) {
        state = state.copyWith(
          error: error,
          isLoading: false,
        );
      }
    });
  }

  void _handleTaskChange(TaskChangeEvent event) {
    if (!mounted) return;

    final tasks = List<Task>.from(state.tasks);

    switch (event.type) {
      case TaskChangeType.created:
        if (event.task != null && !tasks.any((t) => t.id == event.taskId)) {
          tasks.insert(0, event.task!);
          state = state.copyWith(tasks: tasks);
        }
        break;

      case TaskChangeType.updated:
      case TaskChangeType.statusChanged:
        final index = tasks.indexWhere((t) => t.id == event.taskId);
        if (index != -1) {
          if (event.task != null) {
            tasks[index] = event.task!;
          } else if (event.changes != null) {
            // Partial update
            tasks[index] = _applyChanges(tasks[index], event.changes!);
          }
          state = state.copyWith(tasks: tasks);
        }

        // Update selected task if it's the one that changed
        final selectedTask = _ref.read(selectedTaskProvider);
        if (selectedTask?.id == event.taskId && event.task != null) {
          _ref.read(selectedTaskProvider.notifier).state = event.task;
        }
        break;

      case TaskChangeType.deleted:
        tasks.removeWhere((t) => t.id == event.taskId);
        state = state.copyWith(tasks: tasks);

        // Clear selected task if it was deleted
        final selectedTask = _ref.read(selectedTaskProvider);
        if (selectedTask?.id == event.taskId) {
          _ref.read(selectedTaskProvider.notifier).state = null;
        }
        break;

      case TaskChangeType.assigneeAdded:
      case TaskChangeType.assigneeRemoved:
        // Handle assignee changes if needed
        final index = tasks.indexWhere((t) => t.id == event.taskId);
        if (index != -1 && event.task != null) {
          tasks[index] = event.task!;
          state = state.copyWith(tasks: tasks);
        }
        break;
    }
  }

  /// Apply partial changes to a task
  Task _applyChanges(Task task, Map<String, dynamic> changes) {
    return task.copyWith(
      name: changes['name']?['new'] ?? task.name,
      description: changes['description']?['new'] ?? task.description,
      status: changes['status']?['new'] ?? task.status,
      priority: changes['priority']?['new'] ?? task.priority,
      dueDate: changes['dueDate']?['new'] != null 
          ? DateTime.parse(changes['dueDate']['new']) 
          : task.dueDate,
      dateCompleted: changes['completedAt']?['new'] != null 
          ? DateTime.parse(changes['completedAt']['new']) 
          : task.dateCompleted,
    );
  }

  /// Load all tasks
  Future<void> loadTasks({Map<String, dynamic>? filters}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _client.listTasks(filters: filters);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load tasks: $e',
        isLoading: false,
      );
    }
  }

  /// Refresh tasks
  Future<void> refreshTasks() async {
    state = state.copyWith(isLoading: true);
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

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPUTED PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Tasks by status provider
final tasksByStatusProvider = Provider.family<List<Task>, String>((ref, status) {
  final state = ref.watch(taskListProvider);
  return state.tasks.where((t) => t.status == status).toList();
});

/// Tasks by project provider
// final tasksByProjectProvider = Provider.family<List<Task>, int>((ref, projectId) {
//   final state = ref.watch(taskListProvider);
//   return state.tasks.where((t) => t.projectId == projectId).toList();
// });

/// Pending tasks provider
final pendingTasksProvider = Provider<List<Task>>((ref) {
  final state = ref.watch(taskListProvider);
  return state.tasks.where((t) => t.status == 'pending').toList();
});

/// In progress tasks provider
final inProgressTasksProvider = Provider<List<Task>>((ref) {
  final state = ref.watch(taskListProvider);
  return state.tasks.where((t) => t.status == 'in_progress' || t.status == 'inProgress').toList();
});

/// Delivery tasks provider (for delivery dashboard)
final deliveryTasksProvider = Provider<List<Task>>((ref) {
  final state = ref.watch(taskListProvider);
  return state.tasks.where((t) => t.status == 'delivery').toList();
});

/// Completed tasks provider
final completedTasksProvider = Provider<List<Task>>((ref) {
  final state = ref.watch(taskListProvider);
  return state.tasks.where((t) => t.status == 'completed').toList();
});

/// Overdue tasks provider
final overdueTasksProvider = Provider<List<Task>>((ref) {
  final state = ref.watch(taskListProvider);
  final now = DateTime.now();
  return state.tasks.where((t) {
    return t.dueDate != null && 
           t.dueDate!.isBefore(now) && 
           t.status != 'completed';
  }).toList();
});

/// High priority tasks provider
final highPriorityTasksProvider = Provider<List<Task>>((ref) {
  final state = ref.watch(taskListProvider);
  return state.tasks.where((t) => t.priority.index >= 3).toList();
});

/// Search tasks provider
final searchTasksProvider = Provider.family<List<Task>, String>((ref, query) {
  final state = ref.watch(taskListProvider);
  if (query.isEmpty) return state.tasks;

  final lowerQuery = query.toLowerCase();
  return state.tasks.where((task) {
    return task.name.toLowerCase().contains(lowerQuery) ||
           (task.description.toLowerCase().contains(lowerQuery));
  }).toList();
});

/// Task statistics provider
final taskStatsProvider = Provider<TaskStats>((ref) {
  final state = ref.watch(taskListProvider);
  return TaskStats(
    total: state.tasks.length,
    pending: state.tasks.where((t) => t.status == 'pending').length,
    inProgress: state.tasks.where((t) => t.status == 'in_progress' || t.status == 'inProgress').length,
    delivery: state.tasks.where((t) => t.status == 'delivery').length,
    completed: state.tasks.where((t) => t.status == 'completed').length,
    overdue: state.tasks.where((t) {
      return t.dueDate != null && 
             t.dueDate!.isBefore(DateTime.now()) && 
             t.status != 'completed';
    }).length,
    highPriority: state.tasks.where((t) => t.priority.index >= 3).length,
  );
});

class TaskStats {
  final int total;
  final int pending;
  final int inProgress;
  final int delivery;
  final int completed;
  final int overdue;
  final int highPriority;

  const TaskStats({
    required this.total,
    required this.pending,
    required this.inProgress,
    required this.delivery,
    required this.completed,
    required this.overdue,
    required this.highPriority,
  });
}

/// Replace with your actual auth token provider
final authTokenProvider = Provider<String>((ref) {
  return 'your-jwt-token';
});

// ─────────────────────────────────────────────────────────────────────────────
// EXISTING TASKPROVIDER CLASS (retained for backward compatibility)
// ─────────────────────────────────────────────────────────────────────────────

class TaskProvider {
  /// This is the main function to call when changing task state (progressing stage, assigning/unassigning printer, etc)
  static Future<void> setTaskState({
    required WidgetRef ref,
    required int taskId,
    required TaskStatus newStatus,
    /// Pass null when unnassigning printer from task or when progressing task stage without needing to assign a printer (e.g. progressing to completed status)
    String? printerId,
    String? stockTransactionBarcode,
    String? materialId,
    int? stockOutQuantity
  }) async {
    if (printerId == null && newStatus == TaskStatus.printing) {
      throw "Printer ID must be provided when progressing task to printing status";
    }
    if (printerId != null && (materialId == null || stockTransactionBarcode == null || stockOutQuantity == null)) {
      throw "Material ID and stock transaction barcode & stock out id must be provided when assigning printer to task for printing";
    }

    late final StockTransaction? stockOutTransaction;

    if (printerId != null) {
      stockOutTransaction = await ref.watch(taskNotifierProvider.notifier).schedulePrint(
        taskId: taskId,
        printerId: printerId,
        materialId: materialId!, // This value is not used in the backend when progressing stage to printing, so we can just pass in a placeholder value here to satisfy the function parameter requirement
        productionQuantity: stockOutQuantity!, // This value is also not used in the backend when progressing stage to printing, so we can just pass in a placeholder value here to satisfy the function parameter requirement
        barcode: stockTransactionBarcode!
      );
    } else {
      await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: taskId, newStatus: newStatus, printerId: printerId);
    }

    if (printerId != null) {
      ref.watch(printerNotifierProvider.notifier).assignTask(printerId: printerId, taskId: taskId);
    } else {
      ref.watch(printerNotifierProvider.notifier).unassignTask(taskId: taskId);
    }

    // Commit stock out transaction
    if (stockTransactionBarcode != null) {
      print("committing stock out transaction, barcode: ${stockTransactionBarcode}");

      try {
        // stockTransactionBarcode != null implies that stockOutTransaction != null,
        // we will still catch for error anyways.
        ref.watch(materialNotifierProvider.notifier).commitStockOutTransaction(
          stockOutTransaction: stockOutTransaction!
        );
      } catch(e) {
        print("actual error: $e");
        throw "Commit stock out transaction requested but server did not return updated stock out transaction";
      }
    }
  }
}

class TaskStateParams {
  final int id;
  /// Pass in null to unassign printer from task
  final String? printerId;
  final String? stockTransactionBarcode;
  final TaskStatus newTaskStatus;

  const TaskStateParams({required this.id, required this.printerId, required this.stockTransactionBarcode, required this.newTaskStatus});
}