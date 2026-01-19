import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/user.dart';
import 'package:smooflow/core/services/login_service.dart';

enum MaterialLogType { added, removed, transferred }

MaterialLogType materialLogTypeFromString(String type) {
  return MaterialLogType.values.firstWhere(
    (e) => e.name.toLowerCase() == type.toLowerCase(),
    orElse: () => throw ArgumentError('Invalid MaterialLogType: $type'),
  );
}

String materialLogTypeToString(MaterialLogType type) => type.name;

class MaterialLog {
  final int id;
  final String description;
  final int quantity;
  final double width;
  final double height;
  final String loggedById;
  final String? projectId;
  final DateTime dateCreated;
  @Deprecated(
    "This is deprecated and is planned to be removed in future versions as this isn't having any function in the latest app",
  )
  final MaterialLogType type;

  MaterialLog({
    required this.id,
    required this.description,
    required this.quantity,
    required this.width,
    required this.height,
    required this.loggedById,
    this.projectId,
    required this.dateCreated,
    required this.type,
  });

  factory MaterialLog.fromJson(Map<String, dynamic> json) {
    return MaterialLog(
      id: json['id'],
      description: json['description'],
      quantity: json['quantity'],
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      loggedById: User.getIdFromJson(json['loggedBy']),
      projectId:
          json['task'] != null ? Project.getIdFromJson(json['task']) : null,
      dateCreated: DateTime.parse(json['dateCreated']),
      type: MaterialLogTypeExtension.fromString(json['type']),
    );
  }

  MaterialLog.create({
    required this.description,
    required this.quantity,
    required this.width,
    required this.height,
    required this.projectId,
  }) : id = -1,
       dateCreated = DateTime.now(),
       type = MaterialLogType.added,
       loggedById = LoginService.currentUser!.id;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'width': width,
      'height': height,
      'loggedBy': {"id": loggedById},
      'task': {"id": projectId},
      'dateCreated': dateCreated.toIso8601String(),
      'type': type.name,
    };
  }
}

extension MaterialLogTypeExtension on MaterialLogType {
  static MaterialLogType fromString(String type) {
    return MaterialLogType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => MaterialLogType.added, // default fallback
    );
  }
}
