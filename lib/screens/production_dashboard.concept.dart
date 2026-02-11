// production_dashboard_screen.concept.dart
// Populated with realistic sample data based on actual implementation

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/extensions/duration_format.dart';
import 'package:smooflow/helpers/task_component_helper.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';

class ProductionDashboardScreen extends ConsumerStatefulWidget {

  const ProductionDashboardScreen({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ProductionDashboardScreen> createState() =>
      _ProductionDashboardScreenState();
}

class _ProductionDashboardScreenState extends ConsumerState<ProductionDashboardScreen> {
  String selectedFilter = 'All';

  List<Printer> get printers=> ref.watch(printerNotifierProvider).printers; 
  List<Task> get totalPrintJobs => ref.watch(taskNotifierProvider).where(
    (task) => task.status == TaskStatus.clientApproved || task.status == TaskStatus.printing || task.status == TaskStatus.finishing || task.status == TaskStatus.blocked).toList(); // clientApproved + printing + finishing + blocked
  int get printJobsInQueue => totalPrintJobs.where((task) => task.status == TaskStatus.clientApproved).length; // clientApproved
  int get lowStockItems => ref.watch(materialNotifierProvider).materials.where((item) => item.isLowStock).length; // Materials with isLow = true
  // Available printers (active AND not busy)
  List<Printer> get availablePrinters => printers.where((printer)=> printer.isActive && !printer.isBusy).toList();
  int get busyPrintersCount => printers.where((printer) => printer.isActive && printer.isBusy).length;
  int get maintenancePrintersCount => printers.where((printer) => printer.status == PrinterStatus.maintenance).length;
  // Today's schedule - tasks that are scheduled for today
  List<Task> get todaysSchedule => ref.watch(taskNotifierProvider.notifier).todaysProductionTasks;

  void onSchedulePressed () {
    AppRoutes.navigateTo(context, AppRoutes.schedulePrintStages);
  }
  void onPrintersPressed () {

  }
  void onInventoryPressed () {

  }

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });

    Future.microtask(() async {
      await ref.watch(projectNotifierProvider.notifier).load(projectsLastAddedLocal: null);
      await ref.watch(printerNotifierProvider.notifier).fetchPrinters();
      await ref.watch(materialNotifierProvider.notifier).fetchMaterials();
      await ref.watch(taskNotifierProvider.notifier).loadAll();
      await ref.watch(materialNotifierProvider.notifier).fetchMaterials();
      await ref.watch(taskNotifierProvider.notifier).fetchProductionScheduleToday();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.dashboard_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: Color(0xFF475569),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Search Bar
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search jobs, printers, materials...',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF64748B),
                            size: 22,
                          ),
                          suffixIcon: Container(
                            margin: EdgeInsets.all(6),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Container(
                color: Color(0xFFF8FAFC),
                padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Production Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Available Printers',
                            value: availablePrinters.length.toString(),
                            icon: Icons.print_rounded,
                            iconColor: Color(0xFF2563EB),
                            backgroundColor: Color(0xFFEFF6FF),
                            trend: '$busyPrintersCount busy',
                            trendPositive: null,
                            onTap: onPrintersPressed,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Print Jobs',
                            value: totalPrintJobs.length.toString(),
                            icon: Icons.assignment_rounded,
                            iconColor: Color(0xFF10B981),
                            backgroundColor: Color(0xFFECFDF5),
                            trend: '$printJobsInQueue in queue',
                            trendPositive: null,
                            onTap: onSchedulePressed,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildFullWidthMetricCard(
                      title: 'Inventory Status',
                      value: lowStockItems.toString(),
                      subtitle: 'Items need attention',
                      icon: Icons.inventory_2_rounded,
                      iconColor: lowStockItems > 0
                          ? Color(0xFFF59E0B)
                          : Color(0xFF10B981),
                      backgroundColor: lowStockItems > 0
                          ? Color(0xFFFEF3C7)
                          : Color(0xFFECFDF5),
                      actionLabel: 'View Inventory',
                      onTap: onInventoryPressed,
                    ),
                  ],
                ),
              ),
            ),

            // Printer Status Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Printer Fleet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: onPrintersPressed,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Filter Chips - Updated filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', printers.length),
                          SizedBox(width: 8),
                          _buildFilterChip('Available', availablePrinters.length),
                          SizedBox(width: 8),
                          if (busyPrintersCount > 0) _buildFilterChip('Busy', busyPrintersCount),
                          SizedBox(width: 8),
                          if (maintenancePrintersCount > 0) _buildFilterChip('Maintenance', maintenancePrintersCount),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Printers List
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: printers.isEmpty
                      ? [_buildEmptyPrintersState()]
                      : printers
                          .map((printer) => Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: _buildPrinterCard(printer),
                              ))
                          .toList(),
                ),
              ),
            ),

            // Today's Schedule Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Today\'s Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Schedule List
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: todaysSchedule.isEmpty
                    ? _buildEmptyScheduleState()
                    : Column(
                        children: todaysSchedule
                            .map((job) => Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: _buildScheduleCard(job),
                                ))
                            .toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onSchedulePressed,
        backgroundColor: Color(0xFF2563EB),
        elevation: 4,
        icon: Icon(Icons.add_rounded, size: 24),
        label: Text(
          'Schedule Job',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    String? trend,
    bool? trendPositive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -1,
                height: 1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                letterSpacing: -0.1,
              ),
            ),
            if (trend != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  if (trendPositive != null)
                    Icon(
                      trendPositive
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 14,
                      color: trendPositive
                          ? Color(0xFF10B981)
                          : Color(0xFFEF4444),
                    ),
                  if (trendPositive != null) SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trend,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: trendPositive == null
                            ? Color(0xFF64748B)
                            : (trendPositive
                                ? Color(0xFF10B981)
                                : Color(0xFFEF4444)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                      letterSpacing: -0.1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.8,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 8),
                      Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (actionLabel != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Color(0xFF2563EB) : Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2563EB).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Color(0xFF475569),
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterCard(Printer printer) {
    final String status = printer.statusName;
    final bool isBusy = printer.isBusy;
    final bool isAvailable = printer.isActive && !printer.isBusy;
    final bool isMaintenance = printer.status == PrinterStatus.maintenance;
    
    final String name = printer.name;
    final String section = printer.location?? "No Section";
    final int? currentJob = printer.currentJobId;

    Color statusColor;
    Color statusBgColor;
    
    if (isBusy) {
      statusColor = Color(0xFF2563EB);
      statusBgColor = Color(0xFFEFF6FF);
    } else if (isAvailable) {
      statusColor = Color(0xFF10B981);
      statusBgColor = Color(0xFFECFDF5);
    } else if (isMaintenance) {
      statusColor = Color(0xFFF59E0B);
      statusBgColor = Color(0xFFFEF3C7);
    } else {
      statusColor = Color(0xFF94A3B8);
      statusBgColor = Color(0xFFF1F5F9);
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.print_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    SizedBox(width: 8),
                    Text(
                      section,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                // Only show progress for busy printers
                if (isBusy && currentJob != null) ...[
                  SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Job #$currentJob',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Spacer(),
                          Text(
                            '65%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.65,
                          backgroundColor: Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2563EB),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Task job) {
    final String taskName = job.name;
    late final String printerName;
    try {
      printerName = job.printerId!=null ? printers.firstWhere((p) => p.id == job.printerId).name : 'Unassigned';
    } catch(e) {
      printerName = "Updating Printer...";
    }

    final DateTime? startTime = job.actualProductionStartTime;

    final TaskComponentHelper componentHelper = job.componentHelper();
    String statusLabel = componentHelper.labelTitle;
    IconData statusIcon = componentHelper.icon;
    Color statusColor = componentHelper.color;
    Color statusBgColor = componentHelper.color.withOpacity(0.1);

    // Calculate time display based on status
    String timeDisplay = startTime != null && job.actualProductionEndTime != null?
      // If production has ended, show total duration
      job.actualProductionEndTime?.difference(startTime).formatTime?? 'Just finished'
      // If production has started but not ended, show how long it's been running
      : startTime != null? startTime.eventAgo
      : 'Not Started';

    // Production Progress
    bool isInProgress = job.status == TaskStatus.printing;
    bool isProductionCompleted = startTime != null && job.actualProductionEndTime != null;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              if (startTime != null && !isInProgress && !isProductionCompleted)
                Text(
                  DateFormat('HH:mm').format(startTime),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            taskName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.print_rounded, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text(
                printerName,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  timeDisplay,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrintersState() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.print_disabled_rounded,
              size: 32,
              color: Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No Printers Available',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add printers to start managing production',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleState() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_outlined,
              size: 32,
              color: Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No print jobs scheduled for today',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Schedule new jobs to fill your production day',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}