import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/core/models/employee_with_attendance.dart';
import 'package:smooflow/core/repositories/attendance_repo.dart';
import 'package:smooflow/core/repositories/employee_repo.dart';
import 'package:smooflow/screens/desktop/employee_managment_modals.dart';

// Design constants aligned with Smooflow
const double _kMaxWidth = 1400;
const double _kSidebarWidth = 280;
const double _kTableRowHeight = 52;
const double _rSmall = 4;
const double _rMedium = 6;
const double _rLarge = 8;
const double _rXL = 12;

// Color palette (Smooflow)
class _T {
  // Background colors
  static const bgPrimary = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF8F9FB);
  static const bgTertiary = Color(0xF5F7FA);
  static const bgHover = Color(0xFFF0F2F5);

  // Text colors
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textInverse = Color(0xFFFFFFFF);

  // Border colors
  static const borderLight = Color(0xFFE5E7EB);
  static const borderMedium = Color(0xFFD1D5DB);

  // Status colors
  static const statusActive = Color(0xFF10B981);
  static const statusInactive = Color(0xFFEF4444);
  static const statusPending = Color(0xFFF59E0B);
  static const statusWarning = Color(0xFFDC2626);

  // Accent colors
  static const accentBlue = Color(0xFF3B82F6);
  static const accentGreen = Color(0xFF10B981);
  static const accentOrange = Color(0xFFF97316);

  // Shadows
  static const shadowSm = Color(0x0A000000);
  static const shadowMd = Color(0x0F000000);
  static const shadowLg = Color(0x1A000000);
}

// ============================================
// EMPLOYEES MANAGEMENT SCREEN
// ============================================

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
  String _selectedStatus = 'all'; // 'all', 'active', 'inactive'
  String _selectedDepartment = 'all';
  bool _showFilters = false;

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
      backgroundColor: _T.bgSecondary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Container(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _kMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(context),
                        const SizedBox(height: 32),

                        // Search & Filter Bar
                        _buildSearchAndFilterBar(context),
                        const SizedBox(height: 24),

                        // Advanced Filters (Collapsible)
                        if (_showFilters) ...[
                          _buildAdvancedFilters(context),
                          const SizedBox(height: 24),
                        ],

                        // Employees Table or Loading/Error State
                        filteredEmployees.when(
                          data:
                              (employees) => Column(
                                children: [
                                  _buildEmployeesTable(context, employees),
                                ],
                              ),
                          loading: () => _buildLoadingState(),
                          error:
                              (error, st) =>
                                  _buildErrorState(context, error, st),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employees',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: _T.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage and track your team',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _T.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            // Action buttons
            Row(
              children: [
                _buildIconButton(
                  icon: Icons.download_outlined,
                  tooltip: 'Export',
                  onPressed: () => _showExportDialog(context),
                ),
                const SizedBox(width: 12),
                _buildPrimaryButton(
                  label: 'Add Employee',
                  icon: Icons.add_rounded,
                  onPressed: () => _showEmployeeModal(context),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.bgPrimary,
        border: Border.all(color: _T.borderLight),
        borderRadius: BorderRadius.circular(_rLarge),
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or ID...',
                hintStyle: TextStyle(color: _T.textTertiary),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: _T.textTertiary,
                    size: 20,
                  ),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),

          // Status filter dropdown
          DropdownButton<String>(
            value: _selectedStatus,
            underline: SizedBox.shrink(),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(
                  'All Status',
                  style: TextStyle(color: _T.textPrimary, fontSize: 14),
                ),
              ),
              DropdownMenuItem(
                value: 'active',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _T.statusActive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active',
                      style: TextStyle(color: _T.textPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'inactive',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _T.statusInactive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Inactive',
                      style: TextStyle(color: _T.textPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value ?? 'all');
            },
          ),
          const SizedBox(width: 12),

          // Department filter dropdown
          DropdownButton<String>(
            value: _selectedDepartment,
            underline: SizedBox.shrink(),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(
                  'All Departments',
                  style: TextStyle(color: _T.textPrimary, fontSize: 14),
                ),
              ),
              DropdownMenuItem(
                value: 'operations',
                child: Text(
                  'Operations',
                  style: TextStyle(color: _T.textPrimary, fontSize: 14),
                ),
              ),
              DropdownMenuItem(
                value: 'design',
                child: Text(
                  'Design',
                  style: TextStyle(color: _T.textPrimary, fontSize: 14),
                ),
              ),
              DropdownMenuItem(
                value: 'tech',
                child: Text(
                  'Tech',
                  style: TextStyle(color: _T.textPrimary, fontSize: 14),
                ),
              ),
              DropdownMenuItem(
                value: 'sales',
                child: Text(
                  'Sales',
                  style: TextStyle(color: _T.textPrimary, fontSize: 14),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedDepartment = value ?? 'all');
            },
          ),
          const SizedBox(width: 12),

          // Advanced filters toggle
          Tooltip(
            message: 'Advanced filters',
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  border: Border.all(color: _T.borderLight),
                  borderRadius: BorderRadius.circular(_rMedium),
                ),
                child: InkWell(
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  borderRadius: BorderRadius.circular(_rMedium),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _showFilters ? Icons.tune_rounded : Icons.tune_outlined,
                      color: _T.textSecondary,
                      size: 20,
                    ),
                  ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.bgPrimary,
        border: Border.all(color: _T.borderLight),
        borderRadius: BorderRadius.circular(_rLarge),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employment Type',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _T.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children:
                      ['Hourly', 'Salary'].map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: FilterChip(
                            label: Text(type),
                            onSelected: (selected) {},
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hire Date Range',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _T.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'From',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_rMedium),
                            borderSide: BorderSide(
                              color: _T.borderLight,
                              width: 1,
                            ),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'To',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_rMedium),
                            borderSide: BorderSide(
                              color: _T.borderLight,
                              width: 1,
                            ),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Align(
            alignment: Alignment.bottomCenter,
            child: TextButton(
              onPressed:
                  () => setState(() {
                    _searchController.clear();
                    _selectedStatus = 'all';
                    _selectedDepartment = 'all';
                    _showFilters = false;
                  }),
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: _T.accentBlue,
                  fontWeight: FontWeight.w500,
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
    // Sort employees
    final sortedEmployees = _sortEmployees(employees);

    return Container(
      decoration: BoxDecoration(
        color: _T.bgPrimary,
        border: Border.all(color: _T.borderLight),
        borderRadius: BorderRadius.circular(_rLarge),
        boxShadow: [
          BoxShadow(
            color: _T.shadowSm,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          _buildTableHeader(context),
          Divider(height: 1, color: _T.borderLight, thickness: 1),

          // Table rows
          ...sortedEmployees.asMap().entries.map((entry) {
            final index = entry.key;
            final employee = entry.value;
            final isEven = index % 2 == 0;
            return _buildTableRow(context, employee, isEven);
          }).toList(),

          // Footer
          Divider(height: 1, color: _T.borderLight, thickness: 1),
          _buildTableFooter(context, sortedEmployees.length),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: _T.bgTertiary,
      height: _kTableRowHeight,
      child: Row(
        children: [
          // Checkbox for select all
          SizedBox(
            width: 24,
            child: Checkbox(
              value: false,
              onChanged: (value) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 16),

          // Name column
          Expanded(flex: 2, child: _buildColumnHeader('Name', 'name', context)),

          // Email column
          Expanded(
            flex: 2,
            child: _buildColumnHeader('Email', 'email', context),
          ),

          // Department column
          Expanded(
            flex: 1,
            child: _buildColumnHeader('Department', 'department', context),
          ),

          // Role column
          Expanded(flex: 1, child: _buildColumnHeader('Role', 'role', context)),

          // Status column
          Expanded(
            flex: 1,
            child: _buildColumnHeader('Status', 'status', context),
          ),

          // Current Shift column
          Expanded(
            flex: 1,
            child: _buildColumnHeader('Current Shift', 'shift', context),
          ),

          // This Week column
          Expanded(
            flex: 1,
            child: _buildColumnHeader('This Week', 'week', context),
          ),

          // Actions
          SizedBox(
            width: 100,
            child: Text(
              'Actions',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _T.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(
    String label,
    String columnName,
    BuildContext context,
  ) {
    final isActive = _sortColumn == columnName;

    return GestureDetector(
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isActive ? _T.textPrimary : _T.textSecondary,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 14,
              color: _T.textPrimary,
            ),
          ],
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
          comparison = a.isActive ? 1 : -1;
          break;
        default:
          comparison = 0;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return sorted;
  }

  Widget _buildTableRow(
    BuildContext context,
    EmployeeWithAttendance employee,
    bool isEven,
  ) {
    return MouseRegion(
      child: Container(
        color: isEven ? Colors.transparent : _T.bgTertiary.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        height: _kTableRowHeight,
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 24,
              child: Checkbox(
                value: false,
                onChanged: (value) {},
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 16),

            // Name with avatar
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _getAvatarColor(employee.id),
                    child: Text(
                      employee.name
                          .split(' ')
                          .map((e) => e[0])
                          .join()
                          .toUpperCase(),
                      style: const TextStyle(
                        color: _T.textInverse,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: TextStyle(
                            color: _T.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          employee.id,
                          style: TextStyle(
                            color: _T.textTertiary,
                            fontSize: 11,
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
                style: TextStyle(color: _T.textSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Department
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDepartmentColor(
                    employee.department,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_rSmall),
                ),
                child: Text(
                  employee.department,
                  style: TextStyle(
                    color: _getDepartmentColor(employee.department),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Role
            Expanded(
              flex: 1,
              child: Text(
                employee.role,
                style: TextStyle(color: _T.textSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status
            Expanded(flex: 1, child: _buildStatusBadge(employee.isActive)),

            // Current Shift
            Expanded(flex: 1, child: _buildShiftBadge(employee)),

            // This Week
            Expanded(flex: 1, child: _buildWeekBadge(employee)),

            // Actions
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    onPressed: () => _showEmployeeModal(context, employee),
                    size: 18,
                    padding: 6,
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.visibility_outlined,
                    tooltip: 'View Details',
                    onPressed: () => _showEmployeeDetails(context, employee),
                    size: 18,
                    padding: 6,
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete',
                    onPressed: () => _showDeleteConfirmation(context, employee),
                    size: 18,
                    padding: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? _T.statusActive : _T.statusInactive).withOpacity(
          0.1,
        ),
        borderRadius: BorderRadius.circular(_rSmall),
        border: Border.all(
          color: (isActive ? _T.statusActive : _T.statusInactive).withOpacity(
            0.3,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? _T.statusActive : _T.statusInactive,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? _T.statusActive : _T.statusInactive,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftBadge(EmployeeWithAttendance employee) {
    if (employee.isCurrentlyCheckedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _T.accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_rSmall),
          border: Border.all(color: _T.accentGreen.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _T.accentGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Checked In',
              style: TextStyle(
                color: _T.accentGreen,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (employee.lastCheckOut != null) {
      final lastOut = DateFormat('HH:mm').format(employee.lastCheckOut!);
      return Text(
        'Out at $lastOut',
        style: TextStyle(color: _T.textTertiary, fontSize: 12),
      );
    }

    return Text('--', style: TextStyle(color: _T.textTertiary, fontSize: 12));
  }

  Widget _buildWeekBadge(EmployeeWithAttendance employee) {
    if ((employee.currentWeekOvertime ?? 0) > 0) {
      return Tooltip(
        message: '${employee.currentWeekOvertime} hours overtime',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _T.statusWarning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_rSmall),
          ),
          child: Text(
            '+${employee.currentWeekOvertime?.toStringAsFixed(1)}h OT',
            style: TextStyle(
              color: _T.statusWarning,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if ((employee.weekendDaysWorked ?? 0) > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _T.statusPending.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_rSmall),
        ),
        child: Text(
          '${employee.weekendDaysWorked} weekends',
          style: TextStyle(
            color: _T.statusPending,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Text(
      'On track',
      style: TextStyle(
        color: _T.statusActive,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTableFooter(BuildContext context, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $totalCount ${totalCount == 1 ? 'employee' : 'employees'}',
            style: TextStyle(color: _T.textSecondary, fontSize: 13),
          ),
          Row(
            children: [
              _buildIconButton(
                icon: Icons.navigate_before_rounded,
                tooltip: 'Previous',
                onPressed: () {},
                size: 18,
                padding: 8,
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _T.accentBlue,
                  borderRadius: BorderRadius.circular(_rSmall),
                ),
                child: Text(
                  '1',
                  style: TextStyle(
                    color: _T.textInverse,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.navigate_next_rounded,
                tooltip: 'Next',
                onPressed: () {},
                size: 18,
                padding: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: _T.bgPrimary,
        border: Border.all(color: _T.borderLight),
        borderRadius: BorderRadius.circular(_rLarge),
      ),
      padding: const EdgeInsets.all(40),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _T.bgPrimary,
        border: Border.all(color: _T.borderLight),
        borderRadius: BorderRadius.circular(_rLarge),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: _T.statusInactive),
          const SizedBox(height: 16),
          Text(
            'Error loading employees',
            style: TextStyle(
              color: _T.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: _T.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(employeesProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.accentBlue,
              foregroundColor: _T.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.bgPrimary,
        border: Border.all(color: _T.borderLight),
        borderRadius: BorderRadius.circular(_rLarge),
      ),
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: _T.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No employees found',
            style: TextStyle(
              color: _T.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add your first employee',
            style: TextStyle(color: _T.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            label: 'Add Employee',
            icon: Icons.add_rounded,
            onPressed: () => _showEmployeeModal(context),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPER METHODS & DIALOGS
  // ============================================

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: _T.accentBlue,
          borderRadius: BorderRadius.circular(_rMedium),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_rMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: _T.textInverse, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: _T.textInverse,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    double size = 20,
    double padding = 8,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_rMedium),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(_rMedium),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Icon(icon, color: _T.textSecondary, size: size),
            ),
          ),
        ),
      ),
    );
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

  Color _getDepartmentColor(String department) {
    switch (department.toLowerCase()) {
      case 'operations':
        return _T.accentBlue;
      case 'design':
        return _T.accentOrange;
      case 'tech':
        return _T.accentGreen;
      case 'sales':
        return const Color(0xFFEC4899);
      default:
        return _T.textSecondary;
    }
  }

  void _showEmployeeModal(
    BuildContext context, [
    EmployeeWithAttendance? employee,
  ]) {
    // OPEN ITEM: Import and show EmployeeFormModal from employee_management_modals.dart
    // showDialog(
    //   context: context,
    //   builder: (context) => EmployeeFormModal(employee: employee),
    // ).then((result) {
    //   if (result == true) {
    //     ref.invalidate(employeesProvider);
    //   }
    // });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          employee != null
              ? 'Edit mode - Import EmployeeFormModal'
              : 'Add mode - Import EmployeeFormModal',
        ),
      ),
    );
  }

  void _showEmployeeDetails(
    BuildContext context,
    EmployeeWithAttendance employee,
  ) {
    // OPEN ITEM: Import and show EmployeeDetailsModal from employee_management_modals.dart
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
            backgroundColor: _T.bgPrimary,
            title: Text(
              'Delete Employee?',
              style: TextStyle(
                color: _T.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Are you sure you want to delete ${employee.name}? This action cannot be undone.',
              style: TextStyle(color: _T.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text(
                  'Cancel',
                  style: TextStyle(color: _T.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteEmployee(employee);
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: _T.statusInactive),
                ),
              ),
            ],
          ),
    );
  }

  void _deleteEmployee(EmployeeWithAttendance employee) {
    // OPEN ITEM: Call delete API
    // ref.read(deleteEmployeeProvider(employee.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${employee.name}'),
        backgroundColor: _T.statusActive,
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    // OPEN ITEM: Implement export to CSV/PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }
}
