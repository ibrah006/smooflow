import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/task_activity.dart';
import 'package:smooflow/core/repositories/activity_repo.dart';
import 'package:smooflow/data/inbox_item.dart';
import 'package:smooflow/states/message.dart';
import 'package:smooflow/utils/mergeByObjectId.dart';

const _MAX_INBOX_ITEMS = 40;

class InboxState {
  final List<InboxItem> items;
  final bool isLoading;
  final String? error;
  final int unseenCount;
  final int totalCount;
  final bool hasMore;

  int? activeInboxId;

  InboxState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.unseenCount = 0,
    this.totalCount = 0,
    this.hasMore = true,
    this.activeInboxId,
  });

  InboxState markAsSeen(int activityId) {
    return InboxState(
      items:
          items.map((item) {
            if (item.type == InboxItemType.activity &&
                item.activity!.id == activityId) {
              return InboxItem.fromActivity(
                TaskActivity(
                  id: item.activity!.id,
                  type: item.activity!.type,
                  taskId: item.activity!.taskId,
                  taskName: item.activity!.taskName,
                  taskDescription: item.activity!.taskDescription,
                  taskPriority: item.activity!.taskPriority,
                  taskDueDate: item.activity!.taskDueDate,
                  taskStatus: item.activity!.taskStatus,
                  actorId: item.activity!.actorId,
                  actorName: item.activity!.actorName,
                  actorInitials: item.activity!.actorInitials,
                  actorColor: item.activity!.actorColor,
                  printerId: item.activity!.printerId,
                  printerName: item.activity!.printerName,
                  printerNickname: item.activity!.printerNickname,
                  metadata: item.activity!.metadata,
                  updatedAt: item.activity!.updatedAt,
                  isSeen: true,
                ),
              );
            }
            return item;
          }).toList(),
      isLoading: this.isLoading,
      error: this.error,
      unseenCount: this.unseenCount,
      totalCount: this.totalCount,
      hasMore: this.hasMore,
      activeInboxId: this.activeInboxId,
    );
  }

  InboxState copyWith({
    List<InboxItem>? newItems,
    bool? isLoading,
    String? error,
    int? unseenCount,
    int? totalCount,
    bool? hasMore,
    bool isCreateItem = false,
    NewMessageState newItemState = NewMessageState.messagesAfter,
  }) {
    if (isCreateItem && newItems?.length != 1) {
      throw "To create an inbox item, exactly 1 item is required, found: ${newItems?.length ?? 0}";
    }

    if (newItems != null) {
      final totalLength = newItems.length + items.length;
      _evict(newItemState, totalLength);
    }

    late final List<InboxItem> updatedList;

    if (newItems != null) {
      if (newItems.isEmpty) {
        updatedList = this.items;
      } else if (newItems.length == 1 && isCreateItem) {
        updatedList = List.from(this.items);
        updatedList.insert(0, newItems.first);
      } else {
        updatedList = mergeByObjectId(this.items, newItems);
      }
    } else {
      updatedList = this.items;
    }

    return InboxState(
      items: updatedList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unseenCount: unseenCount ?? this.unseenCount,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  void _evict(NewMessageState newMessageState, int totalLength) {
    final toRemove = totalLength - _MAX_INBOX_ITEMS;

    if (toRemove <= 0) {
      // Nothing to evict, within memory limit set for messages
      return;
    }

    int removed = 0;
    items.removeWhere((m) {
      if (removed <= toRemove && m.taskId != activeInboxId) {
        removed++;
        return true;
      }
      return false;
    });

    // Force remove
    while (toRemove > removed) {
      if (newMessageState == NewMessageState.messagesAfter) {
        items.removeLast();
      } else {
        items.removeAt(0);
      }
      removed++;
    }
  }
}

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
      final activityItems =
          activities.map((a) => InboxItem.fromActivity(a)).toList();

      state = state.copyWith(
        items: activityItems,
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
      final olderInbox = await _repo.getInboxBefore(
        beforeInboxId: beforeInboxId,
        limit: limit,
      );

      print("older inbox: ${olderInbox.length}");

      // Step 4: Update state
      state = state.copyWith(
        newInbox: olderInbox,
        isLoading: false,
        newInboxState: NewMessageState.messagesBefore,
      );

      return olderInbox;
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
