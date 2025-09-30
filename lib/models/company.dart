import 'package:smooflow/services/login_service.dart';
import 'package:uuid/uuid.dart';

import 'user.dart';
import 'project.dart';

class Company {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  late final DateTime createdAt;
  final User createdBy;
  final List<Project> projects;

  Company({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    required this.projects,
  });

  Company.create({required this.name, required this.description})
    : id = Uuid().v1(),
      isActive = true,
      createdBy = LoginService.currentUser!,
      projects = [];

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: User.fromJson(json['createdBy']),
      projects:
          ((json['projects'] ?? []) as List<dynamic>)
              .map((projectJson) => Project.fromJson(projectJson))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdBy': createdBy.toJson(),
      'projects': projects.map((p) => p.toJson()).toList(),
    };
  }
}
