import 'dart:convert';

import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/models/work_activity_log.dart';

class WorkActivityLogRepo {
  /// Fetch all work activity logs for a specific task
  Future<List<WorkActivityLog>> getLogsByTask(int taskId) async {
    final response = await ApiClient.http.get(
      '/work-activity-logs/task/$taskId',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load work activity logs for task $taskId: ${response.body}',
      );
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => WorkActivityLog.fromJson(json)).toList();
  }
}
