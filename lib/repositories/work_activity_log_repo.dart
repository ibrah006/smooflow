import 'dart:convert';

import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/endpoints.dart';
import 'package:smooflow/core/models/work_activity_log.dart';
import 'package:smooflow/services/login_service.dart';

class WorkActivityLogRepo {
  /// Fetch all work activity logs for a specific task.
  /// Optionally filters logs updated since the provided timestamp.
  Future<List<WorkActivityLogTemp>> getLogsByTask(
    int taskId, {
    DateTime? since,
  }) async {
    // Construct the endpoint with optional ?since param
    String endpoint = '/activity/task/$taskId';
    if (since != null) {
      endpoint += '?since=${since.toUtc().toIso8601String()}';
    }

    final response = await ApiClient.http.get(endpoint);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load work activity logs for task $taskId: ${response.body}',
      );
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => WorkActivityLogTemp.fromJson(json)).toList();
  }

  Future<DateTime?> getTaskActivityLogsLastModified(int taskId) async {
    // Optional endpoint like: GET /tasks/:projectId/last-modified
    final response = await ApiClient.http.get(
      '/activity/task/$taskId/last-modified',
    );
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    return DateTime.parse(body['lastModified']);
  }

  Future<WorkActivityLog?> getActiveLog() async {
    final response = await ApiClient.http.get(
      ApiEndpoints.getUserActiveWorkActivityLog,
    );

    if (response.statusCode != 200) {
      return null;
    }

    final Map<String, dynamic> json = {
      ...jsonDecode(response.body)["active"],
      "user": {"id": LoginService.currentUser!.id},
    };

    return WorkActivityLog.fromJson(json);
  }
}
