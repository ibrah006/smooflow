// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  String _selectedPeriod = 'Today';
  int _currentTabIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Modern Header with Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20).copyWith(bottom: 0),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.dashboard_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Smooflow Management',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.notifications_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
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

                // Tab Bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    dividerColor: Colors.black12,
                    controller: _tabController,
                    isScrollable: true,
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
                _buildDashboardTab(),
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

  Widget _buildDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Period Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPeriodTab('Today'),
              const SizedBox(width: 8),
              _buildPeriodTab('This Week'),
              const SizedBox(width: 8),
              _buildPeriodTab('This Month'),
              const SizedBox(width: 8),
              _buildPeriodTab('Custom'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Key Metrics Grid - More Modern Layout
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildGradientMetric('\$24,580', 'Revenue', '+12.5%', true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Expanded(
                      child: _buildGradientMetric(
                        '156',
                        'Projects',
                        '+8',
                        true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGradientMetric(
                      '94%',
                      'Efficiency',
                      '+5%',
                      true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Quick Actions - Modern Grid
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),
        Row(
          spacing: 15,
          children: [
            Expanded(
              child: _buildModernActionCard(
                Icons.add_business,
                'New Project',
                const Color(0xFF2563EB),
                () {},
              ),
            ),
            Expanded(
              child: _buildModernActionCard(
                Icons.person_add,
                'Add Staff',
                const Color(0xFF10B981),
                () {},
              ),
            ),
          ],
        ),
        SizedBox(height: 15,)
        Row(
          spacing: 15,
          children: [
            Expanded(
              child: _buildModernActionCard(
                Icons.inventory,
                'Stock Entry',
                const Color(0xFFF59E0B),
                () {},
              ),
            ),
            Expanded(
              child: _buildModernActionCard(
                Icons.print,
                'Add Printer',
                const Color(0xFF9333EA),
                () {},
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
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _buildProductionMetric(
                Icons.print,
                'Active Printers',
                '4/6',
                0.67,
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 20),
              _buildProductionMetric(
                Icons.queue,
                'Jobs in Queue',
                '12',
                0.48,
                const Color(0xFF2563EB),
              ),
              const SizedBox(height: 20),
              _buildProductionMetric(
                Icons.inventory_2,
                'Material Stock',
                '86%',
                0.86,
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 20),
              _buildProductionMetric(
                Icons.warning_amber,
                'Issues',
                '2',
                0.15,
                const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProjectsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Search and Filter
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Search projects...',
                      style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.filter_list,
                color: Color(0xFF2563EB),
                size: 24,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Project Stats
        Row(
          children: [
            Expanded(
              child: _buildProjectStat('24', 'Active', const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProjectStat('8', 'Pending', const Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProjectStat(
                '132',
                'Completed',
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Projects List
        const Text(
          'Active Projects',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),

        _buildProjectCard(
          name: 'ABC Corp - Storefront Signage',
          client: 'ABC Corporation',
          status: 'Production',
          statusColor: const Color(0xFF2563EB),
          progress: 0.65,
          dueDate: 'Due in 3 days',
          team: 5,
          stage: 'Production',
        ),

        _buildProjectCard(
          name: 'XYZ Ltd - Vehicle Wraps',
          client: 'XYZ Limited',
          status: 'Design',
          statusColor: const Color(0xFFF59E0B),
          progress: 0.40,
          dueDate: 'Due in 5 days',
          team: 3,
          stage: 'Design',
        ),

        _buildProjectCard(
          name: 'Local Cafe - Menu Boards',
          client: 'Local Cafe',
          status: 'Finishing',
          statusColor: const Color(0xFF10B981),
          progress: 0.85,
          dueDate: 'Due tomorrow',
          team: 4,
          stage: 'Finishing',
        ),

        _buildProjectCard(
          name: 'Mall Kiosk - Signage Package',
          client: 'Shopping Mall',
          status: 'Planning',
          statusColor: const Color(0xFF9333EA),
          progress: 0.20,
          dueDate: 'Due in 1 week',
          team: 2,
          stage: 'Planning',
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTeamTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Team Overview Cards
        Row(
          children: [
            Expanded(
              child: _buildTeamStat(
                '24',
                'Total Staff',
                Icons.people,
                const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTeamStat(
                '18',
                'Active Today',
                Icons.check_circle,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildTeamStat(
                '3',
                'On Leave',
                Icons.event_busy,
                const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTeamStat(
                '1',
                'Sick Leave',
                Icons.local_hospital,
                const Color(0xFFEF4444),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Department Filter
        const Text(
          'Departments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDepartmentChip('All', true, 24),
              const SizedBox(width: 8),
              _buildDepartmentChip('Design', false, 6),
              const SizedBox(width: 8),
              _buildDepartmentChip('Production', false, 8),
              const SizedBox(width: 8),
              _buildDepartmentChip('Finishing', false, 5),
              const SizedBox(width: 8),
              _buildDepartmentChip('Application', false, 5),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Top Performers
        const Text(
          'Top Performers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),

        _buildTeamMemberCard(
          name: 'Ibrahim',
          role: 'Production Lead',
          department: 'Production',
          score: 98,
          status: 'Active',
          statusColor: const Color(0xFF10B981),
          avatar: '👨‍💼',
          rank: 1,
        ),

        _buildTeamMemberCard(
          name: 'Muhammad Fazaldeen',
          role: 'Senior Designer',
          department: 'Design',
          score: 95,
          status: 'Active',
          statusColor: const Color(0xFF10B981),
          avatar: '👨‍🎨',
          rank: 2,
        ),

        _buildTeamMemberCard(
          name: 'Sarah Johnson',
          role: 'Finishing Specialist',
          department: 'Finishing',
          score: 92,
          status: 'Active',
          statusColor: const Color(0xFF10B981),
          avatar: '👩‍🔧',
          rank: 3,
        ),

        const SizedBox(height: 24),

        // All Team Members
        const Text(
          'All Team Members',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),

        _buildTeamMemberCard(
          name: 'Ahmed Ali',
          role: 'Printer Operator',
          department: 'Production',
          score: 88,
          status: 'Active',
          statusColor: const Color(0xFF10B981),
          avatar: '👨‍💻',
        ),

        _buildTeamMemberCard(
          name: 'Lisa Chen',
          role: 'Designer',
          department: 'Design',
          score: 86,
          status: 'Active',
          statusColor: const Color(0xFF10B981),
          avatar: '👩‍🎨',
        ),

        _buildTeamMemberCard(
          name: 'Mike Brown',
          role: 'Application Technician',
          department: 'Application',
          score: 84,
          status: 'On Leave',
          statusColor: const Color(0xFFF59E0B),
          avatar: '👨‍🔧',
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Report Period Selector
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Period',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildPeriodButton('This Week', true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPeriodButton('This Month', false)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPeriodButton('This Year', false)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Revenue Report
        _buildReportCard(
          icon: Icons.attach_money,
          iconColor: const Color(0xFF10B981),
          title: 'Revenue Report',
          subtitle: 'Financial overview',
          value: '\$24,580',
          change: '+12.5% from last week',
          changePositive: true,
          onTap: () {},
        ),

        // Projects Report
        _buildReportCard(
          icon: Icons.work,
          iconColor: const Color(0xFF2563EB),
          title: 'Projects Report',
          subtitle: 'Completed & In Progress',
          value: '156',
          change: '+8 new projects',
          changePositive: true,
          onTap: () {},
        ),

        // Production Report
        _buildReportCard(
          icon: Icons.print,
          iconColor: const Color(0xFF9333EA),
          title: 'Production Report',
          subtitle: 'Print jobs & efficiency',
          value: '247 jobs',
          change: '94% efficiency rate',
          changePositive: true,
          onTap: () {},
        ),

        // Material Usage Report
        _buildReportCard(
          icon: Icons.inventory_2,
          iconColor: const Color(0xFFF59E0B),
          title: 'Material Usage',
          subtitle: 'Stock & consumption',
          value: '86%',
          change: 'Stock level healthy',
          changePositive: true,
          onTap: () {},
        ),

        // Team Performance Report
        _buildReportCard(
          icon: Icons.people,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Team Performance',
          subtitle: 'Staff productivity',
          value: '92%',
          change: '+5% this week',
          changePositive: true,
          onTap: () {},
        ),

        const SizedBox(height: 24),

        // Export Options
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Reports',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildExportButton(
                'Export as PDF',
                Icons.picture_as_pdf,
                const Color(0xFFEF4444),
              ),
              const SizedBox(height: 12),
              _buildExportButton(
                'Export as Excel',
                Icons.table_chart,
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _buildExportButton(
                'Email Report',
                Icons.email,
                const Color(0xFF2563EB),
              ),
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.settings,
                size: 50,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your custom settings content will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets

  Widget _buildPeriodTab(String period) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientMetric(
    String value,
    String label,
    String trend,
    bool trendUp,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                trendUp ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
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
    double progress,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
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
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFEDF2F7),
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

  Widget _buildProjectStat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard({
    required String name,
    required String client,
    required String status,
    required Color statusColor,
    required double progress,
    required String dueDate,
    required int team,
    required String stage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFEDF2F7),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                dueDate,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.people, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                '$team members',
                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStat(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentChip(String label, bool isSelected, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Colors.white.withOpacity(0.3)
                      : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard({
    required String name,
    required String role,
    required String department,
    required int score,
    required String status,
    required Color statusColor,
    required String avatar,
    int? rank,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            rank != null
                ? Border.all(
                  color:
                      rank == 1
                          ? const Color(0xFFFFD700)
                          : rank == 2
                          ? const Color(0xFFC0C0C0)
                          : const Color(0xFFCD7F32),
                  width: 2,
                )
                : null,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE7FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(avatar, style: const TextStyle(fontSize: 28)),
                ),
              ),
              if (rank != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color:
                          rank == 1
                              ? const Color(0xFFFFD700)
                              : rank == 2
                              ? const Color(0xFFC0C0C0)
                              : const Color(0xFFCD7F32),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        rank.toString(),
                        style: const TextStyle(
                          fontSize: 10,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                department,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    required String change,
    required bool changePositive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        changePositive
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 14,
                        color:
                            changePositive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              changePositive
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9CA3AF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
