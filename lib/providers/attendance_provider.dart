// ============================================
// REPOSITORY PROVIDER
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/attendance/attendance_flag.dart';
import 'package:smooflow/core/models/attendance/public_holiday.dart';
import 'package:smooflow/core/models/attendance/shift.dart';
import 'package:smooflow/core/models/attendance/weekly_attendance_metrics.dart';
import 'package:smooflow/core/repositories/attendance_repo.dart';
import 'package:smooflow/providers/dio_provider.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dio = ref.watch(dioProvider);

  return AttendanceRepository(dio: dio, baseUrl: ApiClient.http.baseUrl);
});

// ============================================
// CURRENT SHIFT
// ============================================

final currentShiftProvider = FutureProvider.family<Shift?, String>((
  ref,
  employeeId,
) async {
  final repo = ref.watch(attendanceRepositoryProvider);

  final now = DateTime.now();

  final startOfDay = DateTime(now.year, now.month, now.day);

  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  final shifts = await repo.getShifts(employeeId, startOfDay, endOfDay);

  for (final shift in shifts) {
    if (shift.isActive) {
      return shift;
    }
  }

  return null;
});

// ============================================
// SHIFTS FOR RANGE
// ============================================

final shiftsForRangeProvider = FutureProvider.family<
  List<Shift>,
  ShiftsForRangeParams
>((ref, params) async {
  final repo = ref.watch(attendanceRepositoryProvider);

  return repo.getShifts(params.employeeId, params.startDate, params.endDate);
});

class ShiftsForRangeParams {
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;

  const ShiftsForRangeParams({
    required this.employeeId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) {
    return other is ShiftsForRangeParams &&
        other.employeeId == employeeId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(employeeId, startDate, endDate);
}

// ============================================
// WEEKLY METRICS
// ============================================

final weeklyMetricsProvider =
    FutureProvider.family<WeeklyAttendanceMetrics, WeeklyMetricsParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(attendanceRepositoryProvider);

      return repo.getWeeklyMetrics(params.employeeId, params.weekStartDate);
    });

class WeeklyMetricsParams {
  final String employeeId;
  final DateTime weekStartDate;

  const WeeklyMetricsParams({
    required this.employeeId,
    required this.weekStartDate,
  });

  @override
  bool operator ==(Object other) {
    return other is WeeklyMetricsParams &&
        other.employeeId == employeeId &&
        other.weekStartDate == weekStartDate;
  }

  @override
  int get hashCode => Object.hash(employeeId, weekStartDate);
}

// ============================================
// WEEKLY METRICS RANGE
// ============================================

final weeklyMetricsRangeProvider = FutureProvider.family<
  List<WeeklyAttendanceMetrics>,
  WeeklyMetricsRangeParams
>((ref, params) async {
  final repo = ref.watch(attendanceRepositoryProvider);

  return repo.getWeeklyMetricsRange(
    params.employeeId,
    params.startDate,
    params.endDate,
  );
});

class WeeklyMetricsRangeParams {
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;

  const WeeklyMetricsRangeParams({
    required this.employeeId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) {
    return other is WeeklyMetricsRangeParams &&
        other.employeeId == employeeId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(employeeId, startDate, endDate);
}

// ============================================
// PUBLIC HOLIDAYS
// ============================================

final publicHolidaysForRangeProvider =
    FutureProvider.family<List<PublicHoliday>, PublicHolidaysParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(attendanceRepositoryProvider);

      return repo.getPublicHolidays(
        params.startDate,
        params.endDate,
        region: params.region,
      );
    });

class PublicHolidaysParams {
  final DateTime startDate;
  final DateTime endDate;
  final String? region;

  const PublicHolidaysParams({
    required this.startDate,
    required this.endDate,
    this.region,
  });

  @override
  bool operator ==(Object other) {
    return other is PublicHolidaysParams &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.region == region;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate, region);
}

// ============================================
// PENDING FLAGS
// ============================================

final pendingFlagsForEmployeeProvider =
    FutureProvider.family<List<AttendanceFlag>, String>((
      ref,
      employeeId,
    ) async {
      final repo = ref.watch(attendanceRepositoryProvider);

      return repo.getPendingFlags(employeeId);
    });
