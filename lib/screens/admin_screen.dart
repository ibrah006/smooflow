// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:smooflow/constants.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/project_args.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/settings_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  String _selectedPeriod = 'Today';
  int _currentTabIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // This will initialize current organization on local level
    // So that invite member screen has access to current organization
    Future.microtask(() async {
      await ref.watch(organizationNotifierProvider.notifier).getCurrentOrganization;
      await ref.watch(printerNotifierProvider.notifier).fetchPrinters();

      await ref.watch(materialNotifierProvider.notifier).fetchStockPercentage();

      // Get active projects (and counts), pending projects counts, finished projects counts
      await ref.watch(projectNotifierProvider.notifier).fetchProjectsOverallStatus();

      setState(() {
        
      });
    });

    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTabIndex = _tabController.index);
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final printers = ref.watch(printerNotifierProvider).printers;

    final materialStockPercentage = ref.watch(materialNotifierProvider).stockStats?.percentage;

    print("printers: $printers");

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 50),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: SafeArea(
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ).copyWith(right: 5),
                      child: Image.asset("assets/icons/app_icon.png"),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      margin: EdgeInsets.only(bottom: 4, right: 2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 90, 132, 222),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Smooflow Management',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                      Positioned(
                        top: 11,
                        right: 11,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Minimal Header
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Clean Tab Bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    dividerColor: Colors.black12,
                    labelColor: const Color(0xFF2563EB),
                    unselectedLabelColor: const Color(0xFF9CA3AF),
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorColor: const Color(0xFF2563EB),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Dashboard'),
                      Tab(text: 'Projects'),
                      Tab(text: 'Team'),
                      Tab(text: 'Reports'),
                      Tab(text: 'Settings'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(materialStockPercentage),
                _buildProjectsTab(),
                _buildTeamTab(),
                _buildReportsTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(double? materialStockPercentage) {

    final activePrintersCount = ref.watch(printerNotifierProvider).activePrinters.length;
    final totalPrintersCount = ref.watch(printerNotifierProvider).totalPrintersCount;

    final overallStatus = ref.watch(projectNotifierProvider.notifier).projectsOverallStatus;
    final projectsThisMonth = overallStatus.countThisMonth;
    final projectsIncreaseWRTPrevMonth = overallStatus.increaseWRTPrevMonth;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Period Filter - Minimal Pills
        Row(
          children: [
            Expanded(child: _buildPeriodTab('Today')),
            const SizedBox(width: 10),
            Expanded(child: _buildPeriodTab('This Week')),
            const SizedBox(width: 10),
            Expanded(child: _buildPeriodTab('This Month')),
          ],
        ),

        const SizedBox(height: 24),

        // Key Metrics - Clean Cards
        _buildMetricCard('\$24,580', 'Revenue', '+12.5%', true),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _buildMetricCard(projectsThisMonth.toString(), 'Projects', '${projectsIncreaseWRTPrevMonth>0?"+":""}${projectsIncreaseWRTPrevMonth.toString()}', projectsIncreaseWRTPrevMonth>=0)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('94%', 'Efficiency', '+5%', true)),
          ],
        ),

        const SizedBox(height: 32),

        // Quick Actions
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                Icons.add_business_rounded,
                'New Project',
                () {
                  AppRoutes.navigateTo(context, AppRoutes.addProject);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                Icons.person_add_rounded,
                'Add Staff',
                () {
                  AppRoutes.navigateTo(context, AppRoutes.inviteMember);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                Icons.inventory_rounded,
                'Stock Entry',
                () {
                  // Select material before navigating to stock entry screen
                  // AppRoutes.navigateTo(context, AppRoutes.stockInEntry, arguments: StockEntryArgs.stockIn(material: ));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                Icons.print_rounded,
                'Add Printer',
                () {
                  AppRoutes.navigateTo(context, AppRoutes.addPrinter);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Production Overview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Production Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _buildProductionMetric(
                Icons.print_rounded,
                'Active Printers',
                '$activePrintersCount/$totalPrintersCount',
                activePrintersCount/(totalPrintersCount==0? 1 : totalPrintersCount),
              ),
              const SizedBox(height: 20),
              _buildProductionMetric(
                Icons.queue_rounded,
                'Jobs in Queue',
                '12',
                0.48,
              ),
              const SizedBox(height: 20),
              _buildProductionMetric(
                Icons.inventory_2_rounded,
                'Material Stock',
                '${materialStockPercentage?.toInt()?? 0}%',
                materialStockPercentage?? 0,
              ),
              const SizedBox(height: 20),
              _buildProductionMetric(
                Icons.warning_amber_rounded,
                'Issues',
                '0',
                0.0,
                color: colorPending,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProjectsTab() {

    final activeProjects = ref.watch(projectNotifierProvider.notifier).activeProjects;
    // Project overall status
    final overallStatus = ref.watch(projectNotifierProvider.notifier).projectsOverallStatus;
    final activeProjectsLength = overallStatus.activeLength;
    final pendingProjectsLength = overallStatus.pendingLength;
    final finishedProjectsLength = overallStatus.finishedLength;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Search Bar - Minimal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
              SizedBox(width: 14),
              Text(
                'Search projects...',
                style: TextStyle(fontSize: 15, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Project Stats
        Row(
          children: [
            Expanded(child: _buildProjectStat(activeProjectsLength.toString(), 'Active')),
            const SizedBox(width: 12),
            Expanded(child: _buildProjectStat(pendingProjectsLength.toString(), 'Pending')),
            const SizedBox(width: 12),
            Expanded(child: _buildProjectStat(finishedProjectsLength.toString(), 'Done')),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'Active Projects',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 16),

        ...activeProjects.map((activeProject)=> _buildProjectCard(
              project: activeProject
            )),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTeamTab() {

    final membersFuture = ref.watch(memberNotifierProvider.notifier).members;

    return FutureBuilder(
      future: membersFuture,
      builder: (context, snapshot) {
        final members = snapshot.data ?? [];
        
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Team Overview
            
            Row(
              children: [
                Expanded(
                  child: _buildTeamStat(members.length.toString(), 'Total Members', Icons.people_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTeamStat(members.length.toString(), 'Active', Icons.check_circle_rounded),
                ),
              ],
            ),
        
            const SizedBox(height: 12),
        
            Row(
              children: [
                Expanded(
                  child: _buildTeamStat('0', 'On Leave', Icons.event_busy_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTeamStat('0', 'Sick', Icons.local_hospital_rounded),
                ),
              ],
            ),
        
            const SizedBox(height: 32),
        
            const Text(
              'All Team Members',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
        
            const SizedBox(height: 16),
        
            ... List.generate(members.length, (
                index,
              ) {
                final name = members[index].name;
                final role = members[index].role;
                return _buildTeamMemberCard(
                  name: name,
                  role: role=='admin'? "Administrator": role[0].toUpperCase() + role.substring(1),
                  score: 98,
                  avatar: '👨‍💼'
                );
            }),

            const SizedBox(height: 24),

            const Text(
              'Top Performers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
        
            const SizedBox(height: 16),      

            const EmptyTopPerformersGraphic(),
        
            const SizedBox(height: 80),
          ],
        );
      }
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Report Period
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Period',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildPeriodButton('This Week', true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPeriodButton('This Month', false)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPeriodButton('This Year', false)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildReportCard(
          icon: Icons.attach_money_rounded,
          title: 'Revenue Report',
          value: '\$24,580',
          change: '+12.5%',
        ),

        _buildReportCard(
          icon: Icons.work_rounded,
          title: 'Projects Report',
          value: '156',
          change: '+8 new',
        ),

        _buildReportCard(
          icon: Icons.print_rounded,
          title: 'Production Report',
          value: '247 jobs',
          change: '94% efficiency',
        ),

        _buildReportCard(
          icon: Icons.inventory_2_rounded,
          title: 'Material Usage',
          value: '86%',
          change: 'Healthy',
        ),

        _buildReportCard(
          icon: Icons.people_rounded,
          title: 'Team Performance',
          value: '92%',
          change: '+5%',
        ),

        const SizedBox(height: 24),

        // Export Options
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Reports',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              _buildExportButton('Export as PDF', Icons.picture_as_pdf_rounded),
              const SizedBox(height: 10),
              _buildExportButton('Export as Excel', Icons.table_chart_rounded),
              const SizedBox(height: 10),
              _buildExportButton('Email Report', Icons.email_rounded),
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return SettingsScreen(designedForTab: true,);
  }

  // Helper Widgets

  Widget _buildPeriodTab(String period) {
    final isSelected = _selectedPeriod == period;
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => setState(() => _selectedPeriod = period),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Align(
          alignment: Alignment.center,
          child: Text(
            period,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String value,
    String label,
    String trend,
    bool trendUp,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                trendUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 16,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionMetric(
    IconData icon,
    String label,
    String value,
    double progress, {
    Color color = colorPrimary,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard({
    required Project project
  }) {

    final name = project.name;
    final client = project.client.name;
    final progress = project.progressRate;
    final dueDate = project.dueDate != null
        ? project.dueDate!.eventIn
        : 'No due date';
    final team = project.assignedManagers.length;

    final isOverdue = project.dueDate!=null? DateTime.now().isAfter(project.dueDate!) : false;
    final dueTextColor = isOverdue? const Color(0xFFEF4444) : const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          AppRoutes.navigateTo(context, AppRoutes.viewProject, arguments: ProjectArgs(projectId: project.id));
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                client,
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2563EB),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: dueTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dueDate,
                    style: TextStyle(fontSize: 12, color: dueTextColor),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.people_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$team',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard({
    required String name,
    required String role,
    required int score,
    required String avatar,
    int? rank,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(avatar, style: const TextStyle(fontSize: 26)),
                ),
              ),
              if (rank != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        rank.toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              score.toString(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String value,
    required String change,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          AppRoutes.navigateTo(context, AppRoutes.projectReport);
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          change,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF94A3B8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyTopPerformersGraphic extends StatelessWidget {
  const EmptyTopPerformersGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: colorPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 44,
              color: colorPrimary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            "No top performers yet",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Top performing members will appear here once tasks are completed and progress is tracked.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}