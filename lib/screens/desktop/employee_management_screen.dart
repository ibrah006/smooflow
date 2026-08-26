import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/core/models/employee_with_attendance.dart';
import 'package:smooflow/core/repositories/attendance_repo.dart';
import 'package:smooflow/core/repositories/employee_repo.dart';
import 'package:smooflow/screens/desktop/employee_managment_modals.dart';

// Modern Compact SaaS Design Tokens
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
  static const orange = Color(0xFFF97316);

  static const double r = 6.0;
  static const double rLg = 12.0;
  static const double rPill = 99.0;

  static const double kHeaderHeight = 56.0;
  static const double kSubToolbarHeight = 40.0;
  static const double kTableHeaderHeight = 36.0;
  static const double kTableRowHeight = 46.0;
}

class EmployeeManagementScreen extends ConsumerStatefulWidget {
  const EmployeeManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState
    extends ConsumerState<EmployeeManagementScreen> {
  late TextEditingController _searchController;
  String _sortColumn = 'name';
  bool _sortAscending = true;
  String _selectedStatus = 'all';
  String _selectedDepartment = 'all';
  bool _showFilters = false;
  int? _hoveredRowIndex;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = ref.watch(
      filteredEmployeesProvider(
        FilteredEmployeesParams(
          search: _searchController.text,
          status: _selectedStatus,
          department: _selectedDepartment,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: _T.canvasBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildPageHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSubToolbar(context),
                    if (_showFilters) ...[
                      const SizedBox(height: 12),
                      _buildAdvancedFilters(context),
                    ],
                    const SizedBox(height: 12),
                    filteredEmployees.when(
                      data:
                          (employees) =>
                              _buildEmployeesTable(context, employees),
                      loading: () => _buildLoadingState(),
                      error:
                          (error, st) => _buildErrorState(context, error, st),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Container(
      height: _T.kHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: _T.surfaceBg,
        border: Border(bottom: BorderSide(color: _T.slate200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: _T.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Employee Directory',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _T.ink,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _T.slate100,
                  borderRadius: BorderRadius.circular(_T.rPill),
                ),
                child: const Text(
                  'Management',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _T.slate400,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildSecondaryIconButton(
                icon: Icons.file_download_outlined,
                tooltip: 'Export Data',
                onPressed: () => _showExportDialog(context),
              ),
              const SizedBox(width: 8),
              _buildPrimaryButton(
                label: 'Add Employee',
                icon: Icons.add,
                onPressed: () => _showEmployeeModal(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubToolbar(BuildContext context) {
    return Container(
      height: _T.kSubToolbarHeight + 8,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _T.surfaceBg,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _T.ink,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search employees by name, email, or ID...',
                  hintStyle: const TextStyle(color: _T.slate400, fontSize: 12),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: _T.slate400,
                    size: 16,
                  ),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: _T.slate100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_T.r),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildCompactDropdown<String>(
            value: _selectedStatus,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Statuses')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
            ],
            onChanged: (v) => setState(() => _selectedStatus = v ?? 'all'),
          ),
          const SizedBox(width: 8),
          _buildCompactDropdown<String>(
            value: _selectedDepartment,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Departments')),
              DropdownMenuItem(value: 'operations', child: Text('Operations')),
              DropdownMenuItem(value: 'design', child: Text('Design')),
              DropdownMenuItem(value: 'tech', child: Text('Tech')),
              DropdownMenuItem(value: 'sales', child: Text('Sales')),
            ],
            onChanged: (v) => setState(() => _selectedDepartment = v ?? 'all'),
          ),
          const SizedBox(width: 8),
          Material(
            color: _showFilters ? _T.primaryBg : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(_T.r),
              onTap: () => setState(() => _showFilters = !_showFilters),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _showFilters ? _T.primaryBorder : _T.slate200,
                  ),
                  borderRadius: BorderRadius.circular(_T.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
                      size: 14,
                      color: _showFilters ? _T.primary : _T.ink3,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _showFilters ? _T.primary : _T.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.surfaceBg,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EMPLOYMENT TYPE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _T.slate400,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children:
                      ['Hourly', 'Salary'].map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(
                              type,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_T.r),
                            ),
                            onSelected: (_) {},
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HIRE DATE RANGE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _T.slate400,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'From',
                            hintStyle: const TextStyle(
                              fontSize: 11,
                              color: _T.slate400,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_T.r),
                              borderSide: const BorderSide(color: _T.slate200),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'To',
                            hintStyle: const TextStyle(
                              fontSize: 11,
                              color: _T.slate400,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_T.r),
                              borderSide: const BorderSide(color: _T.slate200),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Align(
            alignment: Alignment.bottomCenter,
            child: TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed:
                  () => setState(() {
                    _searchController.clear();
                    _selectedStatus = 'all';
                    _selectedDepartment = 'all';
                    _showFilters = false;
                  }),
              child: const Text(
                'Reset Filters',
                style: TextStyle(
                  fontSize: 12,
                  color: _T.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesTable(
    BuildContext context,
    List<EmployeeWithAttendance> employees,
  ) {
    final sortedEmployees = _sortEmployees(employees);

    if (sortedEmployees.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      decoration: BoxDecoration(
        color: _T.surfaceBg,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(context),
          const Divider(height: 1, color: _T.slate200, thickness: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedEmployees.length,
            separatorBuilder:
                (_, __) => const Divider(height: 1, color: _T.slate200),
            itemBuilder: (context, index) {
              final employee = sortedEmployees[index];
              return _buildTableRow(context, employee, index);
            },
          ),
          const Divider(height: 1, color: _T.slate200, thickness: 1),
          _buildTableFooter(context, sortedEmployees.length),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      height: _T.kTableHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: _T.slate100,
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            child: Checkbox(
              value: false,
              onChanged: null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildColumnHeader('NAME', 'name')),
          Expanded(flex: 2, child: _buildColumnHeader('EMAIL', 'email')),
          Expanded(flex: 1, child: _buildColumnHeader('DEPT', 'department')),
          Expanded(flex: 1, child: _buildColumnHeader('ROLE', 'role')),
          Expanded(flex: 1, child: _buildColumnHeader('STATUS', 'status')),
          Expanded(flex: 1, child: _buildColumnHeader('SHIFT', 'shift')),
          Expanded(flex: 1, child: _buildColumnHeader('THIS WEEK', 'week')),
          const SizedBox(
            width: 90,
            child: Text(
              'ACTIONS',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _T.slate400,
                letterSpacing: 0.75,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String label, String columnName) {
    final isActive = _sortColumn == columnName;
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortColumn == columnName) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = columnName;
            _sortAscending = true;
          }
        });
      },
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? _T.primary : _T.slate400,
              letterSpacing: 0.75,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 2),
            Icon(
              _sortAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 14,
              color: _T.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    EmployeeWithAttendance employee,
    int index,
  ) {
    final isHovered = _hoveredRowIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: Container(
        height: _T.kTableRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFFFAFAFB) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: employee.isActive ? _T.green : _T.slate300,
              width: 2.75,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Checkbox(
                value: false,
                onChanged: (v) {},
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),

            // Employee Name & ID
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
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
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            color: _T.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: ${employee.id}',
                          style: const TextStyle(
                            color: _T.slate400,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Email
            Expanded(
              flex: 2,
              child: Text(
                employee.email,
                style: const TextStyle(color: _T.ink3, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Department Pill
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _T.slate100,
                    borderRadius: BorderRadius.circular(_T.r),
                  ),
                  child: Text(
                    employee.department,
                    style: const TextStyle(
                      color: _T.ink2,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),

            // Role
            Expanded(
              flex: 1,
              child: Text(
                employee.role,
                style: const TextStyle(color: _T.ink3, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status Badge
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusBadge(employee.isActive),
              ),
            ),

            // Shift Status
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildShiftBadge(employee),
              ),
            ),

            // Week Metrics
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildWeekBadge(employee),
              ),
            ),

            // Quick Actions Toolbar
            SizedBox(
              width: 90,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionIcon(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    onPressed: () => _showEmployeeModal(context, employee),
                  ),
                  _buildActionIcon(
                    icon: Icons.visibility_outlined,
                    tooltip: 'View Details',
                    onPressed: () => _showEmployeeDetails(context, employee),
                  ),
                  _buildActionIcon(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    color: _T.red,
                    onPressed: () => _showDeleteConfirmation(context, employee),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildShiftBadge(EmployeeWithAttendance employee) {
    if (employee.isCurrentlyCheckedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _T.greenBg,
          borderRadius: BorderRadius.circular(_T.rPill),
        ),
        child: const Text(
          'Checked In',
          style: TextStyle(
            color: _T.green,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (employee.lastCheckOut != null) {
      final lastOut = DateFormat('HH:mm').format(employee.lastCheckOut!);
      return Text(
        'Out @ $lastOut',
        style: const TextStyle(color: _T.slate400, fontSize: 11),
      );
    }
    return const Text('--', style: TextStyle(color: _T.slate400, fontSize: 11));
  }

  Widget _buildWeekBadge(EmployeeWithAttendance employee) {
    if ((employee.currentWeekOvertime ?? 0) > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _T.amberBg,
          borderRadius: BorderRadius.circular(_T.rPill),
        ),
        child: Text(
          '+${employee.currentWeekOvertime?.toStringAsFixed(1)}h OT',
          style: const TextStyle(
            color: _T.amber,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if ((employee.weekendDaysWorked ?? 0) > 0) {
      return Text(
        '${employee.weekendDaysWorked}d weekend',
        style: const TextStyle(color: _T.ink3, fontSize: 11),
      );
    }

    return const Text(
      'On track',
      style: TextStyle(color: _T.slate400, fontSize: 11),
    );
  }

  Widget _buildTableFooter(BuildContext context, int totalCount) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $totalCount total ${totalCount == 1 ? 'record' : 'records'}',
            style: const TextStyle(
              color: _T.slate400,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  size: 16,
                  color: _T.slate400,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _T.primaryBg,
                  borderRadius: BorderRadius.circular(_T.r),
                ),
                child: const Text(
                  '1',
                  style: TextStyle(
                    color: _T.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: _T.slate400,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _T.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        // height: 32,
        fixedSize: Size.fromHeight(32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.r),
        ),
      ),
    );
  }

  Widget _buildSecondaryIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: _T.surfaceBg,
          border: Border.all(color: _T.slate200),
          borderRadius: BorderRadius.circular(_T.r),
        ),
        child: IconButton(
          icon: Icon(icon, size: 16, color: _T.ink2),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = _T.slate400,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 15, color: color),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildCompactDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _T.surfaceBg,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.unfold_more, size: 14, color: _T.slate400),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _T.ink2,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: _T.surfaceBg,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: _T.primary),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, StackTrace st) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _T.surfaceBg,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32, color: _T.red),
          const SizedBox(height: 8),
          const Text(
            'Failed to load employees',
            style: TextStyle(
              color: _T.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            style: const TextStyle(color: _T.slate400, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.invalidate(employeesProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.primary,
              // height: 30,
              fixedSize: Size.fromHeight(30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_T.r),
              ),
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: _T.surfaceBg,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 40, color: _T.slate400),
          const SizedBox(height: 12),
          const Text(
            'No matching employees found',
            style: TextStyle(
              color: _T.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adjust your search queries or active status filter.',
            style: TextStyle(color: _T.slate400, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildPrimaryButton(
            label: 'Add Employee',
            icon: Icons.add,
            onPressed: () => _showEmployeeModal(context),
          ),
        ],
      ),
    );
  }

  List<EmployeeWithAttendance> _sortEmployees(
    List<EmployeeWithAttendance> employees,
  ) {
    final sorted = [...employees];
    sorted.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'email':
          comparison = a.email.compareTo(b.email);
          break;
        case 'department':
          comparison = a.department.compareTo(b.department);
          break;
        case 'role':
          comparison = a.role.compareTo(b.role);
          break;
        case 'status':
          comparison = (a.isActive ? 1 : 0).compareTo(b.isActive ? 1 : 0);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });
    return sorted;
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

  void _showEmployeeModal(
    BuildContext context, [
    EmployeeWithAttendance? employee,
  ]) {
    showDialog(
      context: context,
      builder: (context) => EmployeeFormModal(employee: employee),
    ).then((result) {
      if (result == true) {
        ref.invalidate(employeesProvider);
      }
    });
  }

  void _showEmployeeDetails(
    BuildContext context,
    EmployeeWithAttendance employee,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${employee.name}')),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    EmployeeWithAttendance employee,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: _T.surfaceBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_T.rLg),
            ),
            title: const Text(
              'Delete Employee',
              style: TextStyle(
                color: _T.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            content: Text(
              'Are you sure you want to delete ${employee.name}? This action cannot be undone.',
              style: const TextStyle(color: _T.ink3, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: _T.slate400),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_T.r),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteEmployee(employee);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _deleteEmployee(EmployeeWithAttendance employee) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${employee.name}'),
        backgroundColor: _T.green,
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }
}
