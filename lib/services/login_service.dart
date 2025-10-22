import 'dart:convert';

import 'package:googleapis/cloudresourcemanager/v3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';
import 'package:smooflow/data/fetch_with_timeout_retry.dart';
import 'package:smooflow/enums/login_status.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:smooflow/models/user.dart';

class LoginService {
  static User? currentUser;

  /// re-login is meant to run properly when user is already part of an organization
  /// As the core idea this was developed, was to sign JWT token with organizationId
  static Future<LoginStatus> relogin() async {
    try {
      final response = await ApiClient.http.post(
        ApiEndpoints.relogin,
        body: {"placeholder": "null"},
      );

      if (response.statusCode != 200) {
        // Failed re-logging user in
        return LoginStatus.failed;
      }

      // Will throw late initialization if user is not part of any organization yet
      final orgId = LoginService.currentUser!.organizationId;

      final prefs = await SharedPreferences.getInstance();

      // User corresponds to an Organization, just not saved in shared preferences yet
      await prefs.setString(SharedStorageOptions.organizationId.name, orgId);
      await prefs.setString(
        SharedStorageOptions.jwtToken.name,
        jsonDecode(response.body)["token"],
      );

      return LoginStatus.success;
    } catch (e) {
      // Not part of any organization
      throw "User is not part of any organization";
    }
  }

  static Future<LoginStatus> login({
    required String email,
    required String? password,
  }) async {
    final response = await fetchWithTimeoutAndRetry(
      methodCall: ApiClient.http.post,
      url: ApiEndpoints.login,
      body: {"email": email, "password": password},
    );

    if (response == null) {
      throw "Server Down, Failed to Login";
    }

    if (response.statusCode != 200) {
      throw "Invalid Credentials";
    }

    final body = jsonDecode(response.body);

    final userRaw = (body as Map)["user"];

    currentUser = User.fromJson(userRaw);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedStorageOptions.jwtToken.name, body["token"]);

    final user = User.fromJson(body["user"]);
    await prefs.setString(SharedStorageOptions.uuid.name, user.id);
    await prefs.setString(SharedStorageOptions.displayName.name, user.name);
    await prefs.setString(SharedStorageOptions.email.name, user.email);
    await prefs.setString(SharedStorageOptions.userRole.name, user.role);

    try {
      print("user organization: ${user.organizationId}");
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

  static Future<IsLoggedInStatus> isLoggedIn() async {
    try {
      final response = await fetchWithTimeoutAndRetry(
        methodCall: ApiClient.http.get,
        url: ApiEndpoints.getCurrentUserInfo,
      );

      if (response?.statusCode != 200) {
        return IsLoggedInStatus(loginStatus: LoginStatus.failed);
      }

      final body = (jsonDecode(response!.body) as Map);
      final userRaw = body["user"];

      currentUser = User.fromJson(userRaw);

      final autoInviteOrganizationRaw = body['autoInviteOrganization'];

      if (autoInviteOrganizationRaw != null) {
        return IsLoggedInStatus(
          loginStatus: LoginStatus.noOrganization,
          autoInviteOrganization: Organization.fromJson(
            autoInviteOrganizationRaw,
          ),
        );
      }

      return IsLoggedInStatus(loginStatus: LoginStatus.success);
    } catch (e) {
      throw "Error caught: $e";
    }
  }
}

/// [autoInviteOrganization] != null only when [loginStatus] == [LoginStatus.noOrganization]
class IsLoggedInStatus {
  final Organization? autoInviteOrganization;
  final LoginStatus loginStatus;
  IsLoggedInStatus({required this.loginStatus, this.autoInviteOrganization}) {
    if (autoInviteOrganization != null &&
        loginStatus != LoginStatus.noOrganization) {
      throw "autoInviteOrganization can only be passed in (!= null) when loginStatus == LoginStatus.noOrganization";
    }
  }
}
