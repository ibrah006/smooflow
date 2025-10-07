import 'package:flutter_riverpod/flutter_riverpod.dart';
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
