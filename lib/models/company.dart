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
  final String createdByUserId;
  final List<String> projects;

  final bool _isSample; // private flag for sample data

  // Sample data check
  bool get isSample => _isSample;

  Company({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.createdByUserId,
    required this.projects,
  }) : _isSample = false;

  Company.create({required this.name, required this.description})
    : id = Uuid().v1(),
      isActive = true,
      createdByUserId = LoginService.currentUser!.id,
      projects = [],
      _isSample = false;

  // Sample constructor
  Company.sample()
    : id = 'sample-company-id',
      name = 'Sample Company',
      description = 'This is a sample company for demo/testing purposes.',
      isActive = true,
      createdAt = DateTime.now(),
      createdByUserId = "SAMPLE",
      projects = [],
      _isSample = true;

  static String getIdFromJson(Map<String, dynamic> companyJson) {
    return companyJson["id"];
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      createdByUserId: User.getIdFromJson(json['createdBy']),
      projects:
          ((json['projects'] ?? []) as List<dynamic>)
              .map((projectJson) => Project.getIdFromJson(projectJson))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdBy': createdByUserId,
      'projects': projects,
    };
  }
}
