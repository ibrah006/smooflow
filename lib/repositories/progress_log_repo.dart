import 'dart:convert';

import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';
import 'package:smooflow/models/progress_log.dart';

class ProgressLogRepo {
  // Get progress log
  Future<ProgressLog> getProgressLog(String id) async {
    final response = await ApiClient.http.get(
      ApiEndpoints.getProgressLogById(id),
    );

    if (response.statusCode != 200) {
      throw "Failed to get progress log, STATUS ${response.statusCode}: ${response.body}";
    }

    // Successfully updated progress log
    return ProgressLog.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Get progress logs by project
  /// Get progress logs since(datetime) by project
  Future<List<ProgressLog>> getProgressLogByProject({
    required String projectId,
    DateTime? since,
  }) async {
    final response = await ApiClient.http.get(
      ApiEndpoints.getProgressLogByProject(projectId, since: since),
    );

    if (response.statusCode != 200) {
      throw "Failed to get progress logs, STATUS ${response.statusCode}: ${response.body}";
    }

    // Successfully updated progress log
    return (jsonDecode(response.body) as List)
        .map((json) => ProgressLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<DateTime?> getProjectProgressLogLastModified(String projectId) async {
    final response = await ApiClient.http.get(
      ApiEndpoints.getProjectProgressLogLastModified(projectId),
    );

    if (response.statusCode != 200) {
      throw "Failed to get progress logs last modified from project possibly because the project was not found";
    }

    final progressLogLastModifiedAt =
        jsonDecode(response.body)['progressLogLastModifiedAt'];

    return progressLogLastModifiedAt != null
        ? DateTime.parse(progressLogLastModifiedAt)
        : null;
  }

  // Create progress log
  Future<void> updateProgressLog(
    String progressLogId, {

    /// refer to ProgressLog().toUpdateJson()
    required Map<String, dynamic> update,
  }) async {
    final response = await ApiClient.http.put(
      ApiEndpoints.updateProgressLog(progressLogId),
      body: update,
    );

    if (response.statusCode != 200) {
      throw "Failed to update progress log, STATUS ${response.statusCode}: ${response.body}";
    }

    // Successfully updated progress log
  }
}
