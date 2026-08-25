import 'package:freezed_annotation/freezed_annotation.dart';

part 'compensation_summary.freezed.dart';
part 'compensation_summary.g.dart';

@freezed
abstract class CompensationSummary with _$CompensationSummary {
  const factory CompensationSummary({
    required double overtimeHours,
    required double overtimeAmount,
    required int weekendDaysCount,
    required double weekendCompensationHours,
    required double weekendCompensationAmount,
    required int holidaysWorkedCount,
    required double holidayCompensationHours,
    required double holidayCompensationAmount,
    required double totalCompensationDue,
  }) = _CompensationSummary;

  factory CompensationSummary.fromJson(Map<String, dynamic> json) =>
      _$CompensationSummaryFromJson(json);
}
