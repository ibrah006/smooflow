import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/company.dart';

import 'user.dart';

class Project {
  late final String id;
  final String name;
  final String? description;
  String _status;
  final DateTime? dueDate;
  final DateTime? estimatedProductionStart;
  final DateTime? estimatedSiteFixing;
  final List<int> tasks;
  final List<User> assignedManagers;
  final DateTime dateStarted;
  final Company client;
  final int priority;
  // Progress logs' ids
  final List<String> progressLogs;
  // Project's material logs
  final List<int> materialLogs;

  DateTime progressLogLastModifiedAt;

  DateTime? taskLastModifiedAt;

  set status(String newStatus) {
    _status = newStatus;
  }

  String get status => _status;

  // To ensure toSet gives no duplicates
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          id == other.id;
  @override
  int get hashCode => id.hashCode;

  // You can add computed/derived fields here as needed
  // e.g., double? projectEfficiency;

  static String getIdFromJson(Map<String, dynamic> projectJson) {
    return projectJson["id"];
  }

  initializeId(String newId) {
    id = newId;
  }

  Project({
    required this.id,
    required this.name,
    this.description,
    required String status,
    this.dueDate,
    this.estimatedProductionStart,
    this.estimatedSiteFixing,
    required this.tasks,
    required this.assignedManagers,
    required this.dateStarted,
    required this.client,
    required this.priority,
    required this.progressLogs,
    required this.materialLogs,
    required this.progressLogLastModifiedAt,
  }) : _status = status,
       taskLastModifiedAt = null;

  Project.create({
    required this.name,
    this.description,
    // required this.status,
    this.dueDate,
    this.estimatedProductionStart,
    this.estimatedSiteFixing,
    required this.assignedManagers,
    required this.client,
    required this.priority,
  }) : _status = "Pending",
       tasks = [],
       dateStarted = DateTime.now(),
       progressLogs = [],
       progressLogLastModifiedAt = DateTime.now(),
       taskLastModifiedAt = null,
       materialLogs = [];

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: json['status'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      progressLogLastModifiedAt:
          json['progressLogLastModifiedAt'] != null
              ? DateTime.parse(json['progressLogLastModifiedAt'])
              : DateTime.now(),
      estimatedProductionStart:
          json['estimatedProductionStart'] != null
              ? DateTime.parse(json['estimatedProductionStart'])
              : null,
      estimatedSiteFixing:
          json['estimatedSiteFixing'] != null
              ? DateTime.parse(json['estimatedSiteFixing'])
              : null,
      tasks:
          ((json['tasks'] ?? []) as List<dynamic>).map((e) {
            // e["project"] = {"id": json["id"]};
            return e["id"] as int;
          }).toList(),
      assignedManagers:
          ((json['assignedManagers'] ?? []) as List<dynamic>)
              .map((e) => User.fromJson(e))
              .toList(),
      dateStarted: DateTime.parse(json['dateStarted']),
      client: Company.fromJson(json['client']),
      priority: json['priority'],
      progressLogs:
          (json['progressLogs'] as List?)
              ?.map(
                (e) =>
                    // Progress log id
                    e["id"].toString(),
              )
              .toList() ??
          [],
      materialLogs:
          (json['materialLogs'] as List?)
              ?.map(
                (e) =>
                    // Progress log id
                    e["id"] as int,
              )
              .toList() ??
          [],
    );
  }

  // Only create json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'status': _status,
      'dueDate': dueDate?.toIso8601String(),
      'estimatedProductionStart': estimatedProductionStart?.toIso8601String(),
      'estimatedSiteFixing': estimatedSiteFixing?.toIso8601String(),
      'tasks': tasks,
      'assignedManagers':
          assignedManagers.map((manager) => manager.toJson()).toList(),
      // 'dateStarted': dateStarted.toIso8601String(),
      'client': client.toJson(),
      'priority': priority,
      'progressLogs': progressLogs.map((logId) => {"id": logId}).toList(),
    };
  }

  // Only local data
  double progressRate = 0;

  Color get statusColor {
    switch (_status) {
      case "application":
        return colorPrimary;
      case "finished":
        return colorPositiveStatus;
      case "cancelled":
        return colorError;
      default:
        return colorPending;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 0:
        return Colors.black38;
      case 1:
        return colorPrimary;
      default:
        return colorError;
    }
  }
}
