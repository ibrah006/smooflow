import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/notifiers/task_notifier.dart';
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
final tasksByProjectProvider = Provider.family<Future<List<Task>>, String>((
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

final taskByIdProvider = Provider.family<Task?, int>((ref, taskId) {
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
