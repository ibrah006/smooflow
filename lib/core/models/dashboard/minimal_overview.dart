// lib/core/models/dashboard/minimal_overview.dart
import 'package:smooflow/core/models/dashboard/dashboard_models.dart';

class MinimalOverview {
  final List<TaskSummary> myTasks;
  final List<TaskSummary> unreadThreadTasks;
  final List<MinimalProject> myProjects;

  MinimalOverview({
    required this.myTasks,
    required this.unreadThreadTasks,
    required this.myProjects,
  });

  factory MinimalOverview.fromJson(Map<String, dynamic> json) {
    return MinimalOverview(
      myTasks:
          ((json['myTasks'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
      unreadThreadTasks:
          ((json['unreadThreadTasks'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
      myProjects:
          ((json['myProjects'] as List?) ?? [])
              .map((p) => MinimalProject.fromJson(p as Map<String, dynamic>))
              .toList(),
    );
  }

  int get totalOpenTasks => myTasks.length;
  int get totalUnreadMessages =>
      unreadThreadTasks.fold(0, (sum, t) => sum + t.unreadCount);
}

class MinimalProject {
  final String id;
  final String name;
  final String status;
  final int progressPct;

  MinimalProject({
    required this.id,
    required this.name,
    required this.status,
    required this.progressPct,
  });

  factory MinimalProject.fromJson(Map<String, dynamic> json) {
    return MinimalProject(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      progressPct: json['progressPct'] as int? ?? 0,
    );
  }
}
