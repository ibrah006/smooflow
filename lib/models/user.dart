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
  late final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.phone,
    this.departmentId,
    required this.createdAt,
  });

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

  User.register({required this.name, required this.role, required this.email})
    : departmentId = null,
      phone = null;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    role: json['role'],
    email: json['email'],
    phone: json['phone'],
    departmentId: json['departmentId'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  static String getIdFromJson(userJson) {
    return userJson["id"];
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
    } catch (e) {
      // Can't return with ID because ID isn't initialized yet
      debugPrint(
        "Warning WA01: Can't return with ID from User.toJson() because ID isn't initialized yet. Possibly because this is a new user. This can be ignored",
      );
    }

    try {
      json["createdAt"] = createdAt.toIso8601String();
    } catch (e) {
      // Can't return with ID because ID isn't initialized yet
      debugPrint(
        "Warning WA01: Can't return with createdAt from User.toJson() because createdAt isn't initialized yet. Possibly because this is a new user. This can be ignored",
      );
    }

    return json;
  }
}
