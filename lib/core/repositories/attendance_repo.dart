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
