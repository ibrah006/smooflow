import 'dart:convert';
import 'package:smooflow/models/user.dart';
import 'package:smooflow/api/api_client.dart';

class UserRepo {
  /// Fetch all users assigned to a specific task
  /// If [addedSince] is provided, only returns assignees if they were added after that timestamp.
  Future<List<User>> getUsersByTask({
    required int taskId,
    DateTime? addedSince,
  }) async {
    final uri =
        addedSince != null
            ? '/users/task/$taskId?addedSince=${addedSince.toIso8601String()}'
            : '/users/task/$taskId';

    final response = await ApiClient.http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch users for task $taskId: ${response.body}',
      );
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => User.fromJson(json)).toList();
  }
}
