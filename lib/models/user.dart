// import 'package:workflow/core/api/local_http.dart';R
// import 'package:workflow/core/enums/shared_storage_options.dart';

class User {
  late final String id;
  final String name;
  final String role;
  final String email;
  late final int? phone;
  late final String? departmentId; // Reference to Team
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

  // User.currentUser()
  //     : id = LocalHttp.prefs.get(SharedStorageOptions.uuid.name).toString(),
  //       email = LocalHttp.prefs.get(SharedStorageOptions.email.name).toString(),
  //       name = LocalHttp.prefs
  //           .get(SharedStorageOptions.displayName.name)
  //           .toString(),
  //       role =
  //           LocalHttp.prefs.get(SharedStorageOptions.userRole.name).toString();

  User.register({required this.name, required this.role, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    role: json['role'],
    email: json['email'],
    phone: json['phone'],
    departmentId: json['departmentId'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'email': email,
    'phone': phone,
    'departmentId': departmentId,
    'createdAt': createdAt.toIso8601String(),
  };
}
