// models/message.dart

class Message {
  final int id;
  final String message;
  final DateTime date;
  final int userId;
  final int taskId;

  // Optional nested data (if returned)
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? task;

  Message({
    required this.id,
    required this.message,
    required this.date,
    required this.userId,
    required this.taskId,
    this.user,
    this.task,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      message: json['message'],
      date: DateTime.parse(json['date']),
      userId: json['user']?['id'] ?? json['userId'],
      taskId: json['task']?['id'] ?? json['taskId'],
      user: json['user'],
      task: json['task'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "message": message,
      "taskId": taskId,
      "date": date.toIso8601String(),
    };
  }
}
