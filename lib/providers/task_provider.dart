import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/enums/billing_status.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/notifiers/task_notifier.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/work_activity_log_providers.dart';
import 'package:smooflow/core/repositories/task_repo.dart';
import 'package:smooflow/states/task.dart';

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

@Deprecated("Use TaskProvider.setTaskState instead")
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
      ref.watch(materialNotifierProvider.notifier).commitStockOutTransaction(transactionBarcode: taskStateParams.stockTransactionBarcode!);
    }
  } else {
    await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: taskStateParams.id, newStatus: taskStateParams.newTaskStatus);
    ref.watch(printerNotifierProvider.notifier).unassignTask(taskId: taskStateParams.id);
  }
});

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
  }) async {
    if (printerId == null && newStatus == TaskStatus.printing) {
      throw "Printer ID must be provided when progressing task to printing status";
    }
    if (printerId != null && (materialId == null || stockTransactionBarcode == null)) {
      throw "Material ID and stock transaction barcode must be provided when assigning printer to task for printing";
    }

    if (printerId != null) {
      await ref.watch(taskNotifierProvider.notifier).schedulePrint(
        taskId: taskId,
        printerId: printerId,
        materialId: materialId!, // This value is not used in the backend when progressing stage to printing, so we can just pass in a placeholder value here to satisfy the function parameter requirement
        productionQuantity: 1, // This value is also not used in the backend when progressing stage to printing, so we can just pass in a placeholder value here to satisfy the function parameter requirement
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
    if (stockTransactionBarcode != null){
      ref.watch(materialNotifierProvider.notifier).commitStockOutTransaction(transactionBarcode: stockTransactionBarcode);
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