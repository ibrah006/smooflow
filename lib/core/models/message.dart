// models/message.dart

import 'dart:ui';

import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/extensions/color_hex.dart';
import 'package:smooflow/extensions/username_essentials.dart';

class Message {
  late final int id;
  final String message;
  final DateTime date;
  final String authorId;
  final int taskId;

  final Color? authorColor;

  final String authorName;

  String get authorInitials => authorName.initials;

  Message({
    required this.id,
    required this.message,
    required this.date,
    required this.authorId,
    required this.taskId,
    required this.authorColor,
    required this.authorName,
  });

  Message.create({required this.message, required this.taskId})
    : authorId = LoginService.currentUser!.id,
      authorColor = LoginService.currentUser!.color,
      authorName = LoginService.currentUser!.name,
      date = DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      message: json['message'],
      date: DateTime.parse(json['date']),
      authorId: json['user']?['id'] ?? json['userId'],
      taskId: json['task']?['id'] ?? json['taskId'],
      authorColor:
          json['user']['color'] != null
              ? json['user']['color'].toString().toColor()
              : null,
      authorName: json['user']['name'] ?? 'Unknown User',
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
