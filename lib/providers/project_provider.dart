import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/notifiers/project_notifier.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/repositories/project_repo.dart';

final projectRepoProvider = Provider<ProjectRepo>((ref) {
  return ProjectRepo();
});

final projectNotifierProvider =
    StateNotifierProvider<ProjectNotifier, List<Project>>((ref) {
      final repo = ref.read(projectRepoProvider);
      return ProjectNotifier(repo);
    });

final projectByIdProvider = Provider.family<Project?, String>((ref, id) {
  final projects = ref.watch(projectNotifierProvider);
  try {
    return projects.firstWhere(
      (project) => project.id == id,
      // orElse: () => null,
    );
  } catch (e) {
    return null;
  }
});

// It has a placeholder value, it gets overridden in the project screen
final currentProjectProvider = Provider<Project>((ref) {
  throw UnimplementedError('Override this in your screen.');
});

final createProjectTaskProvider = Provider.family<Future<void>, Task>((
  ref,
  task,
) async {
  await ref.watch(projectNotifierProvider.notifier).createTask(task: task);

  ref.watch(taskNotifierProvider.notifier).loadTaskToMemory(task);
});
