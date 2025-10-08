import 'package:flutter/widgets.dart';
import 'package:smooflow/models/material_log.dart';
import 'package:smooflow/models/user.dart';
import 'package:smooflow/models/work_activity_log.dart';

class Task {
  late final int _id;
  late String _name;
  late String _description;
  late DateTime? _dueDate;

  // Ids of work activity logs associated with this task
  List<int> workActivityLogs;

  late String _status;
  late List<User> _assignees;
  late String _projectId;

  // Material logs
  late List<MaterialLog> _estimatedMaterials;
  late List<MaterialLog> _usedMaterials;

  DateTime? _dateCompleted;

  Color? _color;
  IconData? _icon;

  final String progressLogId;

  DateTime? updatedAt;

  DateTime? activityLogLastModified;

  // Constructor to initialize values
  Task({
    required int id,
    required String name,
    required this.progressLogId,
    required String description,
    required DateTime? dueDate,
    String status = "pending",
    required List<User> assignees,
    required List<MaterialLog> estimatedMaterials,
    required List<MaterialLog> usedMaterials,
    required String projectId,
    required DateTime? dateCompleted,
    required this.workActivityLogs,
  }) : _id = id,
       _name = name,
       _description = description,
       _dueDate = dueDate,
       _assignees = assignees,
       _projectId = projectId,
       _dateCompleted = dateCompleted,
       _estimatedMaterials = estimatedMaterials,
       _usedMaterials = usedMaterials {
    _status = status.replaceAll(RegExp(r"_"), " ");
    _status = "${_status[0].toUpperCase()}${_status.substring(1)}";
    updatedAt = DateTime.now();
    activityLogLastModified = null;
  }

  Task.create({
    required String name,
    required this.progressLogId,
    required String description,
    required DateTime? dueDate,
    String status = "pending",
    required List<User> assignees,
    List<MaterialLog> estimatedMaterials = const [],
    List<MaterialLog> usedMaterials = const [],
    required String projectId,
  }) : _name = name,
       _description = description,
       _dueDate = dueDate,
       _status = status,
       _assignees = assignees,
       _estimatedMaterials = estimatedMaterials,
       _usedMaterials = usedMaterials,
       _projectId = projectId,
       updatedAt = DateTime.now(),
       workActivityLogs = [],
       activityLogLastModified = null;

  void initializeId(int id) {
    _id = id;
  }

  // Getters (you can add more specific access rules here)
  int get id => _id;
  String get name => _name;
  String get description => _description;
  DateTime? get dueDate => _dueDate;
  String get status => _status;
  List<User> get assignees => _assignees;
  String get projectId => _projectId;
  DateTime? get dateCompleted => _dateCompleted;
  Color? get color => _color;
  IconData? get icon => _icon;
  List<MaterialLog> get estimatedMaterials => _estimatedMaterials;
  List<MaterialLog> get usedMaterials => _usedMaterials;

  // Setters (make sure only Task can modify these)
  set status(String newStatus) {
    _status = newStatus.replaceAll(RegExp(r"_"), " ");
    _status = "${_status[0].toUpperCase()}${_status.substring(1)}";
  }

  set dateCompleted(DateTime? newDatetime) {
    _dateCompleted = newDatetime;
  }

  set color(Color? newColor) {
    _color = newColor;
  }

  set icon(IconData? newIcon) {
    _icon = newIcon;
  }

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    name: json['name'],
    progressLogId: json["progressLog"]["id"],
    description: json['description'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    dateCompleted:
        json['dateCompleted'] != null
            ? DateTime.parse(json['dateCompleted'])
            : null,
    // estimatedHours: json['estimatedHours'],
    status: json["status"],
    // TaskStatus.values
    //     .firstWhere((e) => e.toString().split('.').last == json['status']),
    assignees:
        (json['assignees'] as List).map((assigneeRaw) {
          return User.fromJson(assigneeRaw);
        }).toList(),
    projectId: json['project']?['id'],
    // Material logs
    estimatedMaterials:
        ((json["materialsEstimated"] ?? []) as List)
            .map((rawMaterialLog) => MaterialLog.fromJson(rawMaterialLog))
            .toList(),
    usedMaterials:
        ((json["materialsUsed"] ?? []) as List)
            .map((rawMaterialLog) => MaterialLog.fromJson(rawMaterialLog))
            .toList(),
    workActivityLogs:
        (json["workActivityLogs"] as List).map((activityLogJson) {
          return WorkActivityLog.getIdFromJson(activityLogJson);
        }).toList(),
  );

  // Copy constructor
  Task.copy(Task original)
    : _id = original.id,
      _name = original.name,
      _description = original.description,
      _dueDate = original.dueDate,
      _assignees = List.from(original.assignees),
      _projectId = original.projectId,
      _dateCompleted = original._dateCompleted,
      _estimatedMaterials = List.from(original._estimatedMaterials),
      _usedMaterials = List.from(original._usedMaterials),
      progressLogId = original.progressLogId,
      workActivityLogs = original.workActivityLogs {
    updatedAt = original.updatedAt;
    String status = original._status;
    _status = status;
    color = original.color;
    icon = original.icon;
  }

  // This Constructor serves those classes which inherit or use Task model as property, and have initial or at any point, a pointing to a Task that doesn't exist (yet)
  @Deprecated(
    "This constructor is deprecated and will be removed in future versions",
  )
  Task.empty() : progressLogId = "", workActivityLogs = [];

  // Copy With method
  @Deprecated(
    "This constructor is deprecated and will be removed in future versions",
  )
  Task copyWithSafe({
    int? id,
    String? name,
    String? description,
    DateTime? dueDate,
    String? status,
    List<User>? assignees,
    String? projectId,
    DateTime? dateCompleted,
    Color? color,
    IconData? icon,
    List<MaterialLog>? estimatedMaterials,
    List<MaterialLog>? usedMaterials,
  }) {
    final Task newTask = Task.empty();

    try {
      newTask._id = id ?? _id;
    } catch (_) {
      if (id != null) newTask._id = id;
    }

    try {
      newTask._name = name ?? _name;
    } catch (_) {
      if (name != null) newTask._name = name;
    }

    try {
      newTask._description = description ?? _description;
    } catch (_) {
      if (description != null) newTask._description = description;
    }

    try {
      newTask._dueDate = dueDate ?? _dueDate;
    } catch (_) {
      if (dueDate != null) newTask._dueDate = dueDate;
    }

    if (status != null) {
      newTask.status = status;
    } else {
      try {
        newTask.status = _status;
      } catch (_) {}
    }

    try {
      newTask._assignees = assignees ?? _assignees;
    } catch (_) {
      if (assignees != null) newTask._assignees = assignees;
    }

    try {
      newTask._projectId = projectId ?? _projectId;
    } catch (_) {
      if (projectId != null) newTask._projectId = projectId;
    }

    newTask._dateCompleted = dateCompleted ?? _dateCompleted;
    newTask._color = color ?? _color;
    newTask._icon = icon ?? _icon;

    try {
      newTask._estimatedMaterials =
          estimatedMaterials ?? List.from(_estimatedMaterials);
    } catch (_) {
      if (estimatedMaterials != null) {
        newTask._estimatedMaterials = estimatedMaterials;
      }
    }

    try {
      newTask._usedMaterials = usedMaterials ?? List.from(_usedMaterials);
    } catch (_) {
      if (usedMaterials != null) {
        newTask._usedMaterials = usedMaterials;
      }
    }

    return newTask;
  }

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'status': status,
      'assignees': assignees.map((user) => user.id).toList(),
      'project': {'id': projectId},
      'dateCompleted': dateCompleted?.toIso8601String(),
      'estimatedMaterials': _estimatedMaterials.map((m) => m.toJson()).toList(),
      'usedMaterials': _usedMaterials.map((m) => m.toJson()).toList(),
      'progressLog': {'id': progressLogId},
    };
    try {
      return {'id': id, ...json};
    } catch (e) {
      return json;
    }
  }

  // `replaceWith` function to update Task attributes
  void replaceWith(Task newTask) {
    _id = newTask._id;
    _name = newTask._name;
    _description = newTask._description;
    _dueDate = newTask._dueDate;
    _status = newTask._status;
    _assignees = List.from(newTask._assignees);
    _projectId = newTask._projectId;
    _dateCompleted = newTask._dateCompleted;
    _color = newTask._color;
    _icon = newTask._icon;
    _estimatedMaterials = List.from(newTask._estimatedMaterials);
    _usedMaterials = List.from(newTask._usedMaterials);
  }
}
