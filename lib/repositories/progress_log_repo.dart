import 'dart:convert';

import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/endpoints.dart';
import 'package:smooflow/core/models/progress_log.dart';

class ProgressLogRepo {
  // returns: success code
  // 201 success, 209 can't add two consecutive logs of same status
  // Doesn't return code for 400 status, throws error instead
  // Create progress log
  Future<int> createProgressLog(String projectId, ProgressLog log) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.projectProgressLogs(projectId),
      body: log.toJson(),
    );

    if (response.statusCode != 201 && response.statusCode != 209) {
      throw "Failed to create progress log, STATUS ${response.statusCode}: ${response.body}";
    }

    // Successfully created progress log entry
    return response.statusCode;
  }

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
        jsonDecode(response.body)['lastModifiedAt'];

    print("progressLogLastModifiedAt: $progressLogLastModifiedAt");

    return progressLogLastModifiedAt != null
        ? DateTime.parse(progressLogLastModifiedAt)
        : null;
  }

  // Create progress log
  Future<DateTime?> updateProgressLog(
    String progressLogId, {

    /// refer to ProgressLog().toUpdateJson()
    required Map<String, dynamic> update,
  }) async {
    final response = await ApiClient.http.put(
      ApiEndpoints.updateProgressLog(progressLogId),
      body: update,
    );

    if (response.statusCode != 201) {
      throw "Failed to update progress log, STATUS ${response.statusCode}: ${response.body}";
    }

    final completedAtRaw =
        (jsonDecode(response.body) as Map<String, dynamic>)["completedAt"];

    // Successfully updated progress log
    return (completedAtRaw == true ? DateTime.parse(completedAtRaw!) : null);
  }
}
