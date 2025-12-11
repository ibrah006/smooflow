import 'package:flutter/widgets.dart';
import 'package:smooflow/models/material_log.dart';
import 'package:smooflow/models/user.dart';
import 'package:smooflow/models/work_activity_log.dart';

class Task {
  late final int _id;
  late String _name;
  late String _description;
  late DateTime? _dueDate;
  late Duration? _productionDuration;
  late String _printerId;
  late String _materialId;
  late DateTime? _productionStartTime;
  // Ids of work activity logs associated with this task
  List<int> workActivityLogs;
  late int _runs;

  late String _status;
  late List<String> _assignees;
  late String _projectId;

  DateTime? _dateCompleted;

  Color? _color;
  IconData? _icon;

  final List<String> progressLogIds;

  DateTime? updatedAt;

  DateTime? activityLogLastModified;

  DateTime? assigneeLastAdded;

  // Constructor to initialize values
  Task({
    required int id,
    required String name,
    required this.progressLogIds,
    required String description,
    required DateTime? dueDate,
    String status = "pending",
    required List<String> assignees,
    required List<MaterialLog> estimatedMaterials,
    required List<MaterialLog> usedMaterials,
    required String projectId,
    required DateTime? dateCompleted,
    required this.workActivityLogs,
    required this.updatedAt,
    required Duration? productionDuration,
    required String printerId,
    required String? materialId,
    required DateTime? productionStartTime,
    int runs = 1
  }) : _id = id,
       _name = name,
       _description = description,
       _dueDate = dueDate,
       _assignees = assignees,
       _projectId = projectId,
       _dateCompleted = dateCompleted,
       _printerId = printerId,
       _materialId = materialId ?? "",
       _productionStartTime = productionStartTime,
       _runs = runs {
    _status = status.replaceAll(RegExp(r"_"), " ");
    _status = "${_status[0].toUpperCase()}${_status.substring(1)}";
    _productionDuration = productionDuration;
  }

  Task.create({
    required String name,
    required String description,
    required DateTime? dueDate,
    String status = "pending",
    required List<String> assignees,
    List<MaterialLog> estimatedMaterials = const [],
    List<MaterialLog> usedMaterials = const [],
    required String projectId,
    required Duration productionDuration,
    required String printerId,
    required String materialId,
    required DateTime? productionStartTime,
    int runs = 1
  }) : _name = name,
       _description = description,
       _dueDate = dueDate,
       _status = status,
       _assignees = assignees,
       _projectId = projectId,
       updatedAt = DateTime.now(),
       workActivityLogs = [],
       activityLogLastModified = null,
       progressLogIds = [],
       _productionDuration = productionDuration,
       _printerId = printerId,
       _materialId = materialId,
       _productionStartTime = productionStartTime,
       _runs = runs;

  void initializeId(int id) {
    _id = id;
  }

  // Getters (you can add more specific access rules here)
  int get id => _id;
  String get name => _name;
  String get description => _description;
  DateTime? get dueDate => _dueDate;
  String get status => _status;
  // ids of assigned users
  List<String> get assignees => _assignees;
  String get projectId => _projectId;
  DateTime? get dateCompleted => _dateCompleted;
  Color? get color => _color;
  IconData? get icon => _icon;
  int get productionDuration => _productionDuration?.inMinutes ?? 0;
  String get printerId => _printerId;
  String get materialId => _materialId;
  DateTime? get productionStartTime => _productionStartTime;
  int get runs => _runs;

  void addAssignee(String userId) {
    _assignees.add(userId);
    assigneeLastAdded = DateTime.now();
  }

  // Setters (make sure only Task can modify these)
  set status(String newStatus) {
    _status = newStatus.replaceAll(RegExp(r"-"), " ");
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
    progressLogIds: (json["progressLogs"] as List).map((log) => log["id"].toString()).toList(),
    description: json['description'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    updatedAt:
        json["updatedAt"] != null ? DateTime.parse(json["updatedAt"]) : null,
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
          return User.getIdFromJson(assigneeRaw);
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
    productionDuration: json['productionDuration'] != null
        ? Duration(minutes: json['productionDuration'])
        : null,
    printerId: json["printerId"],
    materialId: json["materialId"],
    productionStartTime: json["productionStartTime"] != null
        ? DateTime.parse(json["productionStartTime"])
        : null,
    runs: json["runs"] ?? 1,
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
      progressLogIds = original.progressLogIds,
      workActivityLogs = original.workActivityLogs {
    updatedAt = original.updatedAt;
    String status = original._status;
    _status = status;
    color = original.color;
    icon = original.icon;
    assigneeLastAdded = original.assigneeLastAdded;
    _productionDuration = original._productionDuration;
    _printerId = original._printerId;
    _materialId = original._materialId;
    _productionStartTime = original._productionStartTime;
    _runs = original._runs;
  }

  // This Constructor serves those classes which inherit or use Task model as property, and have initial or at any point, a pointing to a Task that doesn't exist (yet)
  @Deprecated(
    "This constructor is deprecated and will be removed in future versions",
  )
  Task.empty() : progressLogIds = [], workActivityLogs = [];

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
    List<String>? assignees,
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

    return newTask;
  }

  static int getIdFromJson(Map<String, dynamic> taskJson) {
    return taskJson["id"];
  }

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'status': status,
      'assignees': assignees,
      'project': {'id': projectId},
      'dateCompleted': dateCompleted?.toIso8601String(),
      // 'progressLogs': progressLogIds.map((id) => {'id': id}).toList(),
      'estimatedDuration': _productionDuration?.inMinutes,
      'printerId': _printerId,
      'materialId': _materialId,
      'productionStartTime': _productionStartTime?.toIso8601String(),
      'runs': _runs,
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
    _productionDuration = newTask._productionDuration;
    _printerId = newTask._printerId;
    _materialId = newTask._materialId;
    _productionStartTime = newTask._productionStartTime;
    _runs = newTask._runs;
  }
}
