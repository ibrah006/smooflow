// Minimal version of USER class for simplicity, but not used for current user
class Member {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final List<int> activeTasks;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.activeTasks
  });

  // Factory constructor for creating a User from JSON
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      // TODO: implement this in backend
      activeTasks: []
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}
