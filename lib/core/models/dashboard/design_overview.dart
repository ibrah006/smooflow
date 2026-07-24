// lib/core/models/dashboard/design_overview.dart
import 'package:smooflow/core/models/dashboard/dashboard_models.dart';

class DesignOverview {
  final DesignQueue myQueue;
  final DesignHandoff handoff;
  final DesignAttention attention;
  final DesignMessages messages;
  final List<TaskSummary> upcomingDeadlines;
  final int weeklyThroughput;

  DesignOverview({
    required this.myQueue,
    required this.handoff,
    required this.attention,
    required this.messages,
    required this.upcomingDeadlines,
    required this.weeklyThroughput,
  });

  factory DesignOverview.fromJson(Map<String, dynamic> json) {
    return DesignOverview(
      myQueue: DesignQueue.fromJson(json['myQueue'] as Map<String, dynamic>),
      handoff: DesignHandoff.fromJson(json['handoff'] as Map<String, dynamic>),
      attention: DesignAttention.fromJson(
        json['attention'] as Map<String, dynamic>,
      ),
      messages: DesignMessages.fromJson(
        json['messages'] as Map<String, dynamic>,
      ),
      upcomingDeadlines:
          ((json['upcomingDeadlines'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
      weeklyThroughput: json['weeklyThroughput'] as int? ?? 0,
    );
  }
}

class DesignQueue {
  final List<StatusGroup<TaskSummary>> statusGroups;
  final List<TaskSummary> revisionTasks;

  DesignQueue({required this.statusGroups, required this.revisionTasks});

  factory DesignQueue.fromJson(Map<String, dynamic> json) {
    return DesignQueue(
      statusGroups:
          ((json['statusGroups'] as List?) ?? [])
              .map(
                (sg) => StatusGroup.fromJson(
                  sg as Map<String, dynamic>,
                  (t) => TaskSummary.fromJson(t),
                ),
              )
              .toList(),
      revisionTasks:
          ((json['revisionTasks'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
    );
  }

  int get allTasksCount =>
      statusGroups.fold(0, (sum, sg) => sum + sg.items.length);
}

class DesignHandoff {
  final int readyForPrintCount;
  final List<TaskSummary> missingSpecTasks;
  final List<TaskSummary> multiSpecTasks;

  DesignHandoff({
    required this.readyForPrintCount,
    required this.missingSpecTasks,
    required this.multiSpecTasks,
  });

  factory DesignHandoff.fromJson(Map<String, dynamic> json) {
    return DesignHandoff(
      readyForPrintCount: json['readyForPrintCount'] as int? ?? 0,
      missingSpecTasks:
          ((json['missingSpecTasks'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
      multiSpecTasks:
          ((json['multiSpecTasks'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
    );
  }

  bool get hasReadyTasks => readyForPrintCount > 0;
  bool get hasPendingWork =>
      missingSpecTasks.isNotEmpty || multiSpecTasks.isNotEmpty;
  int get totalReadyAndPending =>
      readyForPrintCount + missingSpecTasks.length + multiSpecTasks.length;
}

class DesignAttention {
  final List<TaskSummary> stalledApprovalTasks;
  final List<TaskSummary> blockedOrPausedTasks;

  DesignAttention({
    required this.stalledApprovalTasks,
    required this.blockedOrPausedTasks,
  });

  factory DesignAttention.fromJson(Map<String, dynamic> json) {
    return DesignAttention(
      stalledApprovalTasks:
          ((json['stalledApprovalTasks'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
      blockedOrPausedTasks:
          ((json['blockedOrPausedTasks'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
    );
  }

  int get totalIssues =>
      stalledApprovalTasks.length + blockedOrPausedTasks.length;
  bool get hasIssues => totalIssues > 0;
}

class DesignMessages {
  final List<TaskSummary> unreadThreadTasks;

  DesignMessages({required this.unreadThreadTasks});

  factory DesignMessages.fromJson(Map<String, dynamic> json) {
    return DesignMessages(
      unreadThreadTasks:
          ((json['unreadThreadTasks'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
    );
  }

  int get totalUnreadCount =>
      unreadThreadTasks.fold(0, (sum, t) => sum + t.unreadCount);
}
