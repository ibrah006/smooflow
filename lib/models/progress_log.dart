import 'package:smooflow/enums/progress_issue.dart';
import 'package:smooflow/enums/status.dart';
import 'package:uuid/uuid.dart';

class ProgressLog {
  final String id;
  final String projectId;

  Status _status;
  Status get status => _status;
  // set status(Status newValue) => _status = newValue;

  String? _description;
  String? get description => _description;
  set description(String? newDescription) {
    _description = newDescription;
  }

  final DateTime? dueDate;
  final DateTime startDate;

  ProgressIssue? _issue;
  ProgressIssue? get issue => _issue;
  set issue(ProgressIssue? newIssue) {
    _issue = newIssue;
  }

  late bool _isCompleted;
  bool get isCompleted => _isCompleted;
  set isCompleted(bool newValue) => _isCompleted = newValue;

  bool get hasIssues {
    return (issue != null && issue != ProgressIssue.none);
  }

  DateTime? completedAt;

  ProgressLog({
    required this.id,
    required this.projectId,
    required Status status,
    required String? description,
    required this.startDate,
    this.dueDate,
    ProgressIssue? issue,
    required bool isCompleted,
    required this.completedAt,
  }) : _status = status,
       _issue = issue {
    _description = description;
    _isCompleted = isCompleted;
  }

  ProgressLog.create({
    required this.projectId,
    required final Status status,
    required String? description,
    required this.dueDate,
    required ProgressIssue issue,
  }) : id = const Uuid().v4(),
       startDate = DateTime.now(),
       _isCompleted = false,
       _status = status,
       _issue = issue {
    _description = description;
  }

  factory ProgressLog.fromJson(Map<String, dynamic> json) {
    late final ProgressIssue? issue;
    try {
      issue = ProgressIssue.values.byName(json['issue']);
    } catch (err) {
      issue = ProgressIssue.none;
    }

    return ProgressLog(
      id: json['id'],
      projectId: json["project"]["id"],
      status: Status.values.byName(json['status']),
      description: json['description'],
      issue: issue,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      startDate: DateTime.parse(json['startDate']),
      isCompleted: json['isCompleted'],
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
    );
  }

  factory ProgressLog.deleted(String progressId) {
    return ProgressLog(
      id: progressId,
      projectId: "<deleted>",
      status: Status.values.first, // or a specific deleted-like status
      description: "<deleted_progress_log_desc>",
      startDate: DateTime.fromMillisecondsSinceEpoch(0),
      dueDate: null,
      issue: ProgressIssue.none,
      isCompleted: false,
      completedAt: null,
    );
  }

  bool get isDeleted {
    return projectId == "<deleted>" &&
        description == "<deleted_progress_log_desc>" &&
        startDate == DateTime.fromMillisecondsSinceEpoch(0) &&
        issue == ProgressIssue.none &&
        !isCompleted &&
        completedAt == null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project': {id: projectId},
      'status': status.name,
      'description': description,
      'issue': issue?.name,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'description': description,
      'issue': issue?.name,
      'isCompleted': isCompleted,
    };
  }
}
