import 'package:smooflow/core/models/task_activity.dart';
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
