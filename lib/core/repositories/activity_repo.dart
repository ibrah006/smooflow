import 'dart:convert';

import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/task_activity.dart';

class ActivityRepo {
  /// GET /activities/inbox — fetch inbox activities
  Future<Map<String, dynamic>> fetchRecentInbox({
    int limit = 30,
    int? offset,
  }) async {
    final response = await ApiClient.http.get('/activities/inbox');
    if (response.statusCode != 200) {
      throw Exception('Failed to load inbox: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  /// POST /activities/mark-seen — Mark inbox message/activity as seen
  Future markSeen(int activityId) async {
    final response = await ApiClient.http.post(
      '/activities/mark-seen',
      body: {
        "activityIds": [activityId],
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark inbox message(s) as seen');
    }
  }

  /// GET /activities/inbox — fetch inbox activities before the given id
  /// returns the number of inbox items that came from server
  Future<List<TaskActivity>> getInboxBefore({
    required int beforeInboxId,
    int? offset,
    int? limit = 30,
  }) async {
    final response = await ApiClient.http.get(
      '/activities/inbox?beforeId=${beforeInboxId}${limit != null ? '&limit=$limit' : ''}${offset != null ? '&offset=$offset' : ''}',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load inbox: ${response.body}');
    }

    return jsonDecode(response.body);
  }
}
