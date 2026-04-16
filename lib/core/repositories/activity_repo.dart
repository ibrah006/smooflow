import 'dart:convert';

import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/task_activity.dart';

class ActivityRepo {
  /// GET /activities/inbox — fetch inbox activities
  Future<List<TaskActivity>> fetchInbox() async {
    final response = await ApiClient.http.get('/activities/inbox');
    if (response.statusCode != 200) {
      throw Exception('Failed to load inbox: ${response.body}');
    }

    final List<dynamic> body = jsonDecode(response.body);
    return body.map((taskJson) => TaskActivity.fromJson(taskJson)).toList();
  }
}
