import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/states/filtered_task_cache.dart';
import 'package:smooflow/notifiers/task_cache_notifier.dart';
import 'package:smooflow/states/task.dart'; // Adjust import paths

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
