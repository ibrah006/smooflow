import 'package:smooflow/enums/progress_issue.dart';
import 'package:smooflow/enums/status.dart';
import 'package:uuid/uuid.dart';

class ProgressLog {
  final String id;
  final String projectId; // Assuming you'll pass the project ID only
  final Status status;
  final String? description;
  final DateTime? dueDate;
  final DateTime startDate;
  final ProgressIssue? issue;

  bool get hasIssues {
    return (issue != null && issue != ProgressIssue.none);
  }

  ProgressLog({
    required this.id,
    required this.projectId,
    required this.status,
    this.description,
    required this.startDate,
    this.dueDate,
    this.issue,
  });

  ProgressLog.create({
    required this.projectId,
    required this.status,
    this.description,
    this.dueDate,
    this.issue,
  }) : id = const Uuid().v4(),
       startDate = DateTime.now();

  factory ProgressLog.fromJson(String projectId, Map<String, dynamic> json) {
    late final ProgressIssue? issue;
    try {
      issue = ProgressIssue.values.byName(json['issue']);
    } catch (err) {
      issue = ProgressIssue.none;
    }

    return ProgressLog(
      id: json['id'],
      projectId: projectId, // supports both direct and nested
      status: Status.values.byName(json['status']),
      description: json['description'],
      issue: issue,
      dueDate: DateTime.parse(json['dueDate']),
      startDate: DateTime.parse(json['startDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': {id: projectId},
      'status': status.name,
      'description': description,
      'issue': issue?.name,
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}
