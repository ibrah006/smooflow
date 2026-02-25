import 'package:flutter/widgets.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/helpers/task_component_helper.dart';
import 'package:smooflow/core/models/material_log.dart';
import 'package:smooflow/core/models/user.dart';
import 'package:smooflow/core/models/work_activity_log.dart';

class Task {
  late final int _id;
  late String _name;
  late String _description;
  DateTime? _dueDate;
  int? _productionDuration;
  String? _printerId;
  String? _materialId;
  DateTime? _productionStartTime;
  // Ids of work activity logs associated with this task
  List<int> workActivityLogs;
  int? _runs;
  double? _productionQuantity;
  late final TaskPriority _priority;
  String? _stockTransactionBarcode;

  DateTime? _actualProductionStartTime;
  DateTime? _actualProductionEndTime;

  late TaskStatus _status;
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
    required int? productionDuration,
    required String? printerId,
    required String? materialId,
    required DateTime? productionStartTime,
    int runs = 1,
    required double? productionQuantity,
    required TaskPriority priority,
    required String? stockTransactionBarcode,
    required DateTime? actualProductionStartTime,
    required DateTime? actualProductionEndTime
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
       _runs = runs,
       _productionQuantity = productionQuantity,
       _priority = priority,
       _stockTransactionBarcode = stockTransactionBarcode {
    _status = TaskStatus.values.byName(status);
    _productionDuration = productionDuration;
    _actualProductionStartTime = actualProductionStartTime;
    _actualProductionEndTime = actualProductionEndTime;
  }

  Task.create({
    required String name,
    required String description,
    required DateTime? dueDate,
    TaskStatus status = TaskStatus.designing,
    required List<String> assignees,
    List<MaterialLog> estimatedMaterials = const [],
    List<MaterialLog> usedMaterials = const [],
    required String projectId,
    // required int productionDuration,
    // required String? printerId,
    // required String materialId,
    // required DateTime? productionStartTime,
    // int runs = 1,
    // required double productionQuantity,
    TaskPriority priority = TaskPriority.normal,
    // required String stockTransactionBarcode,
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
       _priority = priority;

  // To ensure toSet gives no duplicates
  @override
  bool operator ==(Object other) {
      return identical(this, other) ||
        other is Task && runtimeType == other.runtimeType && id == other.id;
  }
  @override
  int get hashCode {
    return id.hashCode;
  }

  void initializeId(int id) {
    _id = id;
  }

  // Getters (you can add more specific access rules here)
  int get id => _id;
  String get name => _name;
  String get description => _description;
  DateTime? get dueDate => _dueDate;
  TaskStatus get status => _status;
  String get statusName => "${_status.name[0].toUpperCase()}${_status.name.substring(1)}";
  // ids of assigned users
  List<String> get assignees => _assignees;
  String get projectId => _projectId;
  DateTime? get dateCompleted => _dateCompleted;
  Color? get color => _color;
  IconData? get icon => _icon;
  int get productionDuration => _productionDuration ?? 0;
  String? get printerId => _printerId;
  String? get materialId => _materialId;
  DateTime? get productionStartTime => _productionStartTime;
  DateTime? get actualProductionStartTime => _actualProductionStartTime;
  DateTime? get actualProductionEndTime => _actualProductionEndTime;
  int? get runs => _runs;
  double? get productionQuantity=> _productionQuantity;
  String? get stockTransactionBarcode=> _stockTransactionBarcode;

  TaskPriority get priority => _priority;

  void addAssignee(String userId) {
    _assignees.add(userId);
    assigneeLastAdded = DateTime.now();
  }

  bool get isDeprecated=> printerId != null && status != TaskStatus.printing;

  bool get isInProgress => status == TaskStatus.designing || status == TaskStatus.printing || status == TaskStatus.finishing || status == TaskStatus.installing;

  // Setters (make sure only Task can modify these)
  set status(TaskStatus newStatus) {
    // _status = newStatus.replaceAll(RegExp(r"-"), " ");
    _status = newStatus;

    if (_status == TaskStatus.printing) {
      _actualProductionStartTime = DateTime.now();
    } else if (_status == TaskStatus.completed) {
      _actualProductionEndTime = DateTime.now();
    }
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

  set printerId(String? printerId) {
    _printerId = printerId;
  }

  set materialId(String? materialId) {
    _materialId = materialId;
  }
  
  set actualProductionStartTime(DateTime? productionStartTime) {
    _productionStartTime = productionStartTime;
  }

  set runs(int? runs) {
    _runs = runs;
  }

  set productionQuantity(double? productionQuantity) {
    _productionQuantity = productionQuantity;
  }

  set stockTransactionBarcode(String? stockTransactionBarcode) {
    _stockTransactionBarcode = stockTransactionBarcode;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final prodQuantity = json["stockTransaction"]?["quantity"]?? json["productionQuantity"];
    return Task(
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
            return User.getIdFromJson(assigneeRaw)!;
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
      productionDuration: json['productionDuration'],
      printerId: json["printerId"],
      materialId: json["materialId"],
      productionStartTime: json["productionStartTime"] != null
          ? DateTime.parse(json["productionStartTime"])
          : null,
      runs: json["runs"] ?? 1,
      productionQuantity: prodQuantity!=null? double.parse(prodQuantity) : null,
      priority: TaskPriority.values.elementAt(json["priority"] - 1),
      stockTransactionBarcode: json["stockTransaction"]?["barcode"],
      actualProductionStartTime: json['actualProductionStartTime'] != null
              ? DateTime.parse(json['actualProductionStartTime'])
              : null,
      actualProductionEndTime: json['actualProductionEndTime'] != null
              ? DateTime.parse(json['actualProductionEndTime'])
              : null,
    );
  }

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
    TaskStatus status = original._status;
    _status = status;
    color = original.color;
    icon = original.icon;
    assigneeLastAdded = original.assigneeLastAdded;
    _productionDuration = original._productionDuration;
    _printerId = original._printerId;
    _materialId = original._materialId;
    _productionStartTime = original._productionStartTime;
    _runs = original._runs;
    _productionQuantity = original._productionQuantity;
    _priority = original._priority;
    _stockTransactionBarcode = original._stockTransactionBarcode;
    _actualProductionStartTime = original._actualProductionStartTime;
    _actualProductionEndTime = original._actualProductionEndTime;
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
    TaskStatus? status,
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

  Map<String, dynamic> toCreateJson() {
    return {
      ...toJson(),
      // Inital stage of a Task locked to PRODUCTION
      "progressStage": "design"
    };
  }

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'status': _status.name,
      'assignees': assignees,
      'project': {'id': projectId},
      'dateCompleted': dateCompleted?.toIso8601String(),
      // 'progressLogs': progressLogIds.map((id) => {'id': id}).toList(),
      'estimatedDuration': _productionDuration,
      'printerId': _printerId,
      'materialId': _materialId,
      'productionStartTime': _productionStartTime?.toIso8601String(),
      'runs': _runs,
      'productionQuantity': _productionQuantity,
      'priority': TaskPriority.values.indexOf(_priority),
      'barcode': _stockTransactionBarcode,
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
    _productionQuantity = newTask._productionQuantity;
    _priority = newTask._priority;
    _stockTransactionBarcode = newTask._stockTransactionBarcode;
  }

  /// if [status] is null, it will use the Task's current status to determine the component properties
  TaskComponentHelper componentHelper({TaskStatus? status}) {
    final task = Task.copy(this);
    if (status != null) {
      task.status = status;
    }
    return TaskComponentHelper.get(task);
  }

  Duration get productionDurationElapsed {
    if (updatedAt == null) return Duration.zero;
    return DateTime.now().difference(updatedAt!);
  }
}
