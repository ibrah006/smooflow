import 'user.dart';
import 'project.dart';
import 'company.dart';

class Organization {
  final String id;
  final String name;
  final String? description;
  final String createdById;
  final List<String> users;
  final List<String> projects;
  final List<String> companies;
  final DateTime createdAt;
  final DateTime updatedAt;
  // if the organization owns a custom domain
  final bool isDomainOwner;
  final String? privateDomain;

  Organization({
    required this.id,
    required this.name,
    this.description,
    required this.createdById,
    required this.users,
    required this.projects,
    required this.companies,
    required this.createdAt,
    required this.updatedAt,
    required this.isDomainOwner,
    required this.privateDomain,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdById: User.getIdFromJson(json['createdBy'])!,
      users:
          (json['users'] as List<dynamic>)
              .map((userJson) => User.getIdFromJson(userJson)!)
              .toList(),
      projects:
          (json['projects'] as List<dynamic>)
              .map((projJson) => Project.getIdFromJson(projJson))
              .toList(),
      companies:
          ((json['companies'] as List<dynamic>?)?.map(
                    (compJson) => Company.getIdFromJson(compJson),
                  ) ??
                  [])
              .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isDomainOwner: json['isDomainOwner'],
      privateDomain: json['privateDomain'],
    );
  }

  static String getIdFromJson(Map<String, dynamic> orgJson) {
    return orgJson["id"];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdById': createdById,
      'users': users,
      'projects': projects,
      'companies': companies,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // isDomainOwner and privateDomain don't need to be passed in here as they are only updated from server as of now
    };
  }
}
