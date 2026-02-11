// production_dashboard_screen.concept.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductionDashboardScreen extends StatefulWidget {
  final int activePrinters;
  final int totalPrintJobs;
  final int lowStockItems;
  final List<Map<String, dynamic>> printers;
  final List<Map<String, dynamic>> todaysSchedule;
  final VoidCallback? onSchedulePressed;
  final VoidCallback? onPrintersPressed;
  final VoidCallback? onInventoryPressed;

  const ProductionDashboardScreen({
    Key? key,
    this.activePrinters = 1,
    this.totalPrintJobs = 24,
    this.lowStockItems = 0,
    this.printers = const [],
    this.todaysSchedule = const [],
    this.onSchedulePressed,
    this.onPrintersPressed,
    this.onInventoryPressed,
  }) : super(key: key);

  @override
  State<ProductionDashboardScreen> createState() =>
      _ProductionDashboardScreenState();
}

class _ProductionDashboardScreenState extends State<ProductionDashboardScreen> {
  String selectedFilter = 'All';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              child: Padding(
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
                            title: 'Active Printers',
                            value: widget.activePrinters.toString(),
                            icon: Icons.print_rounded,
                            iconColor: Color(0xFF2563EB),
                            backgroundColor: Color(0xFFEFF6FF),
                            trend: '+2 this week',
                            trendPositive: true,
                            onTap: widget.onPrintersPressed,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Print Jobs',
                            value: widget.totalPrintJobs.toString(),
                            icon: Icons.assignment_rounded,
                            iconColor: Color(0xFF10B981),
                            backgroundColor: Color(0xFFECFDF5),
                            trend: '18 in queue',
                            trendPositive: null,
                            onTap: widget.onSchedulePressed,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildFullWidthMetricCard(
                      title: 'Inventory Status',
                      value: widget.lowStockItems.toString(),
                      subtitle: 'Items need attention',
                      icon: Icons.inventory_2_rounded,
                      iconColor: widget.lowStockItems > 0
                          ? Color(0xFFF59E0B)
                          : Color(0xFF10B981),
                      backgroundColor: widget.lowStockItems > 0
                          ? Color(0xFFFEF3C7)
                          : Color(0xFFECFDF5),
                      actionLabel: 'View Inventory',
                      onTap: widget.onInventoryPressed,
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
                          onPressed: widget.onPrintersPressed,
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
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 1),
                          SizedBox(width: 8),
                          _buildFilterChip('Active', 1),
                          SizedBox(width: 8),
                          _buildFilterChip('Blocked', 0),
                          SizedBox(width: 8),
                          _buildFilterChip('Maintenance', 0),
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
                  children: widget.printers.isEmpty
                      ? [_buildEmptyPrintersState()]
                      : widget.printers
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
                child: widget.todaysSchedule.isEmpty
                    ? _buildEmptyScheduleState()
                    : Column(
                        children: widget.todaysSchedule
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
        onPressed: widget.onSchedulePressed,
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

  Widget _buildPrinterCard(Map<String, dynamic> printer) {
    final bool isActive = printer['status'] == 'Active';
    final String name = printer['name'] ?? 'Unknown Printer';
    final String section = printer['section'] ?? 'No Section';
    final int? currentJob = printer['currentJob'];
    final double? progress = printer['progress'];

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
              color: isActive
                  ? Color(0xFFECFDF5)
                  : Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.print_rounded,
              color: isActive
                  ? Color(0xFF10B981)
                  : Color(0xFF94A3B8),
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
                        color: isActive
                            ? Color(0xFF10B981)
                            : Color(0xFF94A3B8),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      printer['status'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Color(0xFF10B981)
                            : Color(0xFF64748B),
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
                if (currentJob != null && progress != null) ...[
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
                            '${(progress * 100).toInt()}%',
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
                          value: progress,
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

  Widget _buildScheduleCard(Map<String, dynamic> job) {
    final String taskName = job['taskName'] ?? 'Unnamed Task';
    final String printerName = job['printerName'] ?? 'Unknown Printer';
    final DateTime? startTime = job['startTime'];
    final int? duration = job['duration'];
    final String status = job['status'] ?? 'scheduled';

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'in_progress':
        statusColor = Color(0xFF2563EB);
        statusBgColor = Color(0xFFEFF6FF);
        statusIcon = Icons.play_circle_filled;
        break;
      case 'completed':
        statusColor = Color(0xFF10B981);
        statusBgColor = Color(0xFFECFDF5);
        statusIcon = Icons.check_circle;
        break;
      case 'delayed':
        statusColor = Color(0xFFEF4444);
        statusBgColor = Color(0xFFFEE2E2);
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Color(0xFF64748B);
        statusBgColor = Color(0xFFF1F5F9);
        statusIcon = Icons.schedule;
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
                      status.replaceAll('_', ' ').toUpperCase(),
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
              if (startTime != null)
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
              if (duration != null) ...[
                SizedBox(width: 12),
                Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  '$duration min',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
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