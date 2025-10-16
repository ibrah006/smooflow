import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_log.dart';
import '../repositories/material_log_repo.dart';

class MaterialLogNotifier extends StateNotifier<List<MaterialLog>> {
  final MaterialLogRepo _repo;

  MaterialLogNotifier(this._repo) : super([]);

  /// Load all material logs for a project (optionally delta-sync)
  Future<List<MaterialLog>> loadLogsByProject({
    required String projectId,
    bool forceReload = true,
    DateTime? lastLocalUpdate,
  }) async {
    try {
      final logs = await _repo.getMaterialLogsByProject(
        projectId: projectId,
        since: forceReload ? lastLocalUpdate : null,
      );

      if (logs.isEmpty) return state;

      // Remove any old logs with same IDs
      final updatedIds = logs.map((l) => l.id).toSet();
      final filtered = state.where((l) => !updatedIds.contains(l.id)).toList();

      // Merge updated logs
      state = [...filtered, ...logs];
      return logs;
    } catch (e) {
      print('Error loading material logs: $e');
      rethrow;
    }
  }

  /// Add a new MaterialLog and update the state
  Future<void> addMaterialLog(MaterialLog log) async {
    try {
      final newLog = await _repo.addMaterialLog(log);
      state = [...state, newLog];
    } catch (e) {
      print('Error adding material log (notifier): $e');
      rethrow;
    }
  }
}
