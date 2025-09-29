import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/notifiers/progress_log_notifier.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/repositories/progress_log_repo.dart';

final progressLogRepoProvider = Provider<ProgressLogRepo>((ref) {
  return ProgressLogRepo();
});

final progressLogNotifierProvider =
    StateNotifierProvider<ProgressLogNotifier, List<ProgressLog>>((ref) {
      final repo = ref.read(progressLogRepoProvider);
      return ProgressLogNotifier(repo);
    });

final progressLogsByProjectProvider =
    Provider.family<Future<List<ProgressLog>>, ProgressLogsByProviderArgs>((
      ref,
      args,
    ) async {
      final project = ref.watch(projectByIdProvider(args.projectId))!;

      return (ref
          .watch(progressLogNotifierProvider.notifier)
          .getLogsByProject(
            project,
            ensureLatestLogDetails: args.ensureLatestProgressLogData,
          ));
    });

final progressLogsByProjectProviderSimple =
    Provider.family<List<ProgressLog>, String>((ref, projectId) {
      return ref.watch(progressLogNotifierProvider).where((log) {
        return log.projectId == projectId;
      }).toList();
    });

class ProgressLogsByProviderArgs {
  String projectId;
  bool ensureLatestProgressLogData;
  ProgressLogsByProviderArgs(
    this.projectId, {
    this.ensureLatestProgressLogData = true,
  });
}
