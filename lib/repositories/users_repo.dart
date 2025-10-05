import 'dart:convert';

import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';
import 'package:smooflow/models/user.dart';

class UsersRepo {
  static Future<List<User>> getUsers() async {
    final response = await ApiClient.http.get(ApiEndpoints.getUsers);

    if (response.statusCode != 200) {
      throw "Failed to fetch Users";
    }

    return (jsonDecode(response.body) as List)
        .map((userJson) => User.fromJson(userJson))
        .toList();
  }
}
