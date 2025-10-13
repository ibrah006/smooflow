import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/notifiers/task_notifier.dart';
import 'package:smooflow/repositories/task_repo.dart';

final taskRepoProvider = Provider<TaskRepo>((ref) => TaskRepo());

final taskNotifierProvider = StateNotifierProvider<TaskNotifier, List<Task>>((
  ref,
) {
  final repo = ref.watch(taskRepoProvider);
  return TaskNotifier(repo);
});

/// pass in projectId as input
final tasksByProjectProvider = Provider.family<Future<List<Task>>, Project>((
  ref,
  project,
) async {
  return await ref
      .watch(taskNotifierProvider.notifier)
      .loadProjectTasks(
        projectId: project.id,
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
