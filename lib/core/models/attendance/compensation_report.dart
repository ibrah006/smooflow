import 'package:freezed_annotation/freezed_annotation.dart';

part 'compensation_report.freezed.dart';
part 'compensation_report.g.dart';

@freezed
abstract class CompensationReport with _$CompensationReport {
  const factory CompensationReport({
    required String employeeId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double overtimeHours,
    required double overtimeAmount,
    required int weekendDays,
    required double weekendCompAmount,
    required int holidaysDays,
    required double holidayCompAmount,
    required double totalCompensationDue,
    required DateTime exportDate,
  }) = _CompensationReport;

  factory CompensationReport.fromJson(Map<String, dynamic> json) =>
      _$CompensationReportFromJson(json);
}
