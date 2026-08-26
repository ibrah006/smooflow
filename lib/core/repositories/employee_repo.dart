import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/employee_with_attendance.dart';
import 'package:smooflow/core/repositories/attendance_repo.dart';
import 'package:smooflow/providers/dio_provider.dart';
import 'package:smooflow/providers/employee_provider.dart';

class EmployeeRepository {
  final Dio dio;
  final String baseUrl;

  EmployeeRepository({required this.dio, required this.baseUrl});

  // ============================================
  // READ OPERATIONS
  // ============================================

  /// Fetch all employees with optional pagination and active status filtering
  Future<List<EmployeeWithAttendance>> getEmployees({
    bool? isActive,
    int? limit,
    int? offset,
  }) async {
    final response = await dio.get(
      '$baseUrl/api/employees',
      queryParameters: {
        if (isActive != null) 'isActive': isActive,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );

    final jsonResp = response.data as Map<String, dynamic>;

    if (jsonResp['success'] != true) {
      throw Exception('Failed to fetch employees');
    }

    return (jsonResp['data'] as List)
        .map((e) => EmployeeWithAttendance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single employee by ID
  Future<EmployeeWithAttendance> getEmployee(
    String id, {
    bool includeRelations = false,
  }) async {
    final response = await dio.get(
      '$baseUrl/api/employees/$id',
      queryParameters: {if (includeRelations) 'includeRelations': 'true'},
    );

    final jsonResp = response.data as Map<String, dynamic>;

    if (jsonResp['success'] != true) {
      throw Exception('Failed to fetch employee with ID $id');
    }

    return EmployeeWithAttendance.fromJson(
      jsonResp['data'] as Map<String, dynamic>,
    );
  }

  // ============================================
  // WRITE & MUTATION OPERATIONS
  // ============================================

  /// Create a new employee
  Future<EmployeeWithAttendance> createEmployee(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('$baseUrl/api/employees', data: data);

    final jsonResp = response.data as Map<String, dynamic>;

    if (jsonResp['success'] != true) {
      throw Exception('Failed to create employee');
    }

    return EmployeeWithAttendance.fromJson(
      jsonResp['data'] as Map<String, dynamic>,
    );
  }

  /// Update general employee details
  Future<EmployeeWithAttendance> updateEmployee(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.patch('$baseUrl/api/employees/$id', data: data);

    final jsonResp = response.data as Map<String, dynamic>;

    if (jsonResp['success'] != true) {
      throw Exception('Failed to update employee $id');
    }

    return EmployeeWithAttendance.fromJson(
      jsonResp['data'] as Map<String, dynamic>,
    );
  }

  /// Update compensation policy settings for an employee
  Future<EmployeeWithAttendance> updateCompensationPolicy(
    String id,
    Map<String, dynamic> policyData,
  ) async {
    final response = await dio.patch(
      '$baseUrl/api/employees/$id/compensation-policy',
      data: policyData,
    );

    final jsonResp = response.data as Map<String, dynamic>;

    if (jsonResp['success'] != true) {
      throw Exception('Failed to update compensation policy for employee $id');
    }

    return EmployeeWithAttendance.fromJson(
      jsonResp['data'] as Map<String, dynamic>,
    );
  }

  /// Toggle an employee's active status
  Future<EmployeeWithAttendance> toggleStatus(String id, bool isActive) async {
    final response = await dio.patch(
      '$baseUrl/api/employees/$id/status',
      data: {'isActive': isActive},
    );

    final jsonResp = response.data as Map<String, dynamic>;

    if (jsonResp['success'] != true) {
      throw Exception('Failed to toggle status for employee $id');
    }

    return EmployeeWithAttendance.fromJson(
      jsonResp['data'] as Map<String, dynamic>,
    );
  }

  /// Delete an employee record
  Future<void> deleteEmployee(String id) async {
    final response = await dio.delete('$baseUrl/api/employees/$id');

    final jsonResp = response.data as Map<String, dynamic>;

    if (jsonResp['success'] != true) {
      throw Exception('Failed to delete employee $id');
    }
  }
}

// ============================================
// Employee PROVIDERS
// ============================================

// Provider to fetch all employees from API
final employeesProvider = FutureProvider<List<EmployeeWithAttendance>>((
  ref,
) async {
  final repo = ref.watch(employeeRepositoryProvider);
  // OPEN ITEM: Implement API call to get employees

  // For now, return empty list (will be populated by actual API)
  return repo.getEmployees();
});

class FilteredEmployeesParams {
  final String? search;
  final String? status;
  final String? department;

  const FilteredEmployeesParams({this.search, this.status, this.department});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilteredEmployeesParams &&
        other.search == search &&
        other.status == status &&
        other.department == department;
  }

  @override
  int get hashCode => Object.hash(search, status, department);
}

// Provider for filtered employees
final filteredEmployeesProvider = FutureProvider.family<
  List<EmployeeWithAttendance>,
  FilteredEmployeesParams
>((ref, filters) async {
  final allEmployees = await ref.watch(employeesProvider.future);

  return allEmployees.where((emp) {
    final matchesSearch =
        filters.search == null ||
        filters.search!.isEmpty ||
        emp.name.toLowerCase().contains(filters.search!.toLowerCase()) ||
        emp.email.toLowerCase().contains(filters.search!.toLowerCase()) ||
        emp.id.toLowerCase().contains(filters.search!.toLowerCase());

    final matchesStatus =
        filters.status == null ||
        filters.status == 'all' ||
        (filters.status == 'active' && emp.isActive) ||
        (filters.status == 'inactive' && !emp.isActive);

    final matchesDepartment =
        filters.department == null ||
        filters.department == 'all' ||
        emp.department.toLowerCase() == filters.department!.toLowerCase();

    return matchesSearch && matchesStatus && matchesDepartment;
  }).toList();
});
