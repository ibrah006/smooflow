import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/notifiers/task_notifier.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/work_activity_log_providers.dart';
import 'package:smooflow/repositories/task_repo.dart';

final taskRepoProvider = Provider<TaskRepo>((ref) => TaskRepo());

final taskNotifierProvider = StateNotifierProvider<TaskNotifier, List<Task>>((
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
  final tasks = ref.watch(taskNotifierProvider);
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


final setPrinterStateProvider = Provider.family<Future<void>, TaskPrinterStateParams>((
  ref,
  taskPrinterStateParams,
) async {
  // Assign/Unassign printer to task
  if (taskPrinterStateParams.printerId != null) {
    await ref.watch(taskNotifierProvider.notifier).assignPrinter(taskId: taskPrinterStateParams.id, printerId: taskPrinterStateParams.printerId!);
    ref.watch(printerNotifierProvider.notifier).assignTask(printerId: taskPrinterStateParams.printerId!, taskId: taskPrinterStateParams.id);

    // Commit stock out transaction
    if (taskPrinterStateParams.stockTransactionBarcode!=null){
      ref.watch(materialNotifierProvider.notifier).commitStockOutTransaction(transactionBarcode: taskPrinterStateParams.stockTransactionBarcode!);
    }

  } else {
    await ref.watch(taskNotifierProvider.notifier).unassignPrinter(taskId: taskPrinterStateParams.id, status: taskPrinterStateParams.newTaskStatus);
    ref.watch(printerNotifierProvider.notifier).unassignTask(printerId: taskPrinterStateParams.printerId!);
  }
});


class TaskPrinterStateParams {
  final int id;
  final String? printerId;
  final String? stockTransactionBarcode;
  final TaskStatus newTaskStatus;

  const TaskPrinterStateParams({required this.id, required this.printerId, required this.stockTransactionBarcode, required this.newTaskStatus});
}