// Import the model from employee_management_screen.dart
// For now, using inline copy

class EmployeeWithAttendance {
  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final double hourlyRate;
  final String salaryType;
  final bool isActive;
  final DateTime? lastCheckIn;
  final DateTime? lastCheckOut;
  final int? weeklyHoursThreshold;
  final int? consecutiveDaysWorked;
  final double? currentWeekOvertime;
  final int? weekendDaysWorked;
  final DateTime createdAt;

  EmployeeWithAttendance({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.hourlyRate,
    required this.salaryType,
    required this.isActive,
    this.lastCheckIn,
    this.lastCheckOut,
    this.weeklyHoursThreshold,
    this.consecutiveDaysWorked,
    this.currentWeekOvertime,
    this.weekendDaysWorked,
    required this.createdAt,
  });

  bool get isCurrentlyCheckedIn => lastCheckIn != null && lastCheckOut == null;

  factory EmployeeWithAttendance.fromJson(Map<String, dynamic> json) {
    return EmployeeWithAttendance(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'General Staff',
      department: json['department'] as String? ?? 'Operations',
      hourlyRate: double.tryParse(json['hourlyRate']?.toString() ?? '0') ?? 0.0,
      salaryType: json['salaryType'] as String? ?? 'hourly',
      isActive: json['isActive'] as bool? ?? true,
      weeklyHoursThreshold: json['weeklyHoursThreshold'] as int?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }
}
