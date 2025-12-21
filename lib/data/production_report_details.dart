import 'package:json_annotation/json_annotation.dart';

part 'production_report_details.g.dart';

/// Main production report response model
@JsonSerializable(explicitToJson: true)
class ProductionReportResponse {
  final bool success;
  final String period;
  final String generatedAt;
  final ProductionReportDetails data;

  ProductionReportResponse({
    required this.success,
    required this.period,
    required this.generatedAt,
    required this.data,
  });

  factory ProductionReportResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductionReportResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ProductionReportResponseToJson(this);
}

@JsonSerializable()
class ProductionReportDetails {
  final OverviewData overview;
  final List<PrinterUtilizationData> printerUtilization;
  final DowntimeData downtimeAndIssues;
  final ReportPeriod period;

  ProductionReportDetails({
    required this.overview,
    required this.printerUtilization,
    required this.downtimeAndIssues,
    required this.period,
  });

  factory ProductionReportDetails.fromJson(Map<String, dynamic> json) =>
      _$ProductionReportDetailsFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ProductionReportDetailsToJson(this);


  /// Get top performing printers (by utilization percentage)
  List<PrinterUtilizationData> getTopPerformers(int count) {
    return printerUtilization.take(count).toList();
  }

  ProductionReportDetails.sample({ReportPeriod? period})
      : period = period ?? ReportPeriod.thisWeek,
        overview = OverviewData(totalPrinters: 0, activePrinters: 0, idlePrinters: 0, maintenancePrinters: 0, offlinePrinters: 0, averageUtilization: 0),
        printerUtilization = [],
        downtimeAndIssues = DowntimeData(totalMaintenanceMinutes: 0, totalMaintenanceHours: 0, averageMaintenancePerPrinter: 0);

  /// Get underutilized printers (below threshold).
  /// If no threshold is provided, returns the single most underutilized printer.
  /// DEFAULT threshold is 80%
  List<PrinterUtilizationData> getUnderutilizedPrinters({
    double? thresholdPercentage,
  }) {
    if (printerUtilization.isEmpty) return [];

    // If no threshold provided, return the most underutilized printer
    if (thresholdPercentage == null) {
      final mostUnderutilizedPrinter = printerUtilization.reduce(
        (current, next) =>
            current.utilizationPercentage < next.utilizationPercentage
                ? current
                : next,
      );
      return mostUnderutilizedPrinter.utilizationPercentage<80? [mostUnderutilizedPrinter] : [];
    }

    // Return all printers below the threshold
    return printerUtilization
        .where((printer) => printer.utilizationPercentage < thresholdPercentage)
        .toList();
  }

  /// Calculate total print jobs across all printers
  int getTotalPrintJobs() {
    return printerUtilization.fold(
        0, (sum, printer) => sum + printer.totalPrintJobs);
  }

  /// Calculate total utilized hours across all printers
  double getTotalUtilizedHours() {
    return printerUtilization.fold(
        0.0, (sum, printer) => sum + printer.totalUtilizedHours);
  }
}

/// Overview statistics
@JsonSerializable()
class OverviewData {
  final int totalPrinters;
  final int activePrinters;
  final int idlePrinters;
  final int maintenancePrinters;
  final int offlinePrinters;
  final double averageUtilization;

  OverviewData({
    required this.totalPrinters,
    required this.activePrinters,
    required this.idlePrinters,
    required this.maintenancePrinters,
    required this.offlinePrinters,
    required this.averageUtilization,
  });

  factory OverviewData.fromJson(Map<String, dynamic> json) =>
      _$OverviewDataFromJson(json);

  Map<String, dynamic> toJson() =>
      _$OverviewDataToJson(this);

  /// Get percentage of active printers
  double getActivePercentage() {
    if (totalPrinters == 0) return 0.0;
    return (activePrinters / totalPrinters) * 100;
  }

  /// Get percentage of idle printers
  double getIdlePercentage() {
    if (totalPrinters == 0) return 0.0;
    return (idlePrinters / totalPrinters) * 100;
  }

  /// Get percentage of maintenance printers
  double getMaintenancePercentage() {
    if (totalPrinters == 0) return 0.0;
    return (maintenancePrinters / totalPrinters) * 100;
  }

  /// Get percentage of offline printers
  double getOfflinePercentage() {
    if (totalPrinters == 0) return 0.0;
    return (offlinePrinters / totalPrinters) * 100;
  }

  /// Check if utilization is healthy (above threshold)
  bool isUtilizationHealthy(double threshold) {
    return averageUtilization >= threshold;
  }
}

/// Individual printer utilization data
@JsonSerializable()
class PrinterUtilizationData {
  final String printerId;
  final String name;
  final double totalUtilizedHours;
  final double totalActiveHours;
  final int totalPrintJobs;
  final double utilizationPercentage;

  PrinterUtilizationData({
    required this.printerId,
    required this.name,
    required this.totalUtilizedHours,
    required this.totalActiveHours,
    required this.totalPrintJobs,
    required this.utilizationPercentage,
  });

  factory PrinterUtilizationData.fromJson(Map<String, dynamic> json) =>
      _$PrinterUtilizationDataFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PrinterUtilizationDataToJson(this);

  /// Get idle hours (active - utilized)
  double getIdleHours() {
    return totalActiveHours - totalUtilizedHours;
  }

  /// Get average hours per print job
  double getAverageHoursPerJob() {
    if (totalPrintJobs == 0) return 0.0;
    return totalUtilizedHours / totalPrintJobs;
  }

  /// Check if printer is underutilized
  bool isUnderutilized(double threshold) {
    return utilizationPercentage < threshold;
  }

  /// Get utilization status
  String getUtilizationStatus() {
    if (utilizationPercentage >= 80) return 'Excellent';
    if (utilizationPercentage >= 60) return 'Good';
    if (utilizationPercentage >= 40) return 'Fair';
    return 'Poor';
  }
}

/// Downtime and maintenance data
@JsonSerializable()
class DowntimeData {
  final double totalMaintenanceMinutes;
  final double totalMaintenanceHours;
  final double averageMaintenancePerPrinter;

  DowntimeData({
    required this.totalMaintenanceMinutes,
    required this.totalMaintenanceHours,
    required this.averageMaintenancePerPrinter,
  });

  factory DowntimeData.fromJson(Map<String, dynamic> json) =>
      _$DowntimeDataFromJson(json);

  Map<String, dynamic> toJson() =>
      _$DowntimeDataToJson(this);


  /// Check if maintenance time is excessive
  bool isMaintenanceExcessive(double thresholdHours) {
    return totalMaintenanceHours > thresholdHours;
  }

  /// Get formatted maintenance time string
  String getFormattedMaintenanceTime() {
    final hours = totalMaintenanceHours.floor();
    final minutes = ((totalMaintenanceHours - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }
}

/// Enum for report periods
enum ReportPeriod {
  today,
  thisWeek,
  thisMonth;

  String get value {
    switch (this) {
      case ReportPeriod.today:
        return 'today';
      case ReportPeriod.thisWeek:
        return 'thisWeek';
      case ReportPeriod.thisMonth:
        return 'thisMonth';
    }
  }

  String get displayName {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
    }
  }
}