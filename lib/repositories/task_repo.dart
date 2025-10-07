import 'dart:convert';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/models/task.dart';

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

  /// GET /tasks/me — fetch all tasks assigned to current user
  Future<List<Task>> fetchMyTasks() async {
    final response = await ApiClient.http.get('/tasks/me');
    if (response.statusCode != 200) {
      throw Exception('Failed to load my tasks: ${response.body}');
    }

    final List<dynamic> body = jsonDecode(response.body);
    return body.map((taskJson) => Task.fromJson(taskJson)).toList();
  }

  /// GET /tasks/active — get the current active task for the user
  Future<Task?> fetchActiveTask() async {
    final response = await ApiClient.http.get('/tasks/active');
    if (response.statusCode == 404) return null;

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch active task: ${response.body}');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['active'] == null) return null;
    return Task.fromJson(body['active']);
  }

  /// POST /tasks/:taskId/start — start working on a task
  Future<void> startTask(int taskId) async {
    final response = await ApiClient.http.post('/tasks/$taskId/start');

    if (response.statusCode != 200) {
      throw Exception('Failed to start task $taskId: ${response.body}');
    }
  }

  /// POST /tasks/end — stop working on a task (clock out)
  Future<void> endTask({String? status, bool isCompleted = false}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (isCompleted) queryParams['isCompleted'] = 'true';

    final queryString =
        queryParams.isEmpty
            ? ''
            : '?' +
                queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    final response = await ApiClient.http.post('/tasks/end$queryString');

    if (response.statusCode != 200) {
      throw Exception('Failed to end task: ${response.body}');
    }
  }
}
