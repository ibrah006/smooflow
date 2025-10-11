import 'package:smooflow/models/user.dart';
import 'package:smooflow/services/login_service.dart';

class WorkActivityLog {
  final int id;
  final String userId;
  final int? taskId;
  final DateTime start;
  final DateTime? end;

  WorkActivityLog({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.start,
    required this.end,
  });

  WorkActivityLog.create({required this.id, required this.taskId})
    : end = null,
      userId = LoginService.currentUser!.id,
      start = DateTime.now();

  WorkActivityLog.end(WorkActivityLog log)
    : id = log.id,
      userId = log.userId,
      taskId = log.taskId,
      start = log.start,
      end = DateTime.now();

  static int getIdFromJson(workActivityLogJson) {
    return workActivityLogJson["id"];
  }

  factory WorkActivityLog.fromJson(Map<String, dynamic> json) {
    return WorkActivityLog(
      id: json['id'] as int,
      userId: json['user']["id"],
      taskId: json['task'] != null ? json['task']["id"] : null,
      start: DateTime.parse(json['start']),
      end: json['end'] != null ? DateTime.parse(json['end']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'taskId': taskId,
      'start': start.toIso8601String(),
      'end': end?.toIso8601String(),
    };
  }
}

class WorkActivityLogTemp extends WorkActivityLog {
  final User user;

  WorkActivityLogTemp({
    required super.id,
    required this.user,
    required super.taskId,
    required super.start,
    required super.end,
  }) : super(userId: user.id);

  factory WorkActivityLogTemp.fromJson(Map<String, dynamic> json) {
    return WorkActivityLogTemp(
      id: json['id'] as int,
      user: User.fromJson(json['user']),
      taskId: json['task'] != null ? json['task']["id"] : null,
      start: DateTime.parse(json['start']),
      end: json['end'] != null ? DateTime.parse(json['end']) : null,
    );
  }
}
