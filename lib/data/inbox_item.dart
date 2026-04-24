import 'package:smooflow/core/models/message.dart';
import 'package:smooflow/core/models/task_activity.dart';

enum InboxItemType { activity, message }

class InboxItem {
  final InboxItemType type;
  final TaskActivity? activity;
  final Message? message;
  final DateTime timestamp;
  final bool isSeen;

  InboxItem({
    required this.type,
    this.activity,
    this.message,
    required this.timestamp,
    this.isSeen = false,
  }) : assert(
         (type == InboxItemType.activity && activity != null) ||
             (type == InboxItemType.message && message != null),
       );

  factory InboxItem.fromActivity(TaskActivity activity) {
    return InboxItem(
      type: InboxItemType.activity,
      activity: activity,
      timestamp: activity.updatedAt,
      isSeen: activity.isSeen,
    );
  }

  factory InboxItem.fromMessage(Message message) {
    return InboxItem(
      type: InboxItemType.message,
      message: message,
      timestamp: message.date,
      isSeen: false, // Messages use task.unreadCount instead
    );
  }

  int get taskId {
    if (type == InboxItemType.activity) {
      return activity!.taskId;
    } else {
      return message!.taskId;
    }
  }

  int get id {
    if (type == InboxItemType.activity) {
      return activity!.id;
    } else {
      return message!.id;
    }
  }
}
