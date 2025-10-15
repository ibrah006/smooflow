import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/notifiers/work_activity_log_notifier.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/providers/user_provider.dart';
import 'package:smooflow/repositories/work_activity_log_repo.dart';

/// Repository provider — handles API calls for work activity logs
final workActivityLogRepoProvider = Provider<WorkActivityLogRepo>((ref) {
  return WorkActivityLogRepo();
});

/// Notifier provider — manages in-memory state of work activity logs
final workActivityLogNotifierProvider =
    StateNotifierProvider<WorkActivityLogNotifier, List<WorkActivityLog>>((
      ref,
    ) {
      final repo = ref.watch(workActivityLogRepoProvider);
      return WorkActivityLogNotifier(repo);
    });

final workActivityLogsByTaskProvider =
    Provider.family<Future<List<WorkActivityLog>>, int>((ref, taskId) async {
      final task = ref.watch(taskByIdProviderSimple(taskId));

      if (task == null) throw "Task not found";

      final updatedLogsUsers = await ref
          .watch(workActivityLogNotifierProvider.notifier)
          .loadTaskActivityLogs(
            taskId: taskId,
            taskActivityLogsLastModifiedLocal: task.activityLogLastModified,
            taskActivityLogIds: task.workActivityLogs,
          );

      if (updatedLogsUsers != null) {
        ref.watch(userNotifierProvider.notifier).updateUsers(updatedLogsUsers);
      }

      return ref.watch(workActivityLogNotifierProvider).where((log) {
        return log.taskId == taskId;
      }).toList();
    });

final workActivityLogsByTaskProviderSimple =
    Provider.family<List<WorkActivityLog>, int>((ref, taskId) {
      return ref.read(workActivityLogNotifierProvider).where((log) {
        return log.taskId == taskId;
      }).toList();
    });
