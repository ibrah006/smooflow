import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/core/models/employee_with_attendance.dart';
import 'package:smooflow/providers/employee_provider.dart';

// Modern Compact SaaS Design Tokens (Aligned with EmployeeManagementScreen)
class _T {
  static const canvasBg = Color(0xFFF8FAFC);
  static const surfaceBg = Color(0xFFFFFFFF);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);

  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);

  static const primary = Color(0xFF2563EB);
  static const primaryBg = Color(0xFFEFF6FF);
  static const primaryBorder = Color(0xFFDBEAFE);

  static const green = Color(0xFF10B981);
  static const greenBg = Color(0xFFF0FDF4);
  static const red = Color(0xFFEF4444);
  static const redBg = Color(0xFFFEE2E2);
  static const amber = Color(0xFFF59E0B);
  static const amberBg = Color(0xFFFEF3C7);

  static const double r = 6.0;
  static const double rLg = 12.0;
  static const double rPill = 99.0;
}

// ============================================
// EMPLOYEE FORM MODAL
// ============================================

class EmployeeFormModal extends ConsumerStatefulWidget {
  final EmployeeWithAttendance? employee;

  const EmployeeFormModal({this.employee, Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeFormModal> createState() => _EmployeeFormModalState();
}

class _EmployeeFormModalState extends ConsumerState<EmployeeFormModal> {
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
      backgroundColor: _T.surfaceBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_T.rLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _T.slate200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEditing ? Icons.edit_note : Icons.person_add_alt_1,
                        color: _T.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Employee' : 'Add New Employee',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _T.ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'Update existing employee records'
                                : 'Enter details to register a new employee',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _T.slate400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close, size: 18),
                    color: _T.slate400,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('PERSONAL INFORMATION'),
                    const SizedBox(height: 12),
                    _buildFormField(
                      label: 'Full Name',
                      controller: _nameController,
                      placeholder: 'e.g. Jane Doe',
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _buildFormField(
                      label: 'Email Address',
                      controller: _emailController,
                      placeholder: 'jane.doe@company.com',
                      keyboardType: TextInputType.emailAddress,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _buildFormField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      placeholder: '+1 (555) 000-0000',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    _buildSectionHeader('EMPLOYMENT DETAILS'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Role',
                            controller: _roleController,
                            placeholder: 'Designer, Developer...',
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Department',
                            value: _selectedDepartment,
                            items: const [
                              'Operations',
                              'Design',
                              'Tech',
                              'Sales',
                              'Marketing',
                            ],
                            onChanged:
                                (val) => setState(
                                  () =>
                                      _selectedDepartment = val ?? 'Operations',
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Salary Type',
                            value: _selectedSalaryType,
                            items: const ['salary', 'hourly'],
                            onChanged:
                                (val) => setState(
                                  () =>
                                      _selectedSalaryType =
                                          (val ?? 'salary').toLowerCase(),
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 12),
                    _buildFormField(
                      label: 'Weekly Hours Threshold',
                      controller: _weeklyHoursController,
                      placeholder: '40',
                      keyboardType: TextInputType.number,
                      suffix: 'hrs/wk',
                    ),
                    const SizedBox(height: 20),

                    _buildSectionHeader('STATUS & ACCESSIBILITY'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _T.slate100,
                        borderRadius: BorderRadius.circular(_T.r),
                        border: Border.all(color: _T.slate200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Employee Account Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _T.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isActive
                                    ? 'Active employees can log hours and access tools'
                                    : 'Inactive employees are restricted from check-ins',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: _T.slate400,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                            activeColor: _T.green,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _T.slate200, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _T.slate400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      // height: 32,
                      // maximumSize: Size.fromHeight(32),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_T.r),
                      ),
                    ),
                    child:
                        _isSaving
                            ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              isEditing ? 'Save Changes' : 'Create Employee',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
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
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _T.slate400,
        letterSpacing: 0.75,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _T.ink2,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: _T.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 34,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 12.5,
              color: _T.ink,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: _T.slate400, fontSize: 12),
              suffixText: suffix,
              suffixStyle: const TextStyle(color: _T.slate400, fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: _T.surfaceBg,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_T.r),
                borderSide: const BorderSide(color: _T.slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_T.r),
                borderSide: const BorderSide(color: _T.primary, width: 1.5),
              ),
            ),
          ),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _T.ink2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _T.surfaceBg,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _T.slate200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.unfold_more, size: 14, color: _T.slate400),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _T.ink2,
              ),
              items:
                  items
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item[0].toUpperCase() +
                                item.substring(1).toLowerCase(),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: _T.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final isEditing = widget.employee != null;

    try {
      if (isEditing) {
        ref.read(
          updateEmployeeProvider((
            widget.employee!.id,
            {
              'name': _nameController.text,
              'email': _emailController.text,
              'role': _roleController.text,
              'phone': _phoneController.text,
              'department': _selectedDepartment,
              'salaryType': _selectedSalaryType,
              'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0.0,
              'weeklyHoursThreshold':
                  int.tryParse(_weeklyHoursController.text) ?? 40,
              'isActive': _isActive,
            },
          )),
        );
      } else {
        await ref.read(
          createEmployeeProvider({
            'name': _nameController.text,
            'email': _emailController.text,
            'role': _roleController.text,
            'phone': _phoneController.text,
            'department': _selectedDepartment,
            'salaryType': _selectedSalaryType,
            'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0.0,
            'weeklyHoursThreshold':
                int.tryParse(_weeklyHoursController.text) ?? 40,
            'isActive': _isActive,
          }),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Employee updated successfully'
                  : 'Employee created successfully',
            ),
            backgroundColor: _T.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: _T.red,
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
      backgroundColor: _T.surfaceBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_T.rLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _T.slate200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _getAvatarColor(employee.id),
                        child: Text(
                          employee.name.isNotEmpty
                              ? employee.name
                                  .split(' ')
                                  .map((e) => e[0])
                                  .join()
                                  .toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _T.ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              _buildStatusBadge(employee.isActive),
                              const SizedBox(width: 8),
                              Text(
                                'ID: ${employee.id}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _T.slate400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close, size: 18),
                    color: _T.slate400,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Modal Body - Tabbed Layout
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    Container(
                      height: 38,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: _T.slate200, width: 1),
                        ),
                        color: _T.slate100,
                      ),
                      child: const TabBar(
                        labelColor: _T.primary,
                        unselectedLabelColor: _T.slate400,
                        indicatorColor: _T.primary,
                        indicatorWeight: 2,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(text: 'Overview'),
                          Tab(text: 'Attendance'),
                          Tab(text: 'Compensation'),
                        ],
                      ),
                    ),
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

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _T.slate200, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: Navigator.of(context).pop,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _T.slate200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_T.r),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 12,
                        color: _T.ink2,
                        fontWeight: FontWeight.w600,
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

  Widget _buildOverviewTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('PERSONAL INFORMATION', [
            _buildDetailRow('Email', employee.email),
            _buildDetailRow('Department', employee.department),
            _buildDetailRow('Role', employee.role),
          ]),
          const SizedBox(height: 20),
          _buildDetailSection('EMPLOYMENT TERMS', [
            _buildDetailRow('Salary Type', employee.salaryType.toUpperCase()),
            _buildDetailRow(
              'Hourly Rate',
              '\$${employee.hourlyRate.toStringAsFixed(2)} / hr',
            ),
            _buildDetailRow(
              'Weekly Threshold',
              '${employee.weeklyHoursThreshold} hrs',
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('CURRENT SHIFT STATUS', [
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
              'Status',
              employee.isCurrentlyCheckedIn ? 'Checked In' : 'Checked Out',
            ),
          ]),
          const SizedBox(height: 20),
          _buildDetailSection('THIS WEEK PERFORMANCE', [
            _buildDetailRow(
              'Consecutive Days',
              '${employee.consecutiveDaysWorked} days',
            ),
            _buildDetailRow(
              'Overtime Hours',
              '+${employee.currentWeekOvertime?.toStringAsFixed(1) ?? '0'} hrs',
            ),
            _buildDetailRow(
              'Weekend Days',
              '${employee.weekendDaysWorked} days',
            ),
          ]),
          const SizedBox(height: 20),
          _buildDetailSection('RECENT SHIFTS', [
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('PENDING COMPENSATION', [
            _buildDetailRow(
              'Overtime Hours',
              '+${employee.currentWeekOvertime?.toStringAsFixed(1) ?? '0'} hrs',
            ),
            _buildDetailRow(
              'Weekend Days',
              '${employee.weekendDaysWorked} days',
            ),
            _buildDetailRow(
              'Total Estimated Due',
              '\$${((employee.currentWeekOvertime ?? 0) * employee.hourlyRate * 1.5).toStringAsFixed(2)}',
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.primaryBg,
              border: Border.all(color: _T.primaryBorder),
              borderRadius: BorderRadius.circular(_T.r),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: _T.primary, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Compensation calculations are estimates based on standard rate multipliers. Final approval is required prior to payroll entry.',
                    style: TextStyle(
                      color: _T.ink3,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
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
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _T.slate400,
            letterSpacing: 0.75,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _T.surfaceBg,
            border: Border.all(color: _T.slate200),
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: Column(
            children:
                rows.asMap().entries.map((entry) {
                  final isLast = entry.key == rows.length - 1;
                  return Column(
                    children: [
                      entry.value,
                      if (!isLast) const Divider(height: 1, color: _T.slate200),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _T.slate400, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: _T.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftRow(String day, String duration, bool worked) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(color: _T.slate400, fontSize: 12)),
          Text(
            duration,
            style: TextStyle(
              color: worked ? _T.green : _T.slate400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? _T.greenBg : _T.redBg,
        borderRadius: BorderRadius.circular(_T.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? _T.green : _T.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? _T.green : _T.red,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String id) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF10B981),
      const Color(0xFFF97316),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}
