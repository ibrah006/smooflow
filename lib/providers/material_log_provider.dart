import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/material_log_repo.dart';
import '../notifiers/material_log_notifier.dart';
import '../core/models/material_log.dart';

final materialLogRepoProvider = Provider<MaterialLogRepo>((ref) {
  return MaterialLogRepo();
});

final materialLogNotifierProvider =
    StateNotifierProvider<MaterialLogNotifier, List<MaterialLog>>((ref) {
      final repo = ref.read(materialLogRepoProvider);
      return MaterialLogNotifier(repo);
    });
