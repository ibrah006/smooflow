import 'dart:convert';

import 'package:smooflow/core/api/api_client.dart';

class ActivityRepo {
  /// GET /activities/inbox — fetch inbox activities
  Future<Map<String, dynamic>> fetchInbox({int limit = 30, int? offset}) async {
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
}
