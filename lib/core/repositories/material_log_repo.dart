import 'dart:convert';
import 'package:smooflow/core/api/api_client.dart';

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

  Future<MaterialLog> addMaterialLog(MaterialLog log) async {
    try {
      final response = await ApiClient.http.post(
        '/material-logs',
        headers: {'Content-Type': 'application/json'},
        body: log.toJson(),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create material log: ${response.body}');
      }

      final json = jsonDecode(response.body);
      return MaterialLog.fromJson(json);
    } catch (e) {
      print('Error adding material log: $e');
      rethrow;
    }
  }
}
