import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/states/filtered_task_cache.dart';
import 'package:smooflow/notifiers/task_cache_notifier.dart';
import 'package:smooflow/states/task.dart';

/// 1. The Root Family Cache Provider
/// Governs the base notifier state instance tied to specific filter arguments.
final taskCacheProvider = NotifierProvider.family<
  TaskCacheNotifier,
  FilteredTaskCacheState,
  TaskFilter
>(() {
  return TaskCacheNotifier();
});

/// 2. Fine-grained Lane Task Selector Provider
/// Exposes a flat list of tasks for a single column/status lane.
/// Prevents column A from repainting when columns B or C receive updates.
final tasksByStatusProvider = Provider.family<
  List<Task>,
  ({TaskFilter filter, TaskStatus status})
>((ref, arg) {
  // Use select to deeply monitor ONLY this specific lane's map reference
  final statusMap = ref.watch(
    taskCacheProvider(
      arg.filter,
    ).select((state) => state.cachedTasks[arg.status]),
  );

  if (statusMap == null) return const [];

  // Convert the inner Map<int, Task> values to a list sorted by priority or ID
  final tasks = statusMap.values.toList();
  tasks.sort((a, b) => b.priority.compareTo(a.priority)); // High priority first
  return tasks;
});

/// 3. Fine-grained Count Selector Provider
/// Exposes the real-time aggregated integer count for a specific status and project.
/// Ideal for header column counter badges.
final taskCountProvider = Provider.family<
  int,
  ({TaskFilter filter, TaskStatus status, String projectId})
>((ref, arg) {
  return ref.watch(
    taskCacheProvider(
      arg.filter,
    ).select((state) => state.totalCounts[arg.status]?[arg.projectId] ?? 0),
  );
});

/// 4. Selected Task Selector Provider
/// Monitors the actively inspected task modal/panel workspace context.
final selectedTaskProvider = Provider.family<Task?, TaskFilter>((ref, filter) {
  return ref.watch(
    taskCacheProvider(filter).select((state) => state.selectedTask),
  );
});

/// 5. Global Loading State Selector Provider
final isCacheLoadingProvider = Provider.family<bool, TaskFilter>((ref, filter) {
  return ref.watch(
    taskCacheProvider(filter).select((state) => state.isLoadingCounts),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// WEBSOCKET PROVIDERS (integrated into taskCacheProvider)
// ─────────────────────────────────────────────────────────────────────────────

/// Connection status stream provider
final taskCacheConnectionStatusProvider = StreamProvider<ConnectionStatus>((
  ref,
) {
  final notifier = ref.watch(taskCacheProvider(TaskFilter.empty).notifier);
  // Create a stream from the TaskNotifier's connection status changes
  return Stream.periodic(
    Duration(milliseconds: 500),
    (_) => notifier.connectionStatus,
  );
});

class TaskCacheProvider {
  /// This is the main function to call when changing task state (progressing stage, assigning/unassigning printer, etc)
  /// This function assumes the task is already in the local state
  static Future<void> setTaskState({
    required WidgetRef ref,
    required int taskId,
    required TaskStatus newStatus,

    /// Pass null when unnassigning printer from task or when progressing task stage without needing to assign a printer (e.g. progressing to completed status)
    String? printerId,
    String? stockTransactionBarcode,
    String? materialId,
    int? stockOutQuantity,

    // Optional paramters
    bool isStageForward = true,
  }) async {
    if (printerId == null && newStatus == TaskStatus.printing) {
      throw "Printer ID must be provided when progressing task to printing status";
    }
    if (printerId != null &&
        (materialId == null ||
            stockTransactionBarcode == null ||
            stockOutQuantity == null)) {
      throw "Material ID and stock transaction barcode & stock out id must be provided when assigning printer to task for printing";
    }

    late final StockTransaction? stockOutTransaction;

    final task =
        ref.read(taskCacheProvider(TaskFilter.empty)).getLocalTask(taskId)!;

    if (printerId != null) {
      stockOutTransaction = await ref
          .watch(taskCacheProvider(TaskFilter.empty).notifier)
          .schedulePrint(
            task: task,
            printerId: printerId,
            materialId:
                materialId!, // This value is not used in the backend when progressing stage to printing, so we can just pass in a placeholder value here to satisfy the function parameter requirement
            productionQuantity:
                stockOutQuantity!, // This value is also not used in the backend when progressing stage to printing, so we can just pass in a placeholder value here to satisfy the function parameter requirement
            barcode: stockTransactionBarcode!,
          );
    } else {
      await ref
          .watch(taskCacheProvider(TaskFilter.empty).notifier)
          .progressStage(
            task: task,
            newStatus: newStatus,
            printerId: printerId,
            isStageForward: isStageForward,
          );
    }

    if (printerId != null) {
      ref
          .watch(printerNotifierProvider.notifier)
          .assignTask(printerId: printerId, taskId: taskId);
    } else {
      ref.watch(printerNotifierProvider.notifier).unassignTask(taskId: taskId);
    }

    // Commit stock out transaction
    if (stockTransactionBarcode != null) {
      print(
        "committing stock out transaction, barcode: ${stockTransactionBarcode}",
      );

      try {
        // stockTransactionBarcode != null implies that stockOutTransaction != null,
        // we will still catch for error anyways.
        ref
            .watch(materialNotifierProvider.notifier)
            .commitStockOutTransaction(
              stockOutTransaction: stockOutTransaction!,
            );
      } catch (e) {
        print("actual error: $e");
        throw "Commit stock out transaction requested but server did not return updated stock out transaction";
      }
    }
  }
}
