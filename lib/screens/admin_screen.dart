// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Timer? _refreshTimer;
  String _selectedPeriod = 'Today';

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) setState(() {});
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
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              backgroundColor: const Color(0xFFF5F7FA),
              elevation: 0,
              pinned: false,
              toolbarHeight: 100,
              flexibleSpace: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.dashboard,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Overview & Analytics',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: Color(0xFF2563EB),
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
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    // Key Metrics Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.attach_money,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF10B981),
                            value: '\$24,580',
                            label: 'Revenue',
                            trend: '+12.5%',
                            trendUp: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.work,
                            iconBg: const Color(0xFFDCE7FE),
                            iconColor: const Color(0xFF2563EB),
                            value: '156',
                            label: 'Projects',
                            trend: '+8',
                            trendUp: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.people,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFF59E0B),
                            value: '24',
                            label: 'Team',
                            trend: '+2',
                            trendUp: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.trending_up,
                            iconBg: const Color(0xFFE9D5FF),
                            iconColor: const Color(0xFF9333EA),
                            value: '94%',
                            label: 'Efficiency',
                            trend: '+5%',
                            trendUp: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Quick Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.add_box,
                            label: 'New\nProject',
                            color: const Color(0xFF2563EB),
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.person_add,
                            label: 'Add\nStaff',
                            color: const Color(0xFF10B981),
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.inventory_2,
                            label: 'Stock\nEntry',
                            color: const Color(0xFFF59E0B),
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.print,
                            label: 'Add\nPrinter',
                            color: const Color(0xFF9333EA),
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Active Projects
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Active Projects',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildProjectCard(
                      name: 'ABC Corp - Storefront Signage',
                      status: 'Production',
                      statusColor: const Color(0xFF2563EB),
                      progress: 0.65,
                      dueDate: 'Due in 3 days',
                      team: 5,
                    ),

                    _buildProjectCard(
                      name: 'XYZ Ltd - Vehicle Wraps',
                      status: 'Design',
                      statusColor: const Color(0xFFF59E0B),
                      progress: 0.40,
                      dueDate: 'Due in 5 days',
                      team: 3,
                    ),

                    _buildProjectCard(
                      name: 'Local Cafe - Menu Boards',
                      status: 'Finishing',
                      statusColor: const Color(0xFF10B981),
                      progress: 0.85,
                      dueDate: 'Due tomorrow',
                      team: 4,
                    ),

                    const SizedBox(height: 32),

                    // Production Status
                    const Text(
                      'Production Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildProductionStatusItem(
                            icon: Icons.print,
                            label: 'Printers Active',
                            value: '4/6',
                            color: const Color(0xFF10B981),
                            percentage: 0.67,
                          ),
                          const SizedBox(height: 16),
                          _buildProductionStatusItem(
                            icon: Icons.queue,
                            label: 'Jobs in Queue',
                            value: '12',
                            color: const Color(0xFF2563EB),
                            percentage: 0.48,
                          ),
                          const SizedBox(height: 16),
                          _buildProductionStatusItem(
                            icon: Icons.inventory_2,
                            label: 'Material Stock',
                            value: '86%',
                            color: const Color(0xFF10B981),
                            percentage: 0.86,
                          ),
                          const SizedBox(height: 16),
                          _buildProductionStatusItem(
                            icon: Icons.warning_amber,
                            label: 'Issues',
                            value: '2',
                            color: const Color(0xFFF59E0B),
                            percentage: 0.15,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Team Performance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Top Performers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildPerformerCard(
                      name: 'Ibrahim',
                      role: 'Production Lead',
                      score: 98,
                      avatar: '👤',
                      trend: '+5%',
                    ),

                    _buildPerformerCard(
                      name: 'Muhammad Fazaldeen',
                      role: 'Designer',
                      score: 95,
                      avatar: '👤',
                      trend: '+3%',
                    ),

                    _buildPerformerCard(
                      name: 'Sarah Johnson',
                      role: 'Finishing',
                      score: 92,
                      avatar: '👤',
                      trend: '+7%',
                    ),

                    const SizedBox(height: 32),

                    // Recent Alerts
                    const Text(
                      'Recent Alerts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildAlertCard(
                      icon: Icons.inventory_2,
                      title: 'Low Stock Alert',
                      message: 'Cast Vinyl running low - 15 rolls remaining',
                      color: const Color(0xFFF59E0B),
                      time: '2 hours ago',
                    ),

                    _buildAlertCard(
                      icon: Icons.error,
                      title: 'Printer Maintenance',
                      message: 'Banner Pro requires scheduled maintenance',
                      color: const Color(0xFFEF4444),
                      time: '5 hours ago',
                    ),

                    _buildAlertCard(
                      icon: Icons.check_circle,
                      title: 'Project Completed',
                      message: 'Store Opening Banners delivered successfully',
                      color: const Color(0xFF10B981),
                      time: '1 day ago',
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard, 'Dashboard', true),
                _buildNavItem(Icons.work_outline, 'Projects', false),
                _buildNavItem(Icons.people_outline, 'Team', false),
                _buildNavItem(Icons.bar_chart, 'Reports', false),
                _buildNavItem(Icons.settings_outlined, 'Settings', false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String period) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
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

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required String trend,
    required bool trendUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                trendUp ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color:
                    trendUp ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      trendUp
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
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
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard({
    required String name,
    required String status,
    required Color statusColor,
    required double progress,
    required String dueDate,
    required int team,
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
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
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
                  status,
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
              Icon(Icons.schedule, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                dueDate,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, size: 14, color: Color(0xFF9CA3AF)),
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

  Widget _buildProductionStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
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
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
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

  Widget _buildPerformerCard({
    required String name,
    required String role,
    required int score,
    required String avatar,
    required String trend,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE7FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(avatar, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
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
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trend,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
