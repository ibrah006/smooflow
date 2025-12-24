// lib/models/printer.dart
// enum PrinterStatus { active, offline, maintenance, error }

enum JobStatus { waiting, printing, completed, paused, delayed, blocked }

enum JobPriority { low, medium, high, urgent }

enum BlockedReason { materials, files, designApproval, other }

enum PrinterStatus {
  active,
  maintenance,
  offline,
  error;

  static PrinterStatus fromString(String value) {
    return PrinterStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PrinterStatus.active,
    );
  }
}

class Printer {
  final String id;
  final String name;
  final String nickname;
  final String? location;
  final PrinterStatus status;
  final double? maxWidth;
  final double? printSpeed;
  final DateTime createdAt;
  final String? currentJobId;
  final int workMinutes;

  Printer({
    required this.id,
    required this.name,
    required this.nickname,
    this.location,
    required this.status,
    this.maxWidth,
    this.printSpeed,
    required this.createdAt,
    this.currentJobId,
    required this.workMinutes
  });

  factory Printer.fromJson(Map<String, dynamic> json) {
    return Printer(
      id: json['id'],
      name: json['name'],
      nickname: json['nickname'],
      location: json['location'],
      status: PrinterStatus.values.byName(json['status']),
      maxWidth: (json['maxWidth'] as num?)?.toDouble(),
      printSpeed: (json['printSpeed'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      currentJobId: json['currentTaskId'],
      workMinutes: json['workMinutes']
    );
  }

  bool get isActive=> status == PrinterStatus.active;

  String get statusName=> "${status.name[0].toUpperCase()}${status.name.substring(1)}";

  Map<String, dynamic> toJson() {
    // DO NOT PASS IN workMinutes - the value is updated only from server
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'location': location,
      'status': status.name,
      'maxWidth': maxWidth,
      'printSpeed': printSpeed,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PrintJob {
  final String id;
  final String name;
  final String projectId;
  final String printerId;
  final String materialType;
  final int quantity;
  final JobStatus status;
  final JobPriority priority;
  final DateTime deadline;
  final int estimatedDurationMinutes;
  final int? actualDurationMinutes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final BlockedReason? blockedReason;
  final String? blockedNote;
  final Map<String, int>? materialUsage;
  final int queuePosition;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrintJob({
    required this.id,
    required this.name,
    required this.projectId,
    required this.printerId,
    required this.materialType,
    required this.quantity,
    required this.status,
    required this.priority,
    required this.deadline,
    required this.estimatedDurationMinutes,
    this.actualDurationMinutes,
    this.startedAt,
    this.completedAt,
    this.blockedReason,
    this.blockedNote,
    this.materialUsage,
    required this.queuePosition,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'projectId': projectId,
    'printerId': printerId,
    'materialType': materialType,
    'quantity': quantity,
    'status': status.toString().split('.').last,
    'priority': priority.toString().split('.').last,
    'deadline': deadline.toIso8601String(),
    'estimatedDurationMinutes': estimatedDurationMinutes,
    'actualDurationMinutes': actualDurationMinutes,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'blockedReason': blockedReason?.toString().split('.').last,
    'blockedNote': blockedNote,
    'materialUsage': materialUsage,
    'queuePosition': queuePosition,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PrintJob.fromJson(Map<String, dynamic> json) => PrintJob(
    id: json['id'],
    name: json['name'],
    projectId: json['projectId'],
    printerId: json['printerId'],
    materialType: json['materialType'],
    quantity: json['quantity'],
    status: JobStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json['status'],
    ),
    priority: JobPriority.values.firstWhere(
      (e) => e.toString().split('.').last == json['priority'],
    ),
    deadline: DateTime.parse(json['deadline']),
    estimatedDurationMinutes: json['estimatedDurationMinutes'],
    actualDurationMinutes: json['actualDurationMinutes'],
    startedAt:
        json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
    completedAt:
        json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
    blockedReason:
        json['blockedReason'] != null
            ? BlockedReason.values.firstWhere(
              (e) => e.toString().split('.').last == json['blockedReason'],
            )
            : null,
    blockedNote: json['blockedNote'],
    materialUsage:
        json['materialUsage'] != null
            ? Map<String, int>.from(json['materialUsage'])
            : null,
    queuePosition: json['queuePosition'],
    createdBy: json['createdBy'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  PrintJob copyWith({
    String? id,
    String? name,
    String? projectId,
    String? printerId,
    String? materialType,
    int? quantity,
    JobStatus? status,
    JobPriority? priority,
    DateTime? deadline,
    int? estimatedDurationMinutes,
    int? actualDurationMinutes,
    DateTime? startedAt,
    DateTime? completedAt,
    BlockedReason? blockedReason,
    String? blockedNote,
    Map<String, int>? materialUsage,
    int? queuePosition,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PrintJob(
    id: id ?? this.id,
    name: name ?? this.name,
    projectId: projectId ?? this.projectId,
    printerId: printerId ?? this.printerId,
    materialType: materialType ?? this.materialType,
    quantity: quantity ?? this.quantity,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    deadline: deadline ?? this.deadline,
    estimatedDurationMinutes:
        estimatedDurationMinutes ?? this.estimatedDurationMinutes,
    actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    blockedReason: blockedReason ?? this.blockedReason,
    blockedNote: blockedNote ?? this.blockedNote,
    materialUsage: materialUsage ?? this.materialUsage,
    queuePosition: queuePosition ?? this.queuePosition,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  // Helper getters
  bool get isOverdue =>
      DateTime.now().isAfter(deadline) && status != JobStatus.completed;
  bool get isBlocked => status == JobStatus.blocked;
  int get remainingMinutes =>
      estimatedDurationMinutes - (actualDurationMinutes ?? 0);
}
