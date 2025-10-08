import 'package:smooflow/models/task.dart';
import 'package:smooflow/models/user.dart';

class WorkActivityLog {
  final int id;
  final User user;
  final Task? task;
  final DateTime start;
  final DateTime? end;

  WorkActivityLog({
    required this.id,
    required this.user,
    required this.task,
    required this.start,
    required this.end,
  });

  static int getIdFromJson(workActivityLogJson) {
    return workActivityLogJson["id"];
  }

  factory WorkActivityLog.fromJson(Map<String, dynamic> json) {
    return WorkActivityLog(
      id: json['id'] as int,
      user: User.fromJson(json['user']),
      task: json['task'] != null ? Task.fromJson(json['task']) : null,
      start: DateTime.parse(json['start']),
      end: json['end'] != null ? DateTime.parse(json['end']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'task': task?.toJson(),
      'start': start.toIso8601String(),
      'end': end?.toIso8601String(),
    };
  }
}
