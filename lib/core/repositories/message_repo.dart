// repositories/message_repository.dart

import 'dart:convert';

import 'package:smooflow/core/api/api_client.dart';

import '../models/message.dart';

class MessageRepo {
  /// GET /messages/:id
  Future<Message?> getById(int id) async {
    final res = await ApiClient.http.get('/messages/$id');

    if (res.statusCode != 200) return null;

    return Message.fromJson(jsonDecode(res.body));
  }

  /// GET /messages/task/:taskId
  Future<List<Message>> getByTaskId(int taskId) async {
    final res = await ApiClient.http.get('/messages/task/$taskId');

    if (res.statusCode != 200) return [];

    return (jsonDecode(res.body) as List)
        .map((e) => Message.fromJson(e))
        .toList();
  }

  /// GET /messages
  Future<List<Message>> getAll() async {
    final res = await ApiClient.http.get('/messages');

    if (res.statusCode != 200) return [];

    return (jsonDecode(res.body) as List)
        .map((e) => Message.fromJson(e))
        .toList();
  }

  /// GET /messages/recent
  Future<List<Message>> getRecent({
    bool userOnly = false,
    int? taskId,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{};

    if (userOnly) queryParams['userOnly'] = 'true';
    if (taskId != null) queryParams['taskId'] = taskId.toString();
    queryParams['limit'] = limit.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    final res = await ApiClient.http.get(
      '/messages/recent${queryString.isNotEmpty ? '?$queryString' : ''}',
    );

    if (res.statusCode != 200) return [];

    return (jsonDecode(res.body) as List)
        .map((e) => Message.fromJson(e))
        .toList();
  }

  /// POST /messages
  Future<Message?> create({
    required String message,
    required int taskId,
    DateTime? date,
  }) async {
    final res = await ApiClient.http.post(
      '/messages',
      body: {
        "message": message,
        "taskId": taskId,
        if (date != null) "date": date.toIso8601String(),
      },
    );

    if (res.statusCode != 201) return null;

    return Message.fromJson(jsonDecode(res.body));
  }

  /// Will get messages that were created after the message id with [afterMessageId]
  Future<List<Message>> getMessagesAfter({
    required int afterMessageId,
    int limit = 15,
    int? taskId,
  }) async {
    final res = await ApiClient.http.get(
      '/messages?afterId=$afterMessageId${taskId != null ? '&taskId=$taskId' : ''}',
    );

    if (res.statusCode != 200) return [];

    return (res.body as List).map((e) => Message.fromJson(e)).toList();
  }
}
