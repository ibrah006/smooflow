import 'dart:convert';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/services/login_service.dart';

class TaskRepo {
  /// GET /tasks — fetch all tasks
  Future<List<Task>> fetchAllTasks() async {
    final response = await ApiClient.http.get('/tasks');
    if (response.statusCode != 200) {
      throw Exception('Failed to load tasks: ${response.body}');
    }

    final List<dynamic> body = jsonDecode(response.body);
    return body.map((taskJson) => Task.fromJson(taskJson)).toList();
  }

  Future<Task?> getTaskById({
    required int taskId,
    DateTime? updatedAt,
    DateTime? activityLogLastModified,
    DateTime? assigneeLastAdded,
  }) async {
    final queryParams = <String, String>{};
    if (updatedAt != null) {
      queryParams['updatedAt'] = updatedAt.toIso8601String();
    }
    if (activityLogLastModified != null) {
      queryParams['activityLogLastModified'] =
          activityLogLastModified.toIso8601String();
    }
    if (assigneeLastAdded != null) {
      queryParams['assigneeLastAdded'] = assigneeLastAdded.toIso8601String();
    }

    final uri = Uri(
      path: '/tasks/$taskId',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await ApiClient.http.get(uri.toString());

    if (response.statusCode == 204) {
      return null; // Up to date
    } else if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch task: ${response.body}');
    }
  }

  /// GET /tasks/me — fetch all tasks assigned to current user
  Future<List<Task>> fetchMyTasks() async {
    final response = await ApiClient.http.get('/tasks/me');
    if (response.statusCode != 200) {
      throw Exception('Failed to load my tasks: ${response.body}');
    }

    final List<dynamic> body = jsonDecode(response.body);
    return body.map((taskJson) => Task.fromJson(taskJson)).toList();
  }

  /// GET /tasks/:projectId — fetch all tasks for a specific project
  Future<List<Task>> getTasksByProject(
    String projectId, {
    DateTime? since,
  }) async {
    final response = await ApiClient.http.get(
      '/tasks/project/$projectId${since != null ? '?since=$since' : ''}',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch tasks: ${response.body}');
    }

    final List<dynamic> body = jsonDecode(response.body);

    return body.map((e) => Task.fromJson(e)).toList();
  }

  Future<DateTime?> getProjectTasksLastModified(String projectId) async {
    // Optional endpoint like: GET /tasks/:projectId/last-modified
    final response = await ApiClient.http.get(
      '/tasks/$projectId/last-modified',
    );
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    return body['lastModified'] != null
        ? DateTime.parse(body['lastModified'])
        : null;
  }

  /// GET /tasks/active — get the current active task for the user
  Future<Task?> fetchActiveTask() async {
    final response = await ApiClient.http.get('/tasks/active');
    if (response.statusCode == 404) return null;

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch active task: ${response.body}');
    }

    print("active task: ${jsonDecode(response.body)}");

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['active'] == null) return null;
    return Task.fromJson(body['active']);
  }

  /// POST /tasks/:taskId/start — start working on a task
  Future<WorkActivityLog> startTask(int taskId) async {
    final response = await ApiClient.http.post(
      '/tasks/$taskId/start',
      body: {"placeholder": "null"},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start task $taskId: ${response.body}');
    }

    return WorkActivityLog.fromJson({
      ...(jsonDecode(response.body))["workActivityLog"],
      "user": {"id": LoginService.currentUser!.id},
      "taskId": {"id": taskId},
    });
  }

  /// POST /tasks/end — stop working on a task (clock out)
  Future<void> endTask({TaskStatus? status, bool isCompleted = false}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status.name;
    if (isCompleted) queryParams['isCompleted'] = 'true';

    final queryString =
        queryParams.isEmpty
            ? ''
            : '?' +
                queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    final response = await ApiClient.http.post(
      '/tasks/end$queryString',
      body: {"placeholder": "null"},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to end task: ${response.body}');
    }
  }

  Future<List<Task>> getProductionScheduleToday() async {

    final response = await ApiClient.http.get(
      '/tasks/production/today',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch production schedule for today: ${response.body}');
    }

    final todayTasks = ((jsonDecode(response.body) as Map)["tasks"] as List).map((task) {
      return Task.fromJson(task);
    }).toList();

    return todayTasks;
  }

  Future<void> assignPrinter(int taskId, String printerId) async {
    final response = await ApiClient.http.get(
      '/tasks/$taskId/assign-printer',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to assign printer to print job. Please try again.');
    }

    // Successfully assigned priner to task and started print job
  }

  Future<void> unassignPrinter(int taskId) async {
    final response = await ApiClient.http.get(
      '/tasks/$taskId/assign-printer',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unassign printer to print job');
    }

    // Successfully unasssigned priner to task and ended print job
  }
}
