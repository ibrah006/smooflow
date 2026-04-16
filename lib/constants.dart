import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooflow/components/discussion_forms.dart';
import 'package:smooflow/core/models/message.dart';
import 'package:smooflow/core/models/task_activity.dart';
import 'package:smooflow/data/inbox_item.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

const colorPrimary = Color(0xFF2563eb);
const colorLight = Color(0xFFf0f2fe);
const colorPositiveStatus = Color(0xFF19a74e);
const colorPurple = Color(0xFF9333ea);
const colorBorder = Color(0xFFf3f4f6);
const colorBorderDark = Color(0xFFe9e9ed);
const backgroundDarker2 = Color(0xFFf9fafc);
const backgroundDarker = Color(0xFFf8fafc);
const colorPending = Color(0xFFf59e0b);
const colorError = Color(0xFFd53d3c);
const colorErrorBackground = Color(0xFFfbebec);

const timelineRefreshIntervalSecs = 60;

const kOverallProgressHeroKey = "overall_progress";

final GlobalKey<ScaffoldMessengerState> kRootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final kNavigatorKey = GlobalKey<NavigatorState>();

List<InboxItem> get sampleInboxItems {
  final now = DateTime.now();

  return <InboxItem>[
    // 🔴 Recent message (unseen)
    InboxItem.fromMessage(
      Message(
        id: 1,
        message: "Can you check the latest wireframes?",
        date: now.subtract(Duration(minutes: 2)),
        userId: "u1",
        taskId: 101,
        authorColor: Color(0xFF2196F3),
        authorName: "Alice Johnson",
      ),
    ),

    // 🟡 Seen activity (stage forward)
    InboxItem.fromActivity(
      TaskActivity(
        id: 101,
        type: ActivityType.stageForward,
        taskId: 101,
        taskName: "Landing Page Design",
        taskPriority: 2,
        taskDueDate: now.add(Duration(days: 3)),
        taskStatus: "in_progress",
        actorId: "u2",
        actorName: "Bob Smith",
        actorInitials: "BS",
        actorColor: Color(0xFF4CAF50),
        metadata: {"fromStage": "Backlog", "toStage": "In Progress"},
        createdAt: now.subtract(Duration(minutes: 5)),
        isSeen: true,
      ),
    ),

    // 🔴 Unseen activity (assignee added)
    InboxItem.fromActivity(
      TaskActivity(
        id: 102,
        type: ActivityType.assigneeAdded,
        taskId: 102,
        taskName: "API Integration",
        taskPriority: 3,
        taskDueDate: null,
        taskStatus: "open",
        actorId: "u3",
        actorName: "Charlie Lee",
        actorInitials: "CL",
        actorColor: Color(0xFFFF9800),
        metadata: {"addedUserName": "Diana Prince"},
        createdAt: now.subtract(Duration(minutes: 10)),
        isSeen: false,
      ),
    ),

    // 💬 Message burst (same task)
    InboxItem.fromMessage(
      Message(
        id: 2,
        message: "Hey, quick update?",
        date: now.subtract(Duration(minutes: 12)),
        userId: "u4",
        taskId: 103,
        authorColor: Color(0xFF9C27B0),
        authorName: "Diana Prince",
      ),
    ),
    InboxItem.fromMessage(
      Message(
        id: 3,
        message: "We might need to delay deployment.",
        date: now.subtract(Duration(minutes: 13)),
        userId: "u4",
        taskId: 103,
        authorColor: Color(0xFF9C27B0),
        authorName: "Diana Prince",
      ),
    ),

    // 🟡 Priority change (seen)
    InboxItem.fromActivity(
      TaskActivity(
        id: 103,
        type: ActivityType.priorityChanged,
        taskId: 104,
        taskName: "Fix Login Bug",
        taskPriority: 1,
        taskDueDate: now.add(Duration(days: 1)),
        taskStatus: "in_progress",
        actorId: "u1",
        actorName: "Alice Johnson",
        actorInitials: "AJ",
        actorColor: Color(0xFF2196F3),
        metadata: {"fromPriority": 3, "toPriority": 1},
        createdAt: now.subtract(Duration(hours: 1)),
        isSeen: true,
      ),
    ),

    // 🔴 Printer assigned (unseen)
    InboxItem.fromActivity(
      TaskActivity(
        id: 104,
        type: ActivityType.printerAssigned,
        taskId: 105,
        taskName: "Print Brochures",
        taskPriority: 2,
        taskDueDate: now.add(Duration(days: 5)),
        taskStatus: "assigned",
        actorId: "u5",
        actorName: "Ethan Hunt",
        actorInitials: "EH",
        actorColor: Color(0xFFF44336),
        printerId: "p1",
        printerName: "HP LaserJet 4200",
        printerNickname: "Office Printer",
        createdAt: now.subtract(Duration(hours: 2)),
        isSeen: false,
      ),
    ),

    // 💬 Long message (UI stress)
    InboxItem.fromMessage(
      Message(
        id: 4,
        message:
            "This is a long message intended to test how your inbox UI handles multi-line text, overflow, wrapping, and whether trailing UI elements like timestamps and badges stay aligned properly.",
        date: now.subtract(Duration(hours: 3)),
        userId: "u2",
        taskId: 106,
        authorColor: Color(0xFF4CAF50),
        authorName: "Bob Smith",
      ),
    ),

    // 🟡 Due date changed
    InboxItem.fromActivity(
      TaskActivity(
        id: 105,
        type: ActivityType.dueDateChanged,
        taskId: 104,
        taskName: "Fix Login Bug",
        taskPriority: 1,
        taskDueDate: now.add(Duration(days: 2)),
        taskStatus: "in_progress",
        actorId: "u2",
        actorName: "Bob Smith",
        actorInitials: "BS",
        actorColor: Color(0xFF4CAF50),
        metadata: {
          "fromDueDate": now.add(Duration(days: 1)).toIso8601String(),
          "toDueDate": now.add(Duration(days: 2)).toIso8601String(),
        },
        createdAt: now.subtract(Duration(hours: 4)),
        isSeen: true,
      ),
    ),

    // 🔴 Billing status change (unseen)
    InboxItem.fromActivity(
      TaskActivity(
        id: 106,
        type: ActivityType.billingStatusChanged,
        taskId: 107,
        taskName: "Client Invoice #456",
        taskPriority: 2,
        taskDueDate: null,
        taskStatus: "completed",
        actorId: "u6",
        actorName: "Frank Miller",
        actorInitials: "FM",
        actorColor: Color(0xFF009688),
        metadata: {"fromBillingStatus": "pending", "toBillingStatus": "paid"},
        createdAt: now.subtract(Duration(hours: 6)),
        isSeen: false,
      ),
    ),

    // 🟡 Old completed task
    InboxItem.fromActivity(
      TaskActivity(
        id: 107,
        type: ActivityType.taskCompleted,
        taskId: 108,
        taskName: "Deploy Backend",
        taskPriority: 1,
        taskDueDate: now.subtract(Duration(days: 1)),
        taskStatus: "completed",
        actorId: "u3",
        actorName: "Charlie Lee",
        actorInitials: "CL",
        actorColor: Color(0xFFFF9800),
        createdAt: now.subtract(Duration(days: 2)),
        isSeen: true,
      ),
    ),

    // 🔴 Very old unseen (important UX edge case)
    InboxItem.fromActivity(
      TaskActivity(
        id: 108,
        type: ActivityType.taskCancelled,
        taskId: 109,
        taskName: "Old Campaign",
        taskPriority: 3,
        taskDueDate: null,
        taskStatus: "cancelled",
        actorId: "u4",
        actorName: "Diana Prince",
        actorInitials: "DP",
        actorColor: Color(0xFF9C27B0),
        createdAt: now.subtract(Duration(days: 5)),
        isSeen: false,
      ),
    ),
  ];
}
