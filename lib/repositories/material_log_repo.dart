import 'dart:convert';
import 'package:smooflow/api/api_client.dart';

import '../models/material_log.dart';

class MaterialLogRepo {
  /// Get all material logs associated with a specific project
  Future<List<MaterialLog>> getMaterialLogsByProject({
    required String projectId,
    DateTime? since,
  }) async {
    final queryParams =
        since != null
            ? '?since=${Uri.encodeComponent(since.toIso8601String())}'
            : '';

    final response = await ApiClient.http.get(
      '/material-logs/project/$projectId$queryParams',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load material logs for project $projectId: ${response.body}',
      );
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => MaterialLog.fromJson(json)).toList();
  }
}
