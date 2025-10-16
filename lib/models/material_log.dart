import 'package:smooflow/models/task.dart';
import 'package:smooflow/models/user.dart';

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
  final User loggedBy;
  final int? taskId;
  final DateTime dateCreated;
  final MaterialLogType type;

  MaterialLog({
    required this.id,
    required this.description,
    required this.quantity,
    required this.width,
    required this.height,
    required this.loggedBy,
    this.taskId,
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
      loggedBy: User.fromJson(json['loggedBy']),
      taskId: json['task'] != null ? Task.getIdFromJson(json['task']) : null,
      dateCreated: DateTime.parse(json['dateCreated']),
      type: MaterialLogTypeExtension.fromString(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'width': width,
      'height': height,
      'loggedBy': loggedBy.toJson(),
      'task': {"id": taskId},
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
