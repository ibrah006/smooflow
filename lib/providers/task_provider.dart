import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/notifiers/task_notifier.dart';
import 'package:smooflow/providers/project_provider.dart';
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
