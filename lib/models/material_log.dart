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
  final String itemId;
  final double measure;
  final User loggedBy;
  final Task? task;
  final DateTime datetime;
  final MaterialLogType type;

  MaterialLog({
    required this.id,
    required this.itemId,
    required this.measure,
    required this.loggedBy,
    this.task,
    required this.datetime,
    required this.type,
  });

  factory MaterialLog.fromJson(Map<String, dynamic> json) {
    return MaterialLog(
      id: json['id'],
      itemId: json['itemId'],
      measure: (json['measure'] as num).toDouble(),
      loggedBy: User.fromJson(json['loggedBy']),
      task: json['task'] != null ? Task.fromJson(json['task']) : null,
      datetime: DateTime.parse(json['datetime']),
      type: materialLogTypeFromString(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'measure': measure,
      'loggedBy': loggedBy.toJson(),
      'task': task?.toJson(),
      'datetime': datetime.toIso8601String(),
      'type': materialLogTypeToString(type),
    };
  }
}
