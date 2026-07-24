// lib/core/models/dashboard/production_overview.dart
import 'package:smooflow/core/models/dashboard/dashboard_models.dart';

class ProductionOverview {
  final ProductionPrinters printers;
  final ProductionQueue productionQueue;
  final ProductionLogistics logistics;
  final List<TaskSummary> runsInProgress;
  final ProductionAttention attention;
  final List<TaskSummary> completedToday;

  ProductionOverview({
    required this.printers,
    required this.productionQueue,
    required this.logistics,
    required this.runsInProgress,
    required this.attention,
    required this.completedToday,
  });

  factory ProductionOverview.fromJson(Map<String, dynamic> json) {
    return ProductionOverview(
      printers: ProductionPrinters.fromJson(
        json['printers'] as Map<String, dynamic>,
      ),
      productionQueue: ProductionQueue.fromJson(
        json['productionQueue'] as Map<String, dynamic>,
      ),
      logistics: ProductionLogistics.fromJson(
        json['logistics'] as Map<String, dynamic>,
      ),
      runsInProgress:
          ((json['runsInProgress'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
      attention: ProductionAttention.fromJson(
        json['attention'] as Map<String, dynamic>,
      ),
      completedToday:
          ((json['completedToday'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
    );
  }
}

class ProductionPrinters {
  final List<PrinterSummary> fleet;
  final List<TaskSummary> todaysSchedule;

  ProductionPrinters({required this.fleet, required this.todaysSchedule});

  factory ProductionPrinters.fromJson(Map<String, dynamic> json) {
    return ProductionPrinters(
      fleet:
          ((json['fleet'] as List?) ?? [])
              .map((p) => PrinterSummary.fromJson(p as Map<String, dynamic>))
              .toList(),
      todaysSchedule:
          ((json['todaysSchedule'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
    );
  }

  int get availablePrinterCount =>
      fleet
          .where((p) => p.currentTaskId == null && p.status == 'active')
          .length;
  int get busyPrinterCount =>
      fleet.where((p) => p.currentTaskId != null).length;
}

class ProductionQueue {
  final List<StatusGroup<TaskSummary>> statusGroups;

  ProductionQueue({required this.statusGroups});

  factory ProductionQueue.fromJson(Map<String, dynamic> json) {
    return ProductionQueue(
      statusGroups:
          ((json['statusGroups'] as List?) ?? [])
              .map(
                (sg) => StatusGroup.fromJson(
                  sg as Map<String, dynamic>,
                  (t) => TaskSummary.fromJson(t),
                ),
              )
              .toList(),
    );
  }

  int get totalQueuedTasks =>
      statusGroups.fold(0, (sum, sg) => sum + sg.items.length);

  /// Tasks waiting for printing
  int get waitingForPrintCount {
    final sg = statusGroups.firstWhere(
      (g) => g.status == 'waitingPrinting',
      orElse: () => StatusGroup(status: '', items: []),
    );
    return sg.items.length;
  }

  /// Tasks currently printing
  int get printingCount {
    final sg = statusGroups.firstWhere(
      (g) => g.status == 'printing',
      orElse: () => StatusGroup(status: '', items: []),
    );
    return sg.items.length;
  }
}

class ProductionLogistics {
  final List<StatusGroup<TaskSummary>> delivery;
  final List<StatusGroup<TaskSummary>> installation;

  ProductionLogistics({required this.delivery, required this.installation});

  factory ProductionLogistics.fromJson(Map<String, dynamic> json) {
    return ProductionLogistics(
      delivery:
          ((json['delivery'] as List?) ?? [])
              .map(
                (sg) => StatusGroup.fromJson(
                  sg as Map<String, dynamic>,
                  (t) => TaskSummary.fromJson(t),
                ),
              )
              .toList(),
      installation:
          ((json['installation'] as List?) ?? [])
              .map(
                (sg) => StatusGroup.fromJson(
                  sg as Map<String, dynamic>,
                  (t) => TaskSummary.fromJson(t),
                ),
              )
              .toList(),
    );
  }

  int get deliveryTaskCount =>
      delivery.fold(0, (sum, sg) => sum + sg.items.length);
  int get installationTaskCount =>
      installation.fold(0, (sum, sg) => sum + sg.items.length);
}

class ProductionAttention {
  final List<TaskSummary> overrunningTasks;
  final List<TaskSummary> blockedOrPausedTasks;

  ProductionAttention({
    required this.overrunningTasks,
    required this.blockedOrPausedTasks,
  });

  factory ProductionAttention.fromJson(Map<String, dynamic> json) {
    return ProductionAttention(
      overrunningTasks:
          ((json['overrunningTasks'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
      blockedOrPausedTasks:
          ((json['blockedOrPausedTasks'] as List?) ?? [])
              .map((t) => TaskSummary.fromJson(t as Map<String, dynamic>))
              .toList(),
    );
  }

  int get totalIssues => overrunningTasks.length + blockedOrPausedTasks.length;
  bool get hasIssues => totalIssues > 0;
}
