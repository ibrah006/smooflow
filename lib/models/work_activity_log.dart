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
