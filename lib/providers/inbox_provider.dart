import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/task_activity.dart';
import 'package:smooflow/core/repositories/activity_repo.dart';
import 'package:smooflow/data/inbox_item.dart';
import 'package:smooflow/states/message.dart';
import 'package:smooflow/utils/mergeByObjectId.dart';

class InboxNotifier extends StateNotifier<InboxState> {
  final ActivityRepo _repo;
  final Ref _ref;

  InboxNotifier(this._repo, this._ref) : super(InboxState());

  /// Fetch inbox items (activities + recent messages merged)
  Future<void> fetchRecentInbox({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final offset = refresh ? 0 : state.items.length;

      // Fetch activities
      final activitiesResponse = await _repo.fetchRecentInbox(
        limit: 30,
        offset: offset,
      );

      final activities =
          (activitiesResponse['activities'] as List)
              .map((json) => TaskActivity.fromJson(json))
              .toList();

      // Merge activities and messages, sort by timestamp
      final inboxItems =
          activities.map((a) => InboxItem.fromActivity(a)).toList();

      state = state.copyWith(
        newItems: inboxItems,
        isLoading: false,
        unseenCount: activitiesResponse['unseenCount'] ?? 0,
        totalCount: activitiesResponse['totalCount'] ?? 0,
        hasMore: activities.length >= 30,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      print("error: $e");
    }
  }

  /// Mark activity as seen
  Future<void> markActivitySeen(int activityId) async {
    try {
      await _repo.markSeen(activityId);

      // Update local state
      state = state.markAsSeen(activityId);
    } catch (e) {
      print('Error marking activity as seen: $e');
    }
  }

  /// Returns the fetched inbox from server, NOT from existing state
  Future<List<InboxItem>> getInboxBefore({
    required int beforeInboxId,
    int limit = 20,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final olderActivities = await _repo.getInboxBefore(
        beforeInboxId: beforeInboxId,
        limit: limit,
      );

      print("older inbox: ${olderActivities.length}");

      final older =
          olderActivities
              .map((activity) => InboxItem.fromActivity(activity))
              .toList();

      // Step 4: Update state
      state = state.copyWith(
        newItems: older,
        isLoading: false,
        newItemState: NewMessageState.messagesBefore,
      );

      return older;
    } catch (e) {
      print("error loading message before: ${e}");
      state = state.copyWith(
        error: 'Failed to load older messages',
        isLoading: false,
      );

      return [];
    }
  }

  /// Clear all items (for logout, etc.)
  void clear() {
    state = InboxState();
  }
}

final activityRepoProvider = Provider<ActivityRepo>((ref) => ActivityRepo());

final inboxNotifierProvider = StateNotifierProvider<InboxNotifier, InboxState>((
  ref,
) {
  final repo = ref.watch(activityRepoProvider);
  return InboxNotifier(repo, ref);
});
