import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:smooflow/models/user.dart';

class LoginService {
  static User? currentUser;

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.login,
      body: {"email": email, "password": password},
    );

    final body = jsonDecode(response.body);

    final userRaw = (body as Map)["user"];

    currentUser = User.fromJson(userRaw);

    print("response code: ${response.statusCode}, body: ${response.body}");

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedStorageOptions.jwtToken.name, body["token"]);

    final user = User.fromJson(body["user"]);
    await prefs.setString(SharedStorageOptions.uuid.name, user.id);
    await prefs.setString(SharedStorageOptions.displayName.name, user.name);
    await prefs.setString(SharedStorageOptions.email.name, user.email);
    await prefs.setString(SharedStorageOptions.userRole.name, user.role);

    return response.statusCode == 200;
  }

  static Future<void> register({
    required User user,
    required String password,
  }) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.register,
      body: {...user.toJson(), "password": password},
    );

    final userRaw = (jsonDecode(response.body) as Map)["user"];

    user.id = userRaw["id"];
    user.createdAt = DateTime.parse(userRaw["createdAt"]);

    currentUser = user;

    if (response.statusCode != 200) {
      throw "Error registering user in:\n${response.body}\n";
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final response = await ApiClient.http.get(
        ApiEndpoints.getCurrentUserInfo,
      );

      if (response.statusCode != 200) {
        return false;
      }

      final userRaw = (jsonDecode(response.body) as Map)["user"];

      currentUser = User.fromJson(userRaw);

      print("status code: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("error: $e");
      throw "Error caught: $e";
    }
  }
}
