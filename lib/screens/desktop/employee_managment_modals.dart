import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Design constants
const double _rSmall = 4;
const double _rMedium = 6;
const double _rLarge = 8;
const double _rXL = 12;

class _T {
  static const bgPrimary = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF8F9FB);
  static const bgTertiary = Color(0xF5F7FA);

  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textInverse = Color(0xFFFFFFFF);

  static const borderLight = Color(0xFFE5E7EB);
  static const borderMedium = Color(0xFFD1D5DB);

  static const accentBlue = Color(0xFF3B82F6);
  static const accentGreen = Color(0xFF10B981);
  static const accentOrange = Color(0xFFF97316);
  static const statusActive = Color(0xFF10B981);
  static const statusInactive = Color(0xFFEF4444);
}

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
}

// ============================================
// EMPLOYEE FORM MODAL (Add / Edit)
// ============================================

class EmployeeFormModal extends StatefulWidget {
  final EmployeeWithAttendance? employee;

  const EmployeeFormModal({this.employee, Key? key}) : super(key: key);

  @override
  State<EmployeeFormModal> createState() => _EmployeeFormModalState();
}

class _EmployeeFormModalState extends State<EmployeeFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _roleController;
  late TextEditingController _phoneController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _weeklyHoursController;

  String _selectedDepartment = 'Operations';
  String _selectedSalaryType = 'salary';
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.name ?? '');
    _emailController = TextEditingController(
      text: widget.employee?.email ?? '',
    );
    _roleController = TextEditingController(text: widget.employee?.role ?? '');
    _phoneController = TextEditingController();
    _hourlyRateController = TextEditingController(
      text: widget.employee?.hourlyRate.toStringAsFixed(2) ?? '',
    );
    _weeklyHoursController = TextEditingController(
      text: widget.employee?.weeklyHoursThreshold.toString() ?? '40',
    );
    _selectedDepartment = widget.employee?.department ?? 'Operations';
    _selectedSalaryType = widget.employee?.salaryType ?? 'salary';
    _isActive = widget.employee?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _hourlyRateController.dispose();
    _weeklyHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employee != null;

    return Dialog(
      backgroundColor: _T.bgPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rXL)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _T.borderLight, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Employee' : 'Add New Employee',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _T.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEditing
                            ? 'Update employee information'
                            : 'Create a new employee record',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _T.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close_rounded),
                    color: _T.textSecondary,
                  ),
                ],
              ),
            ),

            // Modal body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    _buildSectionHeader('Personal Information'),
                    const SizedBox(height: 16),

                    // Name field
                    _buildFormField(
                      label: 'Full Name',
                      controller: _nameController,
                      placeholder: 'John Doe',
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    _buildFormField(
                      label: 'Email Address',
                      controller: _emailController,
                      placeholder: 'john@example.com',
                      keyboardType: TextInputType.emailAddress,
                      required: true,
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    _buildFormField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      placeholder: '+1 (555) 000-0000',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Employment Information Section
                    _buildSectionHeader('Employment Information'),
                    const SizedBox(height: 16),

                    // Role and Department (row)
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Role',
                            controller: _roleController,
                            placeholder: 'e.g., Designer, Developer',
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Department',
                            value: _selectedDepartment,
                            items: [
                              'Operations',
                              'Design',
                              'Tech',
                              'Sales',
                              'Marketing',
                            ],
                            onChanged: (value) {
                              setState(
                                () =>
                                    _selectedDepartment = value ?? 'Operations',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Salary Type and Rate (row)
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Salary Type',
                            value: _selectedSalaryType,
                            items: ['Hourly', 'Salary'],
                            onChanged: (value) {
                              setState(
                                () =>
                                    _selectedSalaryType =
                                        (value ?? 'salary').toLowerCase(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            label: 'Hourly Rate (\$)',
                            controller: _hourlyRateController,
                            placeholder: '45.00',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weekly hours threshold
                    _buildFormField(
                      label: 'Weekly Hours Threshold',
                      controller: _weeklyHoursController,
                      placeholder: '40',
                      keyboardType: TextInputType.number,
                      suffix: 'hours',
                    ),
                    const SizedBox(height: 24),

                    // Status Section
                    _buildSectionHeader('Status'),
                    const SizedBox(height: 16),

                    // Active/Inactive toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _T.bgTertiary,
                        border: Border.all(color: _T.borderLight),
                        borderRadius: BorderRadius.circular(_rMedium),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Employee Status',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _T.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isActive
                                    ? 'Employee is active and can check in'
                                    : 'Employee is inactive',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: _T.textSecondary),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isActive,
                            onChanged:
                                (value) => setState(() => _isActive = value),
                            activeColor: _T.statusActive,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Modal footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: _T.borderLight, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: _T.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.accentBlue,
                      foregroundColor: _T.textInverse,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_rMedium),
                      ),
                    ),
                    child:
                        _isSaving
                            ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              isEditing ? 'Update' : 'Create',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _T.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _T.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: _T.textTertiary),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: _T.textSecondary, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_rMedium),
              borderSide: const BorderSide(color: _T.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_rMedium),
              borderSide: const BorderSide(color: _T.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_rMedium),
              borderSide: const BorderSide(color: _T.accentBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
          ),
          style: const TextStyle(color: _T.textPrimary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _T.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _T.borderLight),
            borderRadius: BorderRadius.circular(_rMedium),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items:
                items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.toLowerCase(),
                        child: Text(item),
                      ),
                    )
                    .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    // Validate fields
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // OPEN ITEM: Call API to save employee
      // await repository.createOrUpdateEmployee(...)

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.employee != null
                  ? 'Employee updated successfully'
                  : 'Employee created successfully',
            ),
            backgroundColor: _T.statusActive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

// ============================================
// EMPLOYEE DETAILS MODAL
// ============================================

class EmployeeDetailsModal extends StatelessWidget {
  final EmployeeWithAttendance employee;

  const EmployeeDetailsModal({required this.employee, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _T.bgPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rXL)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _T.borderLight, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _getAvatarColor(employee.id),
                        child: Text(
                          employee.name
                              .split(' ')
                              .map((e) => e[0])
                              .join()
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: _T.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    employee.isActive,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(_rSmall),
                                  border: Border.all(
                                    color: _getStatusColor(
                                      employee.isActive,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          employee.isActive,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      employee.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: _getStatusColor(
                                          employee.isActive,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                employee.id,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: _T.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close_rounded),
                    color: _T.textSecondary,
                  ),
                ],
              ),
            ),

            // Modal body - Tabbed content
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    // Tab bar
                    TabBar(
                      labelColor: _T.accentBlue,
                      unselectedLabelColor: _T.textSecondary,
                      indicatorColor: _T.accentBlue,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Attendance'),
                        Tab(text: 'Compensation'),
                      ],
                    ),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildOverviewTab(context),
                          _buildAttendanceTab(context),
                          _buildCompensationTab(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Modal footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: _T.borderLight, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('Personal Information', [
            _buildDetailRow('Email', employee.email),
            _buildDetailRow('Department', employee.department),
            _buildDetailRow('Role', employee.role),
          ]),
          const SizedBox(height: 24),
          _buildDetailSection('Employment', [
            _buildDetailRow('Salary Type', employee.salaryType),
            _buildDetailRow(
              'Hourly Rate',
              '\$${employee.hourlyRate.toStringAsFixed(2)}/hr',
            ),
            _buildDetailRow(
              'Weekly Hours',
              '${employee.weeklyHoursThreshold}h',
            ),
            _buildDetailRow(
              'Hire Date',
              DateFormat('MMM d, yyyy').format(employee.createdAt),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('Current Status', [
            if (employee.lastCheckIn != null)
              _buildDetailRow(
                'Last Check-in',
                DateFormat('MMM d, HH:mm').format(employee.lastCheckIn!),
              ),
            if (employee.lastCheckOut != null)
              _buildDetailRow(
                'Last Check-out',
                DateFormat('MMM d, HH:mm').format(employee.lastCheckOut!),
              ),
            _buildDetailRow(
              'Currently',
              employee.isCurrentlyCheckedIn ? '✓ Checked In' : '—',
            ),
          ]),
          const SizedBox(height: 24),
          _buildDetailSection('This Week', [
            _buildDetailRow(
              'Consecutive Days',
              '${employee.consecutiveDaysWorked} days',
            ),
            _buildDetailRow(
              'Overtime',
              '${employee.currentWeekOvertime?.toStringAsFixed(1) ?? '0'} hours',
            ),
            _buildDetailRow(
              'Weekends Worked',
              '${employee.weekendDaysWorked} days',
            ),
          ]),
          const SizedBox(height: 24),
          _buildDetailSection('Recent Shifts (Last 7 days)', [
            _buildShiftRow('Monday', '8h 45m', true),
            _buildShiftRow('Tuesday', '9h 15m', true),
            _buildShiftRow('Wednesday', '8h 30m', true),
            _buildShiftRow('Thursday', '—', false),
            _buildShiftRow('Friday', '8h 00m', true),
          ]),
        ],
      ),
    );
  }

  Widget _buildCompensationTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('Pending Compensation', [
            _buildDetailRow(
              'Overtime Hours',
              '+${employee.currentWeekOvertime?.toStringAsFixed(1) ?? '0'}h',
            ),
            _buildDetailRow(
              'Weekend Days',
              '${employee.weekendDaysWorked} days',
            ),
            _buildDetailRow(
              'Total Due',
              '\$${(employee.currentWeekOvertime ?? 0 * 67.5).toStringAsFixed(2)}',
            ),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _T.statusActive.withOpacity(0.1),
              border: Border.all(color: _T.statusActive.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(_rMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _T.statusActive, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Compensation is calculated and displayed for manager review. Final approval is required before payroll processing.',
                    style: TextStyle(color: _T.statusActive, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _T.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _T.borderLight),
            borderRadius: BorderRadius.circular(_rMedium),
          ),
          child: Column(
            children:
                rows.asMap().entries.map((entry) {
                  final isLast = entry.key == rows.length - 1;
                  return Column(
                    children: [
                      entry.value,
                      if (!isLast)
                        Divider(height: 1, color: _T.borderLight, thickness: 1),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: _T.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _T.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftRow(String day, String duration, bool worked) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(color: _T.textSecondary, fontSize: 13),
          ),
          Text(
            duration,
            style: TextStyle(
              color: worked ? _T.statusActive : _T.textTertiary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isActive) {
    return isActive ? _T.statusActive : _T.statusInactive;
  }

  Color _getAvatarColor(String id) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF97316),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    return colors[id.hashCode % colors.length];
  }
}
