// ─────────────────────────────────────────────────────────────────────────────
// ADMIN ANALYTICS DASHBOARD
// Extends the DesignDashboardScreen visual language for admin users.
// Drop this file alongside your existing design_dashboard.dart.
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => const AdminDashboardScreen(),
//   ));
//
// The sidebar gains a new "Overview" nav item. Clicking it renders the
// analytics canvas. "Board" / "List" behave exactly as before.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Re-use your existing imports ──────────────────────────────────────────────
// import 'package:smooflow/core/models/member.dart';
// import 'package:smooflow/core/models/project.dart';
// import 'package:smooflow/core/models/task.dart';
// import 'package:smooflow/core/services/login_service.dart';
// import 'package:smooflow/enums/task_priority.dart';
// import 'package:smooflow/enums/task_status.dart';
// import 'package:smooflow/providers/member_provider.dart';
// import 'package:smooflow/providers/project_provider.dart';
// import 'package:smooflow/providers/task_provider.dart';

// For this standalone demo we use mock data instead of real providers.
// Replace the mock getters at the bottom with your real Riverpod providers.

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (identical to your _T class)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue      = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100   = Color(0xFFDBEAFE);
  static const blue50    = Color(0xFFEFF6FF);
  static const teal      = Color(0xFF38BDF8);

  static const green     = Color(0xFF10B981);
  static const green50   = Color(0xFFECFDF5);
  static const amber     = Color(0xFFF59E0B);
  static const amber50   = Color(0xFFFEF3C7);
  static const red       = Color(0xFFEF4444);
  static const red50     = Color(0xFFFEE2E2);
  static const purple    = Color(0xFF8B5CF6);
  static const purple50  = Color(0xFFF3E8FF);

  static const slate50   = Color(0xFFF8FAFC);
  static const slate100  = Color(0xFFF1F5F9);
  static const slate200  = Color(0xFFE2E8F0);
  static const slate300  = Color(0xFFCBD5E1);
  static const slate400  = Color(0xFF94A3B8);
  static const slate500  = Color(0xFF64748B);
  static const ink       = Color(0xFF0F172A);
  static const ink2      = Color(0xFF1E293B);
  static const ink3      = Color(0xFF334155);
  static const white     = Colors.white;

  static const sidebarW = 220.0;
  static const topbarH  = 52.0;

  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS / VIEW MODE
// ─────────────────────────────────────────────────────────────────────────────
enum _AdminView { overview, board, list }

// ─────────────────────────────────────────────────────────────────────────────
// ROOT  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _AdminView _view = _AdminView.overview;
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.slate50,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, event) => KeyEventResult.ignored,
        child: Row(
          children: [
            // ── Sidebar ──────────────────────────────────────────────────
            _AdminSidebar(
              currentView: _view,
              selectedProjectId: _selectedProjectId,
              onViewChanged: (v) => setState(() => _view = v),
              onProjectSelected: (id) => setState(() {
                _selectedProjectId = id;
                _view = _AdminView.board;
              }),
            ),
            // ── Main content ─────────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  _AdminTopbar(
                    currentView: _view,
                    onViewChanged: (v) => setState(() => _view = v),
                  ),
                  Expanded(
                    child: _view == _AdminView.overview
                        ? const _AdminAnalyticsView()
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _view == _AdminView.board
                                      ? Icons.view_kanban_outlined
                                      : Icons.list_alt_outlined,
                                  size: 48,
                                  color: _T.slate300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _view == _AdminView.board
                                      ? 'Board view — wire in your DesignDashboard here'
                                      : 'List view — wire in your TaskListView here',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _T.slate400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN SIDEBAR
// Identical shell to your _Sidebar but with an "Overview" nav item at top.
// ─────────────────────────────────────────────────────────────────────────────
class _AdminSidebar extends StatelessWidget {
  final _AdminView currentView;
  final String? selectedProjectId;
  final ValueChanged<_AdminView> onViewChanged;
  final ValueChanged<String?> onProjectSelected;

  const _AdminSidebar({
    required this.currentView,
    required this.selectedProjectId,
    required this.onViewChanged,
    required this.onProjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    final projects = _MockData.projects;

    return Container(
      width: _T.sidebarW,
      color: _T.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ─────────────────────────────────────────────────────
          Container(
            height: _T.topbarH,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x10FFFFFF))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_T.blue, _T.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Center(child: _LogoMark(size: 16)),
                ),
                const SizedBox(width: 9),
                const Text(
                  'smooflow',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _T.amber.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFFFCD34D),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Nav ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarLabel('Workspace'),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Overview',
                  isActive: currentView == _AdminView.overview,
                  onTap: () => onViewChanged(_AdminView.overview),
                ),
                _SidebarNavItem(
                  icon: Icons.view_kanban_outlined,
                  label: 'Board',
                  isActive: currentView == _AdminView.board,
                  onTap: () => onViewChanged(_AdminView.board),
                ),
                _SidebarNavItem(
                  icon: Icons.list_alt_outlined,
                  label: 'List',
                  isActive: currentView == _AdminView.list,
                  onTap: () => onViewChanged(_AdminView.list),
                ),
              ],
            ),
          ),

          // ── Projects ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
            child: _SidebarLabel('Projects'),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SidebarProjectRow(
                    name: 'All projects',
                    color: _T.slate400,
                    count: _MockData.tasks.length,
                    isActive: selectedProjectId == null,
                    onTap: () => onProjectSelected(null),
                  ),
                  ...projects.map((p) {
                    final cnt = _MockData.tasks
                        .where((t) => t.projectId == p.id)
                        .length;
                    return _SidebarProjectRow(
                      name: p.name,
                      color: p.color,
                      count: cnt,
                      isActive: selectedProjectId == p.id,
                      onTap: () => onProjectSelected(p.id),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Team ─────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x12FFFFFF))),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESIGN TEAM',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                const SizedBox(height: 10),
                ..._MockData.members.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _AvatarWidget(
                        initials: m.initials,
                        color: m.color,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                      // Online dot
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: m.isOnline ? _T.green : _T.slate500,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN TOPBAR
// ─────────────────────────────────────────────────────────────────────────────
class _AdminTopbar extends StatelessWidget {
  final _AdminView currentView;
  final ValueChanged<_AdminView> onViewChanged;

  const _AdminTopbar({
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      height: _T.topbarH,
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (currentView == _AdminView.overview) ...[
            Text(
              '$greeting, Admin',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _T.ink3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: _T.slate300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _fmtDateFull(now),
              style: const TextStyle(fontSize: 12.5, color: _T.slate400),
            ),
          ] else
            Text(
              currentView == _AdminView.board ? 'Design Board' : 'Task List',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _T.ink3,
              ),
            ),

          const Spacer(),

          // Refresh indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _T.green50,
              border: Border.all(color: _T.green.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _T.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _T.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Admin user chip
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            decoration: BoxDecoration(
              border: Border.all(color: _T.slate200),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _T.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _T.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _T.ink3,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.keyboard_arrow_down,
                    size: 14, color: _T.slate400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN ANALYTICS VIEW — the main analytics canvas
// ─────────────────────────────────────────────────────────────────────────────
class _AdminAnalyticsView extends StatefulWidget {
  const _AdminAnalyticsView();

  @override
  State<_AdminAnalyticsView> createState() => _AdminAnalyticsViewState();
}

class _AdminAnalyticsViewState extends State<_AdminAnalyticsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double start, double end) =>
      CurvedAnimation(
        parent: _ac,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    final tasks    = _MockData.tasks;
    final projects = _MockData.projects;
    final members  = _MockData.members;

    // ── Computed stats ────────────────────────────────────────────────────
    final totalActive  = tasks.where((t) => t.status != _Status.approved && t.status != _Status.printing).length;
    final inReview     = tasks.where((t) => t.status == _Status.waitingApproval).length;
    final overdue      = tasks.where((t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now())).length;
    final approvedToday = tasks.where((t) =>
        t.status == _Status.approved &&
        t.approvedAt != null &&
        _sameDay(t.approvedAt!, DateTime.now())).length;
    final printQueue   = tasks.where((t) => t.status == _Status.printing).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: KPI strip ───────────────────────────────────────────
          FadeTransition(
            opacity: _stagger(0.0, 0.4),
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(_stagger(0.0, 0.4)),
              child: Row(
                children: [
                  _KpiCard(
                    label: 'Active Tasks',
                    value: '$totalActive',
                    delta: '+3 this week',
                    deltaPositive: true,
                    icon: Icons.assignment_outlined,
                    iconColor: _T.blue,
                    iconBg: _T.blue50,
                  ),
                  const SizedBox(width: 12),
                  _KpiCard(
                    label: 'In Review',
                    value: '$inReview',
                    delta: 'Awaiting approval',
                    deltaPositive: null,
                    icon: Icons.hourglass_top_rounded,
                    iconColor: _T.amber,
                    iconBg: _T.amber50,
                  ),
                  const SizedBox(width: 12),
                  _KpiCard(
                    label: 'Overdue',
                    value: '$overdue',
                    delta: overdue > 0 ? 'Needs attention' : 'All on track',
                    deltaPositive: overdue == 0,
                    icon: Icons.warning_amber_rounded,
                    iconColor: _T.red,
                    iconBg: _T.red50,
                  ),
                  const SizedBox(width: 12),
                  _KpiCard(
                    label: 'Approved Today',
                    value: '$approvedToday',
                    delta: 'Client sign-offs',
                    deltaPositive: true,
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: _T.green,
                    iconBg: _T.green50,
                  ),
                  const SizedBox(width: 12),
                  _KpiCard(
                    label: 'Print Queue',
                    value: '$printQueue',
                    delta: 'Ready for production',
                    deltaPositive: null,
                    icon: Icons.print_outlined,
                    iconColor: _T.purple,
                    iconBg: _T.purple50,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Row 2: Stage funnel + Throughput chart ─────────────────────
          FadeTransition(
            opacity: _stagger(0.15, 0.55),
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(_stagger(0.15, 0.55)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stage funnel
                  Expanded(
                    flex: 5,
                    child: _AnalyticsCard(
                      title: 'Stage Distribution',
                      subtitle: 'Tasks by pipeline stage',
                      child: _StageFunnelChart(tasks: tasks),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Throughput sparklines
                  Expanded(
                    flex: 4,
                    child: _AnalyticsCard(
                      title: 'Weekly Throughput',
                      subtitle: 'Tasks completed per day',
                      child: _ThroughputChart(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Row 3: Team load + Project health ─────────────────────────
          FadeTransition(
            opacity: _stagger(0.3, 0.7),
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(_stagger(0.3, 0.7)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team workload
                  Expanded(
                    flex: 4,
                    child: _AnalyticsCard(
                      title: 'Team Workload',
                      subtitle: 'Tasks per designer',
                      child: _TeamWorkloadChart(
                          members: members, tasks: tasks),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Project health heatmap
                  Expanded(
                    flex: 5,
                    child: _AnalyticsCard(
                      title: 'Project Health',
                      subtitle: 'Status × overdue risk per project',
                      child: _ProjectHealthGrid(
                          projects: projects, tasks: tasks),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Row 4: Priority breakdown + Activity feed ──────────────────
          FadeTransition(
            opacity: _stagger(0.45, 0.85),
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(_stagger(0.45, 0.85)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority donut
                  Expanded(
                    flex: 3,
                    child: _AnalyticsCard(
                      title: 'Priority Breakdown',
                      subtitle: 'Across all active tasks',
                      child: _PriorityDonutChart(tasks: tasks),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Activity feed
                  Expanded(
                    flex: 6,
                    child: _AnalyticsCard(
                      title: 'Recent Activity',
                      subtitle: 'Stage transitions & approvals',
                      child: _ActivityFeed(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI CARD
// ─────────────────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool? deltaPositive; // null = neutral
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaPositive,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaPositive == null
        ? _T.slate400
        : deltaPositive!
            ? _T.green
            : _T.red;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.white,
          border: Border.all(color: _T.slate200),
          borderRadius: BorderRadius.circular(_T.rLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(_T.r),
                  ),
                  child: Icon(icon, size: 17, color: iconColor),
                ),
                const Spacer(),
                Icon(
                  deltaPositive == null
                      ? Icons.remove
                      : deltaPositive!
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                  size: 14,
                  color: deltaColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _T.ink,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _T.ink3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              delta,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: deltaColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYTICS CARD SHELL
// ─────────────────────────────────────────────────────────────────────────────
class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _T.white,
        border: Border.all(color: _T.slate200),
        borderRadius: BorderRadius.circular(_T.rLg),
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
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _T.slate400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: _T.slate200),
                  borderRadius: BorderRadius.circular(_T.r),
                ),
                child: const Icon(Icons.more_horiz,
                    size: 13, color: _T.slate400),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: _T.slate100),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE FUNNEL CHART
// Horizontal stacked bar showing tasks per stage
// ─────────────────────────────────────────────────────────────────────────────
class _StageFunnelChart extends StatelessWidget {
  final List<_MockTask> tasks;

  const _StageFunnelChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final stages = [
      (label: 'Initialized',       status: _Status.pending,         color: _T.slate400, bg: _T.slate100),
      (label: 'Designing',         status: _Status.designing,       color: _T.purple,   bg: _T.purple50),
      (label: 'Awaiting Approval', status: _Status.waitingApproval, color: _T.amber,    bg: _T.amber50),
      (label: 'Client Approved',   status: _Status.approved,        color: _T.green,    bg: _T.green50),
      (label: 'Printing',          status: _Status.printing,        color: _T.blue,     bg: _T.blue50),
    ];

    final counts = stages
        .map((s) => tasks.where((t) => t.status == s.status).length)
        .toList();
    final total = counts.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox(height: 120);

    return Column(
      children: stages.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final count = counts[i];
        final pct = count / total;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              // Label
              SizedBox(
                width: 130,
                child: Text(
                  s.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _T.ink3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              // Bar
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 26,
                        decoration: BoxDecoration(
                          color: _T.slate100,
                          borderRadius: BorderRadius.circular(_T.r),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        height: 26,
                        width: constraints.maxWidth * pct,
                        decoration: BoxDecoration(
                          color: s.bg,
                          border: Border.all(
                            color: s.color.withOpacity(0.4),
                          ),
                          borderRadius: BorderRadius.circular(_T.r),
                        ),
                        child: count > 0
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: s.color,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(width: 10),
              // Percentage
              SizedBox(
                width: 38,
                child: Text(
                  '${(pct * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _T.slate500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THROUGHPUT CHART
// A mini bar chart of "tasks completed per day" for the last 7 days
// ─────────────────────────────────────────────────────────────────────────────
class _ThroughputChart extends StatelessWidget {
  final List<int> _data = const [2, 5, 3, 7, 4, 6, 3];
  final List<String> _days = const [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  const _ThroughputChart();

  @override
  Widget build(BuildContext context) {
    final maxVal = _data.reduce(math.max).toDouble();

    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_data.length, (i) {
          final isToday = i == _data.length - 1;
          final frac = _data[i] / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_data[i]}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isToday ? _T.blue : _T.slate400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500 + i * 60),
                    curve: Curves.easeOutCubic,
                    height: 80 * frac,
                    decoration: BoxDecoration(
                      color: isToday ? _T.blue : _T.blue100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _days[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? _T.blue : _T.slate400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEAM WORKLOAD CHART
// Horizontal bars per designer — active tasks vs capacity
// ─────────────────────────────────────────────────────────────────────────────
class _TeamWorkloadChart extends StatelessWidget {
  final List<_MockMember> members;
  final List<_MockTask> tasks;

  const _TeamWorkloadChart({
    required this.members,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    const capacity = 8; // max tasks per designer

    return Column(
      children: members.map((m) {
        final active = tasks
            .where((t) =>
                t.assigneeId == m.id &&
                t.status != _Status.approved &&
                t.status != _Status.printing)
            .length;
        final overdue = tasks
            .where((t) =>
                t.assigneeId == m.id &&
                t.dueDate != null &&
                t.dueDate!.isBefore(DateTime.now()))
            .length;
        final frac = (active / capacity).clamp(0.0, 1.0);
        final isOverloaded = frac > 0.75;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _AvatarWidget(initials: m.initials, color: m.color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _T.ink3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$active / $capacity',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isOverloaded ? _T.amber : _T.slate400,
                          ),
                        ),
                        if (overdue > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _T.red50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$overdue overdue',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: _T.red,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    LayoutBuilder(builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: _T.slate100,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            height: 6,
                            width: constraints.maxWidth * frac,
                            decoration: BoxDecoration(
                              color: isOverloaded ? _T.amber : m.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT HEALTH GRID
// Each project row shows: name, task count, stage sparkbar, overdue badge
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectHealthGrid extends StatelessWidget {
  final List<_MockProject> projects;
  final List<_MockTask> tasks;

  const _ProjectHealthGrid({
    required this.projects,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                  flex: 3,
                  child: _ColHeader('Project')),
              Expanded(
                  flex: 4,
                  child: _ColHeader('Stage breakdown')),
              Expanded(
                  flex: 1,
                  child: _ColHeader('Total')),
              Expanded(
                  flex: 1,
                  child: _ColHeader('⚠︎')),
            ],
          ),
        ),
        ...projects.map((p) {
          final ptasks = tasks.where((t) => t.projectId == p.id).toList();
          final total = ptasks.length;
          if (total == 0) return const SizedBox.shrink();

          final overdueCount = ptasks
              .where((t) =>
                  t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
              .length;

          final stageCounts = [
            ptasks.where((t) => t.status == _Status.pending).length,
            ptasks.where((t) => t.status == _Status.designing).length,
            ptasks.where((t) => t.status == _Status.waitingApproval).length,
            ptasks.where((t) => t.status == _Status.approved).length,
            ptasks.where((t) => t.status == _Status.printing).length,
          ];
          final stageColors = [
            _T.slate300, _T.purple, _T.amber, _T.green, _T.blue
          ];

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.slate50,
              borderRadius: BorderRadius.circular(_T.r),
              border: Border.all(color: _T.slate100),
            ),
            child: Row(
              children: [
                // Name
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _T.ink3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Stage micro-bar
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: LayoutBuilder(builder: (context, constraints) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Row(
                          children: List.generate(5, (i) {
                            if (stageCounts[i] == 0) return const SizedBox.shrink();
                            return Flexible(
                              flex: stageCounts[i],
                              child: Container(
                                height: 8,
                                color: stageColors[i],
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
                // Total
                Expanded(
                  flex: 1,
                  child: Text(
                    '$total',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _T.ink3,
                    ),
                  ),
                ),
                // Overdue
                Expanded(
                  flex: 1,
                  child: Center(
                    child: overdueCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _T.red50,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '$overdueCount',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _T.red,
                              ),
                            ),
                          )
                        : const Text(
                            '—',
                            style:
                                TextStyle(fontSize: 12, color: _T.slate300),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: _T.slate400,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY DONUT CHART
// Pure Flutter custom painter donut with legend
// ─────────────────────────────────────────────────────────────────────────────
class _PriorityDonutChart extends StatelessWidget {
  final List<_MockTask> tasks;

  const _PriorityDonutChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final urgent = tasks.where((t) => t.priority == _Priority.urgent).length;
    final high   = tasks.where((t) => t.priority == _Priority.high).length;
    final normal = tasks.where((t) => t.priority == _Priority.normal).length;
    final total  = tasks.length;

    if (total == 0) return const SizedBox(height: 120);

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: CustomPaint(
            painter: _DonutPainter(
              values: [urgent.toDouble(), high.toDouble(), normal.toDouble()],
              colors: [_T.red, _T.amber, _T.slate300],
              strokeWidth: 18,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _T.ink,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'tasks',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _T.slate400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _DonutLegendItem(
                color: _T.red, label: 'Urgent', count: urgent),
            _DonutLegendItem(
                color: _T.amber, label: 'High', count: high),
            _DonutLegendItem(
                color: _T.slate300, label: 'Normal', count: normal),
          ],
        ),
      ],
    );
  }
}

class _DonutLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _DonutLegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _T.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: _T.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;

  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    const gap = 0.04;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = (values[i] / total) * 2 * math.pi - gap;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values || old.colors != colors;
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY FEED
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed();

  @override
  Widget build(BuildContext context) {
    final events = _MockData.activityEvents;

    return Column(
      children: events.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        final isLast = i == events.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: e.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(e.icon, size: 13, color: e.iconColor),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: _T.slate100,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _T.ink3,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                                children: [
                                  TextSpan(
                                    text: e.actor,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: ' ${e.action} '),
                                  TextSpan(
                                    text: e.subject,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _T.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            e.timeAgo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _T.slate400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (e.note != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _T.slate50,
                            borderRadius: BorderRadius.circular(_T.r),
                            border: Border.all(color: _T.slate200),
                          ),
                          child: Text(
                            e.note!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _T.slate500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED MICRO WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  const _AvatarWidget(
      {required this.initials, required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      );
}

class _SidebarLabel extends StatelessWidget {
  final String text;
  const _SidebarLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Colors.white.withOpacity(0.28),
          ),
        ),
      );
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? _T.blue.withOpacity(0.25) : Colors.transparent,
      borderRadius: BorderRadius.circular(_T.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_T.r),
        hoverColor: Colors.white.withOpacity(0.07),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: Colors.white
                      .withOpacity(isActive ? 1.0 : 0.5)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.white
                        .withOpacity(isActive ? 1.0 : 0.5),
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: _T.blue,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarProjectRow extends StatelessWidget {
  final String name;
  final Color color;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarProjectRow({
    required this.name,
    required this.color,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(_T.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_T.r),
        hoverColor: Colors.white.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.white
                        .withOpacity(isActive ? 0.9 : 0.55),
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.19, h * 0.66), w * 0.065,
        paint..color = Colors.white.withOpacity(0.5));
    canvas.drawCircle(Offset(w * 0.48, h * 0.34), w * 0.065,
        paint..color = Colors.white.withOpacity(0.7));

    final flowPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;
    final flowPath = Path()
      ..moveTo(w * 0.19, h * 0.66)
      ..cubicTo(w * 0.19, h * 0.66, w * 0.30, h * 0.34, w * 0.48,
          h * 0.34)
      ..cubicTo(w * 0.66, h * 0.34, w * 0.64, h * 0.66, w * 0.81,
          h * 0.55);
    canvas.drawPath(flowPath, flowPaint);

    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.077
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path()
      ..moveTo(w * 0.35, h * 0.51)
      ..lineTo(w * 0.48, h * 0.65)
      ..lineTo(w * 0.81, h * 0.33);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmtDateFull(DateTime d) {
  const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA
// ─────────────────────────────────────────────────────────────────────────────
// Replace these with your real Riverpod providers and models.

enum _Status { pending, designing, waitingApproval, approved, printing }
enum _Priority { normal, high, urgent }

class _MockMember {
  final String id;
  final String name;
  final String initials;
  final Color color;
  final bool isOnline;
  const _MockMember(this.id, this.name, this.initials, this.color, this.isOnline);
}

class _MockProject {
  final String id;
  final String name;
  final Color color;
  const _MockProject(this.id, this.name, this.color);
}

class _MockTask {
  final String id;
  final String projectId;
  final String? assigneeId;
  final _Status status;
  final _Priority priority;
  final DateTime? dueDate;
  final DateTime? approvedAt;
  const _MockTask({
    required this.id,
    required this.projectId,
    this.assigneeId,
    required this.status,
    this.priority = _Priority.normal,
    this.dueDate,
    this.approvedAt,
  });
}

class _ActivityEvent {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String actor;
  final String action;
  final String subject;
  final String timeAgo;
  final String? note;
  const _ActivityEvent({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.actor,
    required this.action,
    required this.subject,
    required this.timeAgo,
    this.note,
  });
}

class _MockData {
  static final members = [
    const _MockMember('m1', 'Alex Chen',     'AC', Color(0xFF2563EB), true),
    const _MockMember('m2', 'Maria Santos',  'MS', Color(0xFF8B5CF6), true),
    const _MockMember('m3', 'Jordan Lee',    'JL', Color(0xFF10B981), false),
    const _MockMember('m4', 'Taylor Kim',    'TK', Color(0xFFF59E0B), true),
  ];

  static final projects = [
    const _MockProject('p1', 'Spring Campaign',     Color(0xFF2563EB)),
    const _MockProject('p2', 'Brand Refresh',       Color(0xFF8B5CF6)),
    const _MockProject('p3', 'Trade Show Booth',    Color(0xFF10B981)),
    const _MockProject('p4', 'Product Launch Kit',  Color(0xFFF59E0B)),
  ];

  static final tasks = [
    _MockTask(id: 't1',  projectId: 'p1', assigneeId: 'm1', status: _Status.designing,       priority: _Priority.urgent, dueDate: DateTime.now().subtract(const Duration(days: 1))),
    _MockTask(id: 't2',  projectId: 'p1', assigneeId: 'm2', status: _Status.waitingApproval, priority: _Priority.high),
    _MockTask(id: 't3',  projectId: 'p1', assigneeId: 'm1', status: _Status.pending,         priority: _Priority.normal),
    _MockTask(id: 't4',  projectId: 'p2', assigneeId: 'm3', status: _Status.designing,       priority: _Priority.high,   dueDate: DateTime.now().add(const Duration(days: 2))),
    _MockTask(id: 't5',  projectId: 'p2', assigneeId: 'm2', status: _Status.approved,        priority: _Priority.normal, approvedAt: DateTime.now()),
    _MockTask(id: 't6',  projectId: 'p2', assigneeId: 'm4', status: _Status.printing,        priority: _Priority.normal),
    _MockTask(id: 't7',  projectId: 'p3', assigneeId: 'm3', status: _Status.waitingApproval, priority: _Priority.urgent, dueDate: DateTime.now().subtract(const Duration(days: 2))),
    _MockTask(id: 't8',  projectId: 'p3', assigneeId: 'm1', status: _Status.designing,       priority: _Priority.high),
    _MockTask(id: 't9',  projectId: 'p3', assigneeId: 'm4', status: _Status.pending,         priority: _Priority.normal),
    _MockTask(id: 't10', projectId: 'p4', assigneeId: 'm2', status: _Status.pending,         priority: _Priority.normal, dueDate: DateTime.now().subtract(const Duration(days: 3))),
    _MockTask(id: 't11', projectId: 'p4', assigneeId: 'm3', status: _Status.designing,       priority: _Priority.urgent),
    _MockTask(id: 't12', projectId: 'p4', assigneeId: 'm4', status: _Status.waitingApproval, priority: _Priority.high),
    _MockTask(id: 't13', projectId: 'p1', assigneeId: 'm1', status: _Status.printing,        priority: _Priority.normal),
    _MockTask(id: 't14', projectId: 'p2', assigneeId: 'm3', status: _Status.approved,        priority: _Priority.high,   approvedAt: DateTime.now()),
    _MockTask(id: 't15', projectId: 'p3', assigneeId: 'm4', status: _Status.designing,       priority: _Priority.normal),
  ];

  static final activityEvents = [
    const _ActivityEvent(
      icon: Icons.check_circle_outline_rounded,
      iconColor: _T.green,
      iconBg: _T.green50,
      actor: 'Maria S.',
      action: 'got client approval on',
      subject: 'Brand Refresh — Hero Banner',
      timeAgo: '8 min ago',
    ),
    const _ActivityEvent(
      icon: Icons.arrow_forward_rounded,
      iconColor: _T.blue,
      iconBg: _T.blue50,
      actor: 'Alex C.',
      action: 'moved to Awaiting Approval:',
      subject: 'Spring Campaign — Email Header',
      timeAgo: '24 min ago',
      note: 'Draft v3 uploaded. Please review colour accuracy before sign-off.',
    ),
    const _ActivityEvent(
      icon: Icons.warning_amber_rounded,
      iconColor: _T.red,
      iconBg: _T.red50,
      actor: 'System',
      action: 'flagged overdue task —',
      subject: 'Trade Show Booth — Vinyl Banner A',
      timeAgo: '1 hr ago',
    ),
    const _ActivityEvent(
      icon: Icons.print_outlined,
      iconColor: _T.purple,
      iconBg: _T.purple50,
      actor: 'Taylor K.',
      action: 'sent to print queue:',
      subject: 'Brand Refresh — Business Cards',
      timeAgo: '2 hr ago',
    ),
    const _ActivityEvent(
      icon: Icons.add_circle_outline_rounded,
      iconColor: _T.slate500,
      iconBg: _T.slate100,
      actor: 'Jordan L.',
      action: 'created task',
      subject: 'Product Launch Kit — Social Pack',
      timeAgo: '3 hr ago',
    ),
  ];
}