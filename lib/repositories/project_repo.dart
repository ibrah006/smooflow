import 'dart:convert';

import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/models/task.dart';

class ProjectRepo {
  @deprecated
  static List<Project> projects = [];

  Future<List<Project>> fetchProjects() async {
    final response = await ApiClient.http.get(ApiEndpoints.projects);
    print("fetch projects response body: ${response.body}");
    final body = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw "Failed to fetch projects: ${response.body}";
    }

    projects = (body as List).map((e) => Project.fromJson(e)).toList();

    return projects;
  }

  Future<Map<int, String>> getRecentProjects() async {
    final response = await ApiClient.http.get(ApiEndpoints.getRecentProjects);
    final body = (jsonDecode(response.body) as Map).map(
      (k, projectId) => MapEntry(int.parse(k), projectId.toString()),
    );

    print("body received: ${body}");

    if (response.statusCode != 200) {
      throw "Failed to fetch projects: ${response.body}";
    }

    return body;
  }

  Future<void> createProject(Project project) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.projects,
      body: project.toJson(),
    );
    final body = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw "Failed to create project: ${response.body}\nbody: $body";
    }
  }

  Future<void> updateStatus(String projectId, String newStatus) async {
    final response = await ApiClient.http.put(
      ApiEndpoints.updateProjectStatus(projectId),
      body: {"status": newStatus},
    );

    if (response.statusCode != 200) {
      throw "Failed to update project status: ${response.body}";
    }
  }

  // Get progress logs
  Future<List<ProgressLog>> fetchProgressLogs(String projectId) async {
    final response = await ApiClient.http.get(
      ApiEndpoints.projectProgressLogs(projectId),
    );

    if (response.statusCode != 200) {
      throw "No logs found: ${response.body}";
    }

    final body = jsonDecode(response.body);

    return (body as List).map((e) => ProgressLog.fromJson(e)).toList();
  }

  // Create task
  // return task id
  Future<int> createTask(String projectId, Task task) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.createTask(projectId),
      body: task.toJson(),
    );

    if (response.statusCode != 201) {
      throw "Failed to create Task, STATUS ${response.statusCode}: ${response.body}";
    }

    // Successfully created Task
    return jsonDecode(response.body)["taskId"];
  }

  // Mark task as completed
  // Returns the date the task was marked 'complete' from server
  // This approach is to ensure the local datetime task completed doesn't contradict with the one in database (this problem is short term but crucial to consider)
  Future<DateTime> markTaskAsComplete(int taskId) async {
    final response = await ApiClient.http.put(
      ApiEndpoints.markTaskAsComplete(taskId),
      body: {"placeholder": "null"},
    );

    if (response.statusCode != 200) {
      throw "Failed to mark task as completed, STATUS ${response.statusCode}: ${response.body}";
    }

    // Successfully marked task as completed
    return DateTime.parse((jsonDecode(response.body) as Map)["dateCompleted"]);
  }

  Future<double> getProjectProgressRate(String projectId) async {
    final response = await ApiClient.http.get(
      ApiEndpoints.getProjectProgressRate(projectId),
    );

    if (response.statusCode != 200) {
      throw "Failed to get project's progress rate, STATUS ${response.statusCode}: ${response.body}";
    }

    // Successful
    return (jsonDecode(response.body)["progressRate"] as num).toDouble();
  }

  Future<double> getProjectsProgressRate() async {
    final response = await ApiClient.http.get(
      ApiEndpoints.getProjectsProgressRate,
    );

    if (response.statusCode != 200) {
      throw "Failed to get projects' avg progress rate, STATUS ${response.statusCode}: ${response.body}";
    }

    // Successful
    return (jsonDecode(response.body)["progressRate"] as num).toDouble();
  }
}
