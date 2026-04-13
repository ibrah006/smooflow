import 'package:smooflow/core/models/project.dart';

/// Project change event types
enum ProjectChangeType { newProject }

/// Task change event from WebSocket
class TaskChangeEvent {
  final ProjectChangeType type;
  final String? changedBy;
  final DateTime timestamp;
  final Project? project;

  TaskChangeEvent({
    required this.type,
    this.changedBy,
    required this.timestamp,
    this.project,
  });

  factory TaskChangeEvent.fromJson(Map<String, dynamic> json) {
    ProjectChangeType getType(String typeStr) {
      switch (typeStr) {
        case 'new_project':
          return ProjectChangeType.newProject;
        default:
          return ProjectChangeType.newProject;
      }
    }

    return TaskChangeEvent(
      type: getType(json['type'] as String),
      changedBy: json['changedBy'] as String?,
      timestamp: DateTime.parse(json['timestamp']),
      project:
          json['project'] != null ? Project.fromJson(json['project']) : null,
    );
  }
}
