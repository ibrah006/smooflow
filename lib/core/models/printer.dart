// lib/models/printer.dart
// enum PrinterStatus { active, offline, maintenance, error }

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

enum JobStatus { waiting, printing, completed, paused, delayed, blocked }

enum JobPriority { low, medium, high, urgent }

enum BlockedReason { materials, files, designApproval, other }

enum PrinterStatus {
  // NO TWO WORD STATUSES to be specified
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
  PrinterStatus _status;
  final int totalJobsCompleted;

  PrinterStatus get status => _status;

  final double? maxWidth;
  final double? printSpeed;
  final DateTime createdAt;
  late int? _currentJobId;

  int? get currentJobId => _currentJobId;

  /// Assign a job to a printer.
  assignJob({required int jobId}) {
    if (isBusy) {
      throw Exception("Printer is already assigned to a job.");
    }

    _currentJobId = jobId;

    _status = PrinterStatus.active;
  }

  /// Unassign a job from a printer.
  unassignJob() {
    _currentJobId = null;

    _status = PrinterStatus.active;
  }

  final int workMinutes;

  Printer({
    required this.id,
    required this.name,
    required this.nickname,
    this.location,
    required PrinterStatus status,
    this.maxWidth,
    this.printSpeed,
    required this.createdAt,
    int? currentJobId,
    required this.workMinutes,
    required this.totalJobsCompleted
  }) : _currentJobId = currentJobId, _status = status;

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
      workMinutes: json['workMinutes'],
      totalJobsCompleted: (json['tasks'] as List).length,
    );
  }

  bool get isActive=> status == PrinterStatus.active;
  bool get isBusy=> currentJobId!=null;

  bool get isAvailable => isActive && !isBusy;

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

  // Components can use this to determine which icon/color to show for the job status
  String get statusLabel {
    if (!isBusy && isActive) {
      return 'Available';
    } else if (isBusy) {
      return 'Busy';
    } else if (status == PrinterStatus.maintenance) {
      return 'Maintenance';
    } else if (status == PrinterStatus.offline) {
      return 'Offline';
    } else if (status == PrinterStatus.error) {
      return 'Error';
    } else {
      return 'Unknown';
    }
  }

  Color get statusColor {
    if (!isBusy && isActive) {
      return Color(0xFF10B981);
    } else if (isBusy) {
      return Color(0xFF2563EB);
    } else if (status == PrinterStatus.maintenance) {
      return Color(0xFFF59E0B);
    } else if (status == PrinterStatus.offline) {
      return Color(0xFF6B7280);
    } else if (status == PrinterStatus.error) {
      return Color(0xFFEF4444);
    } else {
      return Color(0xFF9CA3AF);
    }
  }

  Color get statusBackgroundColor {
    if (!isBusy && isActive) {
      return Color(0xFFD1FAE5);
    } else if (isBusy) {
      return Color(0xFFEFF6FF);
    } else if (status == PrinterStatus.maintenance) {
      return Color(0xFFFEF3C7);
    } else if (status == PrinterStatus.offline) {
      return Color(0xFF6B7280);
    } else if (status == PrinterStatus.error) {
      return Color(0xFFFEE2E2);
    } else {
      return Color(0xFF9CA3AF);
    }
  }

  IconData get statusIcon {
    if (!isBusy && isActive) {
      return Icons.check_circle;
    } else if (isBusy) {
      return Icons.play_circle_filled;
    } else if (status == PrinterStatus.maintenance) {
      return Icons.build_circle;
    } else if (status == PrinterStatus.offline) {
      return Icons.power_off;
    } else if (status == PrinterStatus.error) {
      return Icons.error_outline;
    } else {
      return Icons.question_mark;
    }
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
