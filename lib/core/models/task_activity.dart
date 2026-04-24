import 'package:flutter/material.dart';

enum ActivityType {
  stageForward,
  stageBackward,
  printerAssigned,
  printerUnassigned,
  taskCreated,
  taskCompleted,
  taskCancelled,
  assigneeAdded,
  assigneeRemoved,
  priorityChanged,
  dueDateChanged,
  billingStatusChanged,
}

class TaskActivity {
  final int id;
  final ActivityType type;
  final int taskId;
  final String taskName;
  final String? taskDescription;
  final int taskPriority;
  final DateTime? taskDueDate;
  final String taskStatus;

  // Actor (who did this)
  final String actorId;
  final String actorName;
  final String actorInitials;
  final Color? actorColor;

  // Printer (if relevant)
  final String? printerId;
  final String? printerName;
  final String? printerNickname;

  final Map<String, dynamic>? metadata;
  final DateTime updatedAt;
  final bool isSeen;

  const TaskActivity({
    required this.id,
    required this.type,
    required this.taskId,
    required this.taskName,
    this.taskDescription,
    required this.taskPriority,
    this.taskDueDate,
    required this.taskStatus,
    required this.actorId,
    required this.actorName,
    required this.actorInitials,
    this.actorColor,
    this.printerId,
    this.printerName,
    this.printerNickname,
    this.metadata,
    required this.updatedAt,
    this.isSeen = false,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> json) {
    return TaskActivity(
      id: json['id'],
      type: _parseActivityType(json['type']),
      taskId: json['taskId'],
      taskName: json['taskName'],
      taskDescription: json['taskDescription'],
      taskPriority: json['taskPriority'],
      taskDueDate:
          json['taskDueDate'] != null
              ? DateTime.parse(json['taskDueDate'])
              : null,
      taskStatus: json['taskStatus'],
      actorId: json['actorId'],
      actorName: json['actorName'],
      actorInitials: json['actorInitials'],
      actorColor:
          json['actorColor'] != null
              ? Color(int.parse(json['actorColor'].replaceFirst('#', '0xFF')))
              : null,
      printerId: json['printerId'],
      printerName: json['printerName'],
      printerNickname: json['printerNickname'],
      metadata: json['metadata'],
      updatedAt: DateTime.parse(json['updatedAt']),
      isSeen: json['isSeen'] ?? false,
    );
  }

  static ActivityType _parseActivityType(String type) {
    switch (type) {
      case 'stage_forward':
        return ActivityType.stageForward;
      case 'stage_backward':
        return ActivityType.stageBackward;
      case 'printer_assigned':
        return ActivityType.printerAssigned;
      case 'printer_unassigned':
        return ActivityType.printerUnassigned;
      case 'task_created':
        return ActivityType.taskCreated;
      case 'task_completed':
        return ActivityType.taskCompleted;
      case 'task_cancelled':
        return ActivityType.taskCancelled;
      case 'assignee_added':
        return ActivityType.assigneeAdded;
      case 'assignee_removed':
        return ActivityType.assigneeRemoved;
      case 'priority_changed':
        return ActivityType.priorityChanged;
      case 'due_date_changed':
        return ActivityType.dueDateChanged;
      case 'billing_status_changed':
        return ActivityType.billingStatusChanged;
      default:
        return ActivityType.stageForward;
    }
  }

  // Helper getters for UI
  String get fromStage => metadata?['fromStage'] ?? '';
  String get toStage => metadata?['toStage'] ?? '';
  String get addedUserName => metadata?['addedUserName'] ?? '';
  String get removedUserName => metadata?['removedUserName'] ?? '';
  int? get fromPriority => metadata?['fromPriority'];
  int? get toPriority => metadata?['toPriority'];
  String? get fromBillingStatus => metadata?['fromBillingStatus'];
  String? get toBillingStatus => metadata?['toBillingStatus'];
}
