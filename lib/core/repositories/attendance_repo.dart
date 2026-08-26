import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/attendance/attendance_api_response.dart';
import 'package:smooflow/core/models/attendance/attendance_flag.dart';
import 'package:smooflow/core/models/attendance/public_holiday.dart';
import 'package:smooflow/core/models/attendance/shift.dart';
import 'package:smooflow/core/models/attendance/weekly_attendance_metrics.dart';
import 'package:smooflow/core/models/employee_with_attendance.dart';
import 'package:smooflow/core/repositories/employee_repo.dart';
import 'package:smooflow/screens/desktop/employee_managment_modals.dart';

// ============================================
// REPOSITORY
// ============================================

class AttendanceRepository {
  final Dio dio;
  final String baseUrl;

  AttendanceRepository({required this.dio, required this.baseUrl});

  // ============================================
  // CHECK-IN / CHECK-OUT
  // ============================================

  Future<Shift> checkIn(String employeeId, {DateTime? timestamp}) async {
    final response = await dio.post(
      '$baseUrl/api/attendance/check-in',
      data: {
        'employeeId': employeeId,
        'timestamp': timestamp?.toIso8601String(),
      },
    );

    final apiResp = AttendanceApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (obj) => obj as Map<String, dynamic>,
    );

    if (!apiResp.success) {
      throw Exception('Check-in failed');
    }

    return Shift.fromJson(apiResp.data!['shift'] as Map<String, dynamic>);
  }

  Future<Shift> checkOut(String employeeId, {DateTime? timestamp}) async {
    final response = await dio.post(
      '$baseUrl/api/attendance/check-out',
      data: {
        'employeeId': employeeId,
        'timestamp': timestamp?.toIso8601String(),
      },
    );

    final apiResp = AttendanceApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (obj) => obj as Map<String, dynamic>,
    );

    if (!apiResp.success) {
      throw Exception('Check-out failed');
    }

    return Shift.fromJson(apiResp.data!['shift'] as Map<String, dynamic>);
  }

  // ============================================
  // SHIFT QUERIES
  // ============================================

  Future<List<Shift>> getShifts(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await dio.get(
      '$baseUrl/api/attendance/shifts/$employeeId',
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    final jsonResp = response.data as Map<String, dynamic>;

    return (jsonResp['data'] as List)
        .map((s) => Shift.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<Shift> getShift(String shiftId) async {
    final response = await dio.get('$baseUrl/api/attendance/shift/$shiftId');

    final jsonResp = response.data as Map<String, dynamic>;

    return Shift.fromJson(jsonResp['data'] as Map<String, dynamic>);
  }

  // ============================================
  // SHIFT MANAGEMENT
  // ============================================

  Future<Shift> recordBreakTime(
    String shiftId,
    int breakMinutes, {
    String? managerNotes,
  }) async {
    final response = await dio.patch(
      '$baseUrl/api/attendance/shift/$shiftId/break',
      data: {'breakMinutes': breakMinutes, 'managerNotes': managerNotes},
    );

    final jsonResp = response.data as Map<String, dynamic>;

    return Shift.fromJson(jsonResp['shift'] as Map<String, dynamic>);
  }

  Future<Shift> adjustShiftTimes(
    String shiftId, {
    DateTime? checkInTime,
    DateTime? checkOutTime,
    required String managerNotes,
  }) async {
    final response = await dio.patch(
      '$baseUrl/api/attendance/shift/$shiftId/times',
      data: {
        'checkInTime': checkInTime?.toIso8601String(),
        'checkOutTime': checkOutTime?.toIso8601String(),
        'managerNotes': managerNotes,
      },
    );

    final jsonResp = response.data as Map<String, dynamic>;

    return Shift.fromJson(jsonResp['shift'] as Map<String, dynamic>);
  }

  Future<Shift> approveShift(
    String shiftId,
    String managerId, {
    String? approvalNotes,
  }) async {
    final response = await dio.patch(
      '$baseUrl/api/attendance/shift/$shiftId/approve',
      data: {'managerId': managerId, 'approvalNotes': approvalNotes},
    );

    final jsonResp = response.data as Map<String, dynamic>;

    return Shift.fromJson(jsonResp['shift'] as Map<String, dynamic>);
  }

  // ============================================
  // WEEKLY METRICS
  // ============================================

  Future<WeeklyAttendanceMetrics> getWeeklyMetrics(
    String employeeId,
    DateTime weekStartDate,
  ) async {
    final response = await dio.get(
      '$baseUrl/api/attendance/metrics/$employeeId',
      queryParameters: {'weekStartDate': weekStartDate.toIso8601String()},
    );

    final jsonResp = response.data as Map<String, dynamic>;

    return WeeklyAttendanceMetrics.fromJson(
      jsonResp['data'] as Map<String, dynamic>,
    );
  }

  Future<List<WeeklyAttendanceMetrics>> getWeeklyMetricsRange(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await dio.get(
      '$baseUrl/api/attendance/metrics/$employeeId/range',
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    final jsonResp = response.data as Map<String, dynamic>;

    return (jsonResp['data'] as List)
        .map((m) => WeeklyAttendanceMetrics.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> recalculateMetrics(
    String employeeId,
    DateTime weekStartDate,
  ) async {
    await dio.post(
      '$baseUrl/api/attendance/metrics/$employeeId/recalculate',
      data: {'weekStartDate': weekStartDate.toIso8601String()},
    );
  }

  // ============================================
  // PUBLIC HOLIDAYS
  // ============================================

  Future<List<PublicHoliday>> getPublicHolidays(
    DateTime startDate,
    DateTime endDate, {
    String? region,
  }) async {
    final response = await dio.get(
      '$baseUrl/api/attendance/holidays',
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (region != null) 'region': region,
      },
    );

    final jsonResp = response.data as Map<String, dynamic>;

    return (jsonResp['data'] as List)
        .map((h) => PublicHoliday.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  // ============================================
  // FLAGS & ALERTS
  // ============================================

  Future<List<AttendanceFlag>> getPendingFlags(String employeeId) async {
    final response = await dio.get('$baseUrl/api/attendance/flags/$employeeId');

    final jsonResp = response.data as Map<String, dynamic>;

    return (jsonResp['data'] as List)
        .map((f) => AttendanceFlag.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  Future<AttendanceFlag> acknowledgeFlag(
    String flagId,
    String managerId,
  ) async {
    final response = await dio.patch(
      '$baseUrl/api/attendance/flags/$flagId/acknowledge',
      data: {'managerId': managerId},
    );

    final jsonResp = response.data as Map<String, dynamic>;

    return AttendanceFlag.fromJson(jsonResp['data'] as Map<String, dynamic>);
  }
}

// ============================================
// DIO PROVIDER
// ============================================

// Keep your existing Dio provider if you already have one.
// Example:
//
// final dioProvider = Provider<Dio>((ref) {
//   return Dio();
// });

// ============================================
// REPOSITORY PROVIDER
// ============================================

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

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
