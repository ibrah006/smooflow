// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_report_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductionReportResponse _$ProductionReportResponseFromJson(
  Map<String, dynamic> json,
) => ProductionReportResponse(
  success: json['success'] as bool,
  period: json['period'] as String,
  generatedAt: json['generatedAt'] as String,
  data: ProductionReportDetails.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProductionReportResponseToJson(
  ProductionReportResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'period': instance.period,
  'generatedAt': instance.generatedAt,
  'data': instance.data.toJson(),
};

ProductionReportDetails _$ProductionReportDetailsFromJson(
  Map<String, dynamic> json,
) => ProductionReportDetails(
  overview: OverviewData.fromJson(json['overview'] as Map<String, dynamic>),
  printerUtilization:
      (json['printerUtilization'] as List<dynamic>)
          .map(
            (e) => PrinterUtilizationData.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
  downtimeAndIssues: DowntimeData.fromJson(
    json['downtimeAndIssues'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ProductionReportDetailsToJson(
  ProductionReportDetails instance,
) => <String, dynamic>{
  'overview': instance.overview,
  'printerUtilization': instance.printerUtilization,
  'downtimeAndIssues': instance.downtimeAndIssues,
};

OverviewData _$OverviewDataFromJson(Map<String, dynamic> json) => OverviewData(
  totalPrinters: (json['totalPrinters'] as num).toInt(),
  activePrinters: (json['activePrinters'] as num).toInt(),
  idlePrinters: (json['idlePrinters'] as num).toInt(),
  maintenancePrinters: (json['maintenancePrinters'] as num).toInt(),
  offlinePrinters: (json['offlinePrinters'] as num).toInt(),
  averageUtilization: (json['averageUtilization'] as num).toDouble(),
);

Map<String, dynamic> _$OverviewDataToJson(OverviewData instance) =>
    <String, dynamic>{
      'totalPrinters': instance.totalPrinters,
      'activePrinters': instance.activePrinters,
      'idlePrinters': instance.idlePrinters,
      'maintenancePrinters': instance.maintenancePrinters,
      'offlinePrinters': instance.offlinePrinters,
      'averageUtilization': instance.averageUtilization,
    };

PrinterUtilizationData _$PrinterUtilizationDataFromJson(
  Map<String, dynamic> json,
) => PrinterUtilizationData(
  printerId: json['printerId'] as String,
  name: json['name'] as String,
  totalUtilizedHours: (json['totalUtilizedHours'] as num).toDouble(),
  totalActiveHours: (json['totalActiveHours'] as num).toDouble(),
  totalPrintJobs: (json['totalPrintJobs'] as num).toInt(),
  utilizationPercentage: (json['utilizationPercentage'] as num).toDouble(),
);

Map<String, dynamic> _$PrinterUtilizationDataToJson(
  PrinterUtilizationData instance,
) => <String, dynamic>{
  'printerId': instance.printerId,
  'name': instance.name,
  'totalUtilizedHours': instance.totalUtilizedHours,
  'totalActiveHours': instance.totalActiveHours,
  'totalPrintJobs': instance.totalPrintJobs,
  'utilizationPercentage': instance.utilizationPercentage,
};

DowntimeData _$DowntimeDataFromJson(Map<String, dynamic> json) => DowntimeData(
  totalMaintenanceMinutes: (json['totalMaintenanceMinutes'] as num).toDouble(),
  totalMaintenanceHours: (json['totalMaintenanceHours'] as num).toDouble(),
  averageMaintenancePerPrinter:
      (json['averageMaintenancePerPrinter'] as num).toDouble(),
);

Map<String, dynamic> _$DowntimeDataToJson(DowntimeData instance) =>
    <String, dynamic>{
      'totalMaintenanceMinutes': instance.totalMaintenanceMinutes,
      'totalMaintenanceHours': instance.totalMaintenanceHours,
      'averageMaintenancePerPrinter': instance.averageMaintenancePerPrinter,
    };
