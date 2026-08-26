// ============================================
// REPOSITORY PROVIDER
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/employee_with_attendance.dart';
import 'package:smooflow/core/repositories/employee_repo.dart';
import 'package:smooflow/providers/dio_provider.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final dio = ref.watch(dioProvider);

  return EmployeeRepository(dio: dio, baseUrl: ApiClient.http.baseUrl);
});

// Provider for single employee
final employeeProvider = FutureProvider.family<EmployeeWithAttendance, String>((
  ref,
  employeeId,
) async {
  final repo = ref.watch(employeeRepositoryProvider);
  // OPEN ITEM: Implement API call to get single employee
  return repo.getEmployee(employeeId);

  throw UnimplementedError('Fetch single employee not implemented');
});

// ============================================
// CRUD OPERATIONS PROVIDERS
// ============================================

// Create employee
final createEmployeeProvider =
    FutureProvider.family<EmployeeWithAttendance, Map<String, dynamic>>((
      ref,
      data,
    ) async {
      final repo = ref.watch(employeeRepositoryProvider);
      // OPEN ITEM: Implement API call to create employee
      // final employee = await repo.createEmployee(data);
      // ref.invalidate(employeesProvider); // Refresh employee list
      // return employee;

      throw UnimplementedError('Create employee not implemented');
    });

// Update employee
final updateEmployeeProvider = FutureProvider.family<
  EmployeeWithAttendance,
  (String id, Map<String, dynamic> data)
>((ref, args) async {
  final repo = ref.watch(employeeRepositoryProvider);
  // OPEN ITEM: Implement API call to update employee
  // final employee = await repo.updateEmployee(args.$1, args.$2);
  // ref.invalidate(employeesProvider); // Refresh employee list
  // ref.invalidate(employeeProvider(args.$1)); // Refresh single employee
  // return employee;

  throw UnimplementedError('Update employee not implemented');
});

// Delete employee
final deleteEmployeeProvider = FutureProvider.family<void, String>((
  ref,
  employeeId,
) async {
  final repo = ref.watch(employeeRepositoryProvider);
  // OPEN ITEM: Implement API call to delete employee
  // await repo.deleteEmployee(employeeId);
  // ref.invalidate(employeesProvider); // Refresh employee list

  throw UnimplementedError('Delete employee not implemented');
});
