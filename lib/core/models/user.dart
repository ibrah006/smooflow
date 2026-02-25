// import 'package:workflow/core/api/local_http.dart';R
// import 'package:workflow/core/enums/shared_storage_options.dart';

import 'package:flutter/cupertino.dart';

class User {
  late final String id;
  final String name;
  final String role;
  final String email;
  final int? phone;
  final String? departmentId; // Reference to Team
  @Deprecated("Will be removed in future versions")
  late final DateTime? createdAt;
  // Set once, the user joins/creates an organization
  late final String organizationId;

  User({
    required String? userId,
    required this.name,
    required this.role,
    required this.email,
    this.phone,
    this.departmentId,
    required this.createdAt,
    required String? userOrganizationId,
  }) {
    if (userId != null) {
      id = userId;
    }
    if (userOrganizationId != null) organizationId = userOrganizationId;
  }

  bool get isAdmin => role.toLowerCase() == 'admin';

  // To ensure toSet gives no duplicates
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;
  @override
  int get hashCode => id.hashCode;

  // User.currentUser()
  //     : id = LocalHttp.prefs.get(SharedStorageOptions.uuid.name).toString(),
  //       email = LocalHttp.prefs.get(SharedStorageOptions.email.name).toString(),
  //       name = LocalHttp.prefs
  //           .get(SharedStorageOptions.displayName.name)
  //           .toString(),
  //       role =
  //           LocalHttp.prefs.get(SharedStorageOptions.userRole.name).toString();

  // Display Name
  String get displayName => name[0].toUpperCase() + name.substring(1);
  String get initials {
    final splitted = name.split(" ");

    String result = "";

    while(splitted.isNotEmpty && result.length < 4) {
      result += splitted[0][0].toUpperCase();
      splitted.removeAt(0);
    }

    return result;
  }

  String get nameShort {
    final n = name.split(" ");
    return n.length > 1? "${n[0]} ${n[1][0]}." : name;
  }

  User.register({required this.name, required this.role, required this.email})
    : departmentId = null,
      phone = null;

  factory User.fromJson(Map<String, dynamic> json) {
    late final userId;
    try {
      json['id']!;
      userId = json['id'];
    } catch (e) {
      userId = null;
    }

    late final userOrganizationId;
    try {
      json['organization']!;
      userOrganizationId = json['organization']['id'];
    } catch (e) {
      userOrganizationId = null;
    }

    return User(
      userId: userId,
      name: json['name'],
      role: json['role'],
      email: json['email'],
      phone: json['phone'],
      departmentId: json['departmentId'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      userOrganizationId: userOrganizationId,
    );
  }

  static String? getIdFromJson(userJson) {
    try {
      return userJson["id"];
    }catch(e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
      'department': {"id": departmentId},
    };

    try {
      json["id"] = id;
      json["organization"] = {"id": organizationId};
    } catch (e) {
      // Can't return with ID because ID isn't initialized yet
      debugPrint(
        "Warning WA01: Can't return with ID from User.toJson() because ID isn't initialized yet. Possibly because this is a new user. This can be ignored",
      );
    }

    try {
      json["createdAt"] = createdAt?.toIso8601String();
    } catch (e) {
      // Can't return with ID because ID isn't initialized yet
      debugPrint(
        "Warning WA01: Can't return with createdAt from User.toJson() because createdAt isn't initialized yet. Possibly because this is a new user. This can be ignored",
      );
    }

    return json;
  }
}
