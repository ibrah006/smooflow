import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/message.dart';
import 'package:smooflow/core/models/task_activity.dart';
import 'package:smooflow/core/repositories/activity_repo.dart';
import 'package:smooflow/core/repositories/message_repo.dart';
import 'package:smooflow/data/inbox_item.dart';
import 'package:smooflow/providers/message_provider.dart';

class InboxState {
  final List<InboxItem> items;
  final bool isLoading;
  final String? error;
  final int unseenCount;
  final int totalCount;
  final bool hasMore;

  const InboxState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.unseenCount = 0,
    this.totalCount = 0,
    this.hasMore = true,
  });

  InboxState copyWith({
    List<InboxItem>? items,
    bool? isLoading,
    String? error,
    int? unseenCount,
    int? totalCount,
    bool? hasMore,
  }) {
    return InboxState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unseenCount: unseenCount ?? this.unseenCount,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class InboxNotifier extends StateNotifier<InboxState> {
  final ActivityRepo _repo;
  final Ref _ref;

  InboxNotifier(this._repo, this._ref) : super(const InboxState());

  /// Fetch inbox items (activities + recent messages merged)
  Future<void> fetchInbox({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final offset = refresh ? 0 : state.items.length;

      // Fetch activities
      final activitiesResponse = await _repo.fetchInbox(
        limit: 30,
        offset: offset,
      );

      final activities =
          (activitiesResponse['activities'] as List)
              .map((json) => TaskActivity.fromJson(json))
              .toList();

      // Fetch recent messages (from tasks with unread messages)
      // This is a simplified approach - you might want to optimize this
      final messages = await _ref
          .read(messageNotifierProvider.notifier)
          .getRecent(limit: 20);

      // Merge activities and messages, sort by timestamp
      final activityItems =
          activities.map((a) => InboxItem.fromActivity(a)).toList();
      final messageItems =
          messages.map((m) => InboxItem.fromMessage(m)).toList();

      final allItems = [...activityItems, ...messageItems];
      allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final newItems = refresh ? allItems : [...state.items, ...allItems];

      state = state.copyWith(
        items: newItems,
        isLoading: false,
        unseenCount: activitiesResponse['unseenCount'] ?? 0,
        totalCount: activitiesResponse['totalCount'] ?? 0,
        hasMore: activities.length >= 30,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Mark activity as seen
  Future<void> markActivitySeen(int activityId) async {
    try {
      await _repo.markSeen(activityId);

      // Update local state
      final updatedItems =
          state.items.map((item) {
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
                  createdAt: item.activity!.createdAt,
                  isSeen: true,
                ),
              );
            }
            return item;
          }).toList();

      state = state.copyWith(
        items: updatedItems,
        unseenCount: state.unseenCount > 0 ? state.unseenCount - 1 : 0,
      );
    } catch (e) {
      print('Error marking activity as seen: $e');
    }
  }

  /// Clear all items (for logout, etc.)
  void clear() {
    state = const InboxState();
  }
}

final activityRepoProvider = Provider<ActivityRepo>((ref) => ActivityRepo());

final inboxNotifierProvider = StateNotifierProvider<InboxNotifier, InboxState>((
  ref,
) {
  final repo = ref.watch(activityRepoProvider);
  return InboxNotifier(repo, ref);
});
