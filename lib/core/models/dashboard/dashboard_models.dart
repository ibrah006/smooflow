// lib/core/models/dashboard/dashboard_models.dart
//
// Shared summary models used across multiple dashboard sections.
// These are NOT the full Task/Printer/etc. entities — they're lightweight
// projections optimized for dashboard display.

class TaskStatusCount {
  final String status;
  final int count;

  TaskStatusCount({required this.status, required this.count});

  factory TaskStatusCount.fromJson(Map<String, dynamic> json) {
    return TaskStatusCount(
      status: json['status'] as String,
      count: json['count'] as int? ?? 0,
    );
  }
}

class AssigneeSummary {
  final String id;
  final String name;
  final String? colorHex;

  AssigneeSummary({required this.id, required this.name, this.colorHex});

  factory AssigneeSummary.fromJson(Map<String, dynamic> json) {
    return AssigneeSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String?,
    );
  }
}

class TaskSummary {
  final int id;
  final String name;
  final String projectId;
  final String projectName;
  final String status;
  final DateTime? dueDate;
  final int priority;
  final List<AssigneeSummary> assignees;
  final String? printerId;
  final String? printerName;
  final int unreadCount;
  final int messageCount;
  final bool hasCompletePrintSpec;
  final int? productionDuration;
  final DateTime? actualProductionStartTime;
  final DateTime? actualProductionEndTime;
  final int? runs;

  TaskSummary({
    required this.id,
    required this.name,
    required this.projectId,
    required this.projectName,
    required this.status,
    this.dueDate,
    required this.priority,
    required this.assignees,
    this.printerId,
    this.printerName,
    required this.unreadCount,
    required this.messageCount,
    required this.hasCompletePrintSpec,
    this.productionDuration,
    this.actualProductionStartTime,
    this.actualProductionEndTime,
    this.runs,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      status: json['status'] as String,
      dueDate:
          json['dueDate'] != null
              ? DateTime.parse(json['dueDate'] as String)
              : null,
      priority: json['priority'] as int? ?? 0,
      assignees:
          ((json['assignees'] as List?) ?? [])
              .map((a) => AssigneeSummary.fromJson(a as Map<String, dynamic>))
              .toList(),
      printerId: json['printerId'] as String?,
      printerName: json['printerName'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      messageCount: json['messageCount'] as int? ?? 0,
      hasCompletePrintSpec: json['hasCompletePrintSpec'] as bool? ?? false,
      productionDuration: json['productionDuration'] as int?,
      actualProductionStartTime:
          json['actualProductionStartTime'] != null
              ? DateTime.parse(json['actualProductionStartTime'] as String)
              : null,
      actualProductionEndTime:
          json['actualProductionEndTime'] != null
              ? DateTime.parse(json['actualProductionEndTime'] as String)
              : null,
      runs: json['runs'] as int?,
    );
  }
}

class PrinterSummary {
  final String id;
  final String name;
  final String nickname;
  final String status;
  final int? currentTaskId;
  final String? currentTaskName;
  final int workMinutesToday;
  final int scheduledMinutes;
  final int utilizationPct;

  PrinterSummary({
    required this.id,
    required this.name,
    required this.nickname,
    required this.status,
    this.currentTaskId,
    this.currentTaskName,
    required this.workMinutesToday,
    required this.scheduledMinutes,
    required this.utilizationPct,
  });

  factory PrinterSummary.fromJson(Map<String, dynamic> json) {
    return PrinterSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String,
      status: json['status'] as String,
      currentTaskId: json['currentTaskId'] as int?,
      currentTaskName: json['currentTaskName'] as String?,
      workMinutesToday: json['workMinutesToday'] as int? ?? 0,
      scheduledMinutes: json['scheduledMinutes'] as int? ?? 480,
      utilizationPct: json['utilizationPct'] as int? ?? 0,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return currentTaskId != null ? 'Busy' : 'Available';
      case 'maintenance':
        return 'Maintenance';
      case 'offline':
        return 'Offline';
      case 'error':
        return 'Error';
      default:
        return 'Unknown';
    }
  }
}

class MaterialLowStockSummary {
  final String id;
  final String name;
  final double currentStock;
  final double minStockLevel;
  final String measureType;
  final String barcode;

  MaterialLowStockSummary({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.minStockLevel,
    required this.measureType,
    required this.barcode,
  });

  factory MaterialLowStockSummary.fromJson(Map<String, dynamic> json) {
    return MaterialLowStockSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0,
      minStockLevel: (json['minStockLevel'] as num?)?.toDouble() ?? 0,
      measureType: json['measureType'] as String,
      barcode: json['barcode'] as String,
    );
  }

  double get shortfallQty => minStockLevel - currentStock;
}

class StockTransactionSummary {
  final String id;
  final String materialId;
  final String materialName;
  final String type;
  final double quantity;
  final DateTime createdAt;
  final String createdByName;

  StockTransactionSummary({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.type,
    required this.quantity,
    required this.createdAt,
    required this.createdByName,
  });

  factory StockTransactionSummary.fromJson(Map<String, dynamic> json) {
    return StockTransactionSummary(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      materialName: json['materialName'] as String,
      type: json['type'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdByName: json['createdByName'] as String,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'stock_in':
        return 'Stock In';
      case 'stock_out':
        return 'Stock Out';
      case 'adjustment':
        return 'Adjustment';
      default:
        return type;
    }
  }
}

class ProjectRiskSummary {
  final String id;
  final String name;
  final DateTime? dueDate;
  final String clientName;
  final int totalTasks;
  final int completedTasks;
  final int progressPct;

  ProjectRiskSummary({
    required this.id,
    required this.name,
    this.dueDate,
    required this.clientName,
    required this.totalTasks,
    required this.completedTasks,
    required this.progressPct,
  });

  factory ProjectRiskSummary.fromJson(Map<String, dynamic> json) {
    return ProjectRiskSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      dueDate:
          json['dueDate'] != null
              ? DateTime.parse(json['dueDate'] as String)
              : null,
      clientName: json['clientName'] as String,
      totalTasks: json['totalTasks'] as int? ?? 0,
      completedTasks: json['completedTasks'] as int? ?? 0,
      progressPct: json['progressPct'] as int? ?? 0,
    );
  }

  int get remainingTasks => totalTasks - completedTasks;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!);
}

class AssigneeWorkloadSummary {
  final String userId;
  final String name;
  final String? colorHex;
  final int openTaskCount;

  AssigneeWorkloadSummary({
    required this.userId,
    required this.name,
    this.colorHex,
    required this.openTaskCount,
  });

  factory AssigneeWorkloadSummary.fromJson(Map<String, dynamic> json) {
    return AssigneeWorkloadSummary(
      userId: json['userId'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String?,
      openTaskCount: json['openTaskCount'] as int? ?? 0,
    );
  }
}

class ClientSummary {
  final String id;
  final String name;
  final int activeProjectCount;

  ClientSummary({
    required this.id,
    required this.name,
    required this.activeProjectCount,
  });

  factory ClientSummary.fromJson(Map<String, dynamic> json) {
    return ClientSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      activeProjectCount: json['activeProjectCount'] as int? ?? 0,
    );
  }
}

class StatusGroup<T> {
  final String status;
  final List<T> items;

  StatusGroup({required this.status, required this.items});

  factory StatusGroup.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decoder,
  ) {
    return StatusGroup(
      status: json['status'] as String,
      items:
          ((json['tasks'] as List?) ?? [])
              .map((t) => decoder(t as Map<String, dynamic>))
              .toList(),
    );
  }
}

class ActivityFeedItem {
  final int id;
  final String description;
  final int? taskId;
  final String? taskName;
  final String? printerId;
  final String? printerName;
  final DateTime createdAt;

  ActivityFeedItem({
    required this.id,
    required this.description,
    this.taskId,
    this.taskName,
    this.printerId,
    this.printerName,
    required this.createdAt,
  });

  factory ActivityFeedItem.fromJson(Map<String, dynamic> json) {
    return ActivityFeedItem(
      id: json['id'] as int,
      description: json['description'] as String,
      taskId: json['taskId'] as int?,
      taskName: json['taskName'] as String?,
      printerId: json['printerId'] as String?,
      printerName: json['printerName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
