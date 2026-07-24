// lib/core/models/dashboard/admin_overview.dart
import 'package:smooflow/core/models/dashboard/dashboard_models.dart';

class AdminOverview {
  final AdminPipeline pipeline;
  final List<ProjectRiskSummary> projectsAtRisk;
  final AdminPrinters printers;
  final AdminMaterials materials;
  final AdminTeam team;
  final List<ClientSummary> topClients;
  final List<ActivityFeedItem> recentActivity;

  AdminOverview({
    required this.pipeline,
    required this.projectsAtRisk,
    required this.printers,
    required this.materials,
    required this.team,
    required this.topClients,
    required this.recentActivity,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    return AdminOverview(
      pipeline: AdminPipeline.fromJson(
        json['pipeline'] as Map<String, dynamic>,
      ),
      projectsAtRisk:
          ((json['projectsAtRisk'] as List?) ?? [])
              .map(
                (p) => ProjectRiskSummary.fromJson(p as Map<String, dynamic>),
              )
              .toList(),
      printers: AdminPrinters.fromJson(
        json['printers'] as Map<String, dynamic>,
      ),
      materials: AdminMaterials.fromJson(
        json['materials'] as Map<String, dynamic>,
      ),
      team: AdminTeam.fromJson(json['team'] as Map<String, dynamic>),
      topClients:
          ((json['topClients'] as List?) ?? [])
              .map((c) => ClientSummary.fromJson(c as Map<String, dynamic>))
              .toList(),
      recentActivity:
          ((json['recentActivity'] as List?) ?? [])
              .map((a) => ActivityFeedItem.fromJson(a as Map<String, dynamic>))
              .toList(),
    );
  }
}

class AdminPipeline {
  final List<TaskStatusCount> statusCounts;
  final List<TaskStatusCount> attentionCounts;
  final int overdueTaskCount;

  AdminPipeline({
    required this.statusCounts,
    required this.attentionCounts,
    required this.overdueTaskCount,
  });

  factory AdminPipeline.fromJson(Map<String, dynamic> json) {
    return AdminPipeline(
      statusCounts:
          ((json['statusCounts'] as List?) ?? [])
              .map((s) => TaskStatusCount.fromJson(s as Map<String, dynamic>))
              .toList(),
      attentionCounts:
          ((json['attentionCounts'] as List?) ?? [])
              .map((s) => TaskStatusCount.fromJson(s as Map<String, dynamic>))
              .toList(),
      overdueTaskCount: json['overdueTaskCount'] as int? ?? 0,
    );
  }

  int get totalTasks => statusCounts.fold(0, (sum, s) => sum + s.count);
  int get totalAttention => attentionCounts.fold(0, (sum, s) => sum + s.count);
}

class AdminPrinters {
  final List<PrinterSummary> fleet;
  final int activeCount;
  final int offlineOrMaintenanceCount;

  AdminPrinters({
    required this.fleet,
    required this.activeCount,
    required this.offlineOrMaintenanceCount,
  });

  factory AdminPrinters.fromJson(Map<String, dynamic> json) {
    return AdminPrinters(
      fleet:
          ((json['fleet'] as List?) ?? [])
              .map((p) => PrinterSummary.fromJson(p as Map<String, dynamic>))
              .toList(),
      activeCount: json['activeCount'] as int? ?? 0,
      offlineOrMaintenanceCount: json['offlineOrMaintenanceCount'] as int? ?? 0,
    );
  }

  int get totalPrinters => fleet.length;
  int get busyCount => fleet.where((p) => p.currentTaskId != null).length;
}

class AdminMaterials {
  final List<MaterialLowStockSummary> lowStock;
  final List<StockTransactionSummary> recentTransactions;

  AdminMaterials({required this.lowStock, required this.recentTransactions});

  factory AdminMaterials.fromJson(Map<String, dynamic> json) {
    return AdminMaterials(
      lowStock:
          ((json['lowStock'] as List?) ?? [])
              .map(
                (m) =>
                    MaterialLowStockSummary.fromJson(m as Map<String, dynamic>),
              )
              .toList(),
      recentTransactions:
          ((json['recentTransactions'] as List?) ?? [])
              .map(
                (t) =>
                    StockTransactionSummary.fromJson(t as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class AdminTeam {
  final List<AssigneeWorkloadSummary> workload;

  AdminTeam({required this.workload});

  factory AdminTeam.fromJson(Map<String, dynamic> json) {
    return AdminTeam(
      workload:
          ((json['workload'] as List?) ?? [])
              .map(
                (w) =>
                    AssigneeWorkloadSummary.fromJson(w as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  int get totalPeople => workload.length;
  int get totalOpenTasks => workload.fold(0, (sum, w) => sum + w.openTaskCount);
}
