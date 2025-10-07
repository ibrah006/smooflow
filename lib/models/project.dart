import 'package:smooflow/models/company.dart';
import 'package:uuid/uuid.dart';

import 'task.dart';
import 'user.dart';

class Project {
  final String id;
  final String name;
  final String? description;
  String _status;
  final DateTime? dueDate;
  final DateTime? estimatedProductionStart;
  final DateTime? estimatedSiteFixing;
  final List<Task> tasks;
  final List<User> assignedManagers;
  final DateTime dateStarted;
  final Company client;
  final int priority;
  // Progress logs' ids
  final List<String> progressLogs;

  final DateTime progressLogLastModifiedAt;

  set status(String newStatus) {
    _status = newStatus;
  }

  String get status => _status;

  // You can add computed/derived fields here as needed
  // e.g., double? projectEfficiency;

  Project({
    required this.id,
    required this.name,
    this.description,
    required String status,
    this.dueDate,
    this.estimatedProductionStart,
    this.estimatedSiteFixing,
    required this.tasks,
    required this.assignedManagers,
    required this.dateStarted,
    required this.client,
    required this.priority,
    required this.progressLogs,
  }) : _status = status,
       progressLogLastModifiedAt = DateTime.now();

  Project.create({
    required this.name,
    this.description,
    // required this.status,
    this.dueDate,
    this.estimatedProductionStart,
    this.estimatedSiteFixing,
    required this.assignedManagers,
    required this.client,
    required this.priority,
  }) : id = Uuid().v1(),
       _status = "Pending",
       tasks = [],
       dateStarted = DateTime.now(),
       progressLogs = [],
       progressLogLastModifiedAt = DateTime.now();

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: json['status'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      estimatedProductionStart:
          json['estimatedProductionStart'] != null
              ? DateTime.parse(json['estimatedProductionStart'])
              : null,
      estimatedSiteFixing:
          json['estimatedSiteFixing'] != null
              ? DateTime.parse(json['estimatedSiteFixing'])
              : null,
      tasks:
          ((json['tasks'] ?? []) as List<dynamic>).map((e) {
            e["project"] = {"id": json["id"]};
            return Task.fromJson(e);
          }).toList(),
      assignedManagers:
          ((json['assignedManagers'] ?? []) as List<dynamic>)
              .map((e) => User.fromJson(e))
              .toList(),
      dateStarted: DateTime.parse(json['dateStarted']),
      client: Company.fromJson(json['client']),
      priority: json['priority'],
      progressLogs:
          (json['progressLogs'] as List?)
              ?.map(
                (e) =>
                    // Progress log id
                    e["id"].toString(),
              )
              .toList() ??
          [],
    );
  }

  List<User> get assignees {
    final List<User> projectAssignees = [];
    for (Task task in tasks) {
      for (User assignee in task.assignees) {
        if (!projectAssignees.contains(assignee)) {
          projectAssignees.add(assignee);
        }
      }
    }

    return projectAssignees;
  }

  Iterable<Task> get completedTasks {
    return tasks.where((task) => task.dateCompleted != null);
  }

  Iterable<String> get uniqueTaskStatuses {
    final List<String> uniqueStatuses = [];
    for (Task task in tasks) {
      if (!uniqueStatuses.contains(task.status)) {
        uniqueStatuses.add(task.status);
      }
    }

    return uniqueStatuses;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': _status,
      'dueDate': dueDate?.toIso8601String(),
      'estimatedProductionStart': estimatedProductionStart?.toIso8601String(),
      'estimatedSiteFixing': estimatedSiteFixing?.toIso8601String(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'assignedManagers':
          assignedManagers.map((manager) => manager.toJson()).toList(),
      // 'dateStarted': dateStarted.toIso8601String(),
      'client': client.toJson(),
      'priority': priority,
      'progressLogs': progressLogs.map((logId) => {"id": logId}).toList(),
    };
  }

  // Only local data
  late double progressRate;
}
