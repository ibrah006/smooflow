import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift.freezed.dart';
part 'shift.g.dart';

@freezed
class Shift with _$Shift {
  const factory Shift({
    required String id,
    required String employeeId,
    required DateTime date,
    required DateTime checkInTime,
    DateTime? checkOutTime,
    required int shiftDurationMinutes,
    required int workMinutes,
    required int recordedBreakMinutes,
    required int policyBreakMinutes,
    required ShiftStatus status,
    String? statusReason,
    String? managerNotes,
    String? managerApprovedBy,
    DateTime? managerApprovedAt,
    @Default(false) bool isHolidayWorked,
    String? holidayId,
    @Default(DateTime.now) DateTime createdAt,
    @Default(DateTime.now) DateTime updatedAt,
  }) = _Shift;

  factory Shift.fromJson(Map<String, dynamic> json) => _$ShiftFromJson(json);

  bool get isActive => checkOutTime == null;

  bool get needsReview =>
      status == ShiftStatus.completed || status == ShiftStatus.flagged;

  String get displayDate => '${date.month}/${date.day}/${date.year}';

  String get displayCheckInTime => _formatTime(checkInTime);

  String get displayCheckOutTime =>
      checkOutTime != null ? _formatTime(checkOutTime!) : '--:--';

  String get displayDuration {
    final hours = shiftDurationMinutes ~/ 60;
    final minutes = shiftDurationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String get displayWorkTime {
    final hours = workMinutes ~/ 60;
    final minutes = workMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

enum ShiftStatus {
  @JsonValue('incomplete')
  incomplete,

  @JsonValue('completed')
  completed,

  @JsonValue('approved')
  approved,

  @JsonValue('flagged')
  flagged,
}
