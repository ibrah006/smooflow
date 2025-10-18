import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';
import 'package:smooflow/data/fetch_with_timeout_retry.dart';
import 'package:smooflow/enums/login_status.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:smooflow/models/user.dart';

class LoginService {
  static User? currentUser;

  static Future<LoginStatus> login({
    required String email,
    required String password,
  }) async {
    final response = await fetchWithTimeoutAndRetry(
      methodCall: ApiClient.http.post,
      url: ApiEndpoints.login,
      body: {"email": email, "password": password},
    );

    if (response == null) {
      throw "Server Down, Failed to Login";
    }

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

    try {
      await prefs.setString(
        SharedStorageOptions.organizationId.name,
        user.organizationId,
      );
    } catch (e) {
      // Not part of any organization yet

      await prefs.remove(SharedStorageOptions.organizationId.name);

      if (response.statusCode == 200) {
        return LoginStatus.noOrganization;
      }
    }

    return response.statusCode == 200
        ? LoginStatus.success
        : LoginStatus.failed;
  }

  // static Future<void> logout() async {
  //   final response = await ApiClient.http.post(ApiEndpoints.logout);

  //   if (response)

  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove(SharedStorageOptions.jwtToken.name);

  //   await prefs.remove(SharedStorageOptions.uuid.name);
  //   await prefs.remove(SharedStorageOptions.displayName.name);
  //   await prefs.remove(SharedStorageOptions.email.name);
  //   await prefs.remove(SharedStorageOptions.userRole.name);
  // }

  static Future<void> register({
    required User user,
    required String password,
  }) async {
    final response = await fetchWithTimeoutAndRetry(
      methodCall: ApiClient.http.post,
      url: ApiEndpoints.register,
      body: {...user.toJson(), "password": password},
    );

    if (response == null) {
      throw "Server Down, Failed to Register";
    }

    final userRaw = (jsonDecode(response.body) as Map)["user"];

    user.id = userRaw["id"];
    user.createdAt = DateTime.parse(userRaw["createdAt"]);

    currentUser = user;
  }

  static Future<bool> isLoggedIn() async {
    try {
      final response = await fetchWithTimeoutAndRetry(
        methodCall: ApiClient.http.get,
        url: ApiEndpoints.getCurrentUserInfo,
      );

      if (response?.statusCode != 200) {
        return false;
      }

      final userRaw = (jsonDecode(response!.body) as Map)["user"];

      currentUser = User.fromJson(userRaw);

      return response.statusCode == 200;
    } catch (e) {
      throw "Error caught: $e";
    }
  }
}
