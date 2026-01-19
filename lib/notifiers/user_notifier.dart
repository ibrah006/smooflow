import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/user.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/repositories/user_repo.dart';
import 'package:smooflow/core/services/login_service.dart';

// Beware of removing users from memory randomly
// To ensure there's isn't too many users in memory, we will need to remove som
// but in order to do that, we need to ensure their corresponding work-activity-lots associated with them are also removed
// If not work activity logs are associated with a user, they can be freely removed from memory

class UserNotifier extends StateNotifier<List<User>> {
  final UserRepo _repo;

  UserNotifier(this._repo) : super([LoginService.currentUser!]);

  updateUsers(List<User> users) {
    final List<User> temp = [...state, ...users].toSet().toList();

    state = temp;
  }

  /// Fetch all users (assignees) for a task.
  ///
  /// [task] - The task object to fetch assignees for.
  /// [forceReload] - If true, bypasses cache and fetches from server using `addedSince`.
  /// [assigneeIds] - List of assignee IDs already known to the frontend.
  ///
  /// Returns a list of up-to-date User objects.
  Future<List<User>> getTaskUsers({
    required Task task,
    bool forceReload = false,
  }) async {
    try {
      final DateTime? lastAddedAt = task.assigneeLastAdded;

      final bool allInMemory = task.assignees.every(
        (id) => state.any((user) => user.id == id),
      );

      // Determine if we must fetch from backend
      final bool mustFetch = forceReload || !allInMemory || lastAddedAt == null;

      if (!mustFetch) {
        // Return already loaded users
        return state.where((user) => task.assignees.contains(user.id)).toList();
      }

      final fetchedUsers = await _repo.getUsersByTask(
        taskId: task.id,
        addedSince: forceReload ? lastAddedAt : null,
      );

      // If new users were returned, merge them into state
      if (fetchedUsers.isNotEmpty) {
        // Remove duplicates and update
        final Map<String, User> merged = {
          for (var u in state) u.id: u,
          for (var u in fetchedUsers) u.id: u,
        };
        state = merged.values.toList();
      }

      return state.where((user) => task.assignees.contains(user.id)).toList();
    } catch (e) {
      print("❌ Error fetching users for task: $e");
      rethrow;
    }
  }
}
