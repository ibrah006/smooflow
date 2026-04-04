// ─────────────────────────────────────────────────────────────────────────────
// SKELETON LOADING — admin_desktop_dashboard_screen.dart
//
// Drop-in replacements and targeted diffs. Apply in order.
// ─────────────────────────────────────────────────────────────────────────────

// ─── (1) ROOT SCAFFOLD — remove LoadingOverlay, pass isLoading down ──────────
//
// BEFORE:
//   return GestureDetector(
//     onTap: ...,
//     child: LoadingOverlay(
//       isLoading: _isInitLoading,
//       child: Scaffold(
//         body: Focus(
//           ...
//           child: Row(
//             children: [
//               _AdminSidebar(
//                 currentView: _view,
//                 selectedProjectId: _selectedProjectId,
//                 projects: _projects,
//                 tasks: _pipelineTasks,
//                 members: _members,
//                 onViewChanged: ...,
//                 onProjectSelected: ...,
//               ),
//               Expanded(
//                 child: Column(
//                   children: [
//                     _AdminTopbar(...),
//                     Expanded(
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: _view == _AdminView.overview
//                                 ? _AdminAnalyticsView(...)
//                                 : ...
//
// AFTER — replace the entire return statement with:

/*
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _addTaskFocusNode.unfocus();
        setState(() => _isAddingTask = false);
      },
      child: Scaffold(                           // ← LoadingOverlay removed
        body: Focus(
          autofocus: true,
          onKeyEvent: _handleKey,
          child: Row(
            children: [
              _AdminSidebar(
                currentView: _view,
                selectedProjectId: _selectedProjectId,
                projects: _projects,
                tasks: _pipelineTasks,
                members: _members,
                isLoading: _isInitLoading,       // ← new param
                onViewChanged: (v) {
                  setState(() => _view = v);
                  _closeDetail();
                },
                onProjectSelected: (id) => setState(() {
                  _selectedProjectId = id;
                  if (_view == _AdminView.overview) _view = _AdminView.list;
                }),
              ),
              Expanded(
                child: Column(
                  children: [
                    _AdminTopbar(
                      currentView: _view,
                      selectedProjectId: _selectedProjectId,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _view == _AdminView.overview
                                ? (_isInitLoading              // ← skeleton branch
                                    ? const _OverviewSkeleton()
                                    : _AdminAnalyticsView(
                                        tasks: _pipelineTasks,
                                        projects: _projects,
                                        members: _members,
                                      ))
                                : _view == _AdminView.list
                                ? TaskListView(
                                    projects: _projects,
                                    selectedProjectId: _selectedProjectId,
                                    selectedTaskId: _selectedTaskId,
                                    onTaskSelected: _selectTask,
                                    isDetailOpen: _selectedTaskId != null,
                                    onAddTask: _showTaskModal,
                                    addTaskFocusNode: _addTaskFocusNode,
                                    isAddingTask: _isAddingTask,
                                  )
                                : _view == _AdminView.clients
                                ? ClientsPage()
                                : _view == _AdminView.team
                                ? ManageMembersPage()
                                : _view == _AdminView.printers
                                ? DesktopPrinterManagementScreen()
                                : _view == _AdminView.inventory
                                ? DesktopMaterialsManagementScreen()
                                : _view == _AdminView.reports
                                ? DesktopReportsScreen()
                                : _view == _AdminView.accounts
                                ? AccountsManagementScreen()
                                : SettingsPage(),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            width: _selectedTaskId != null ? _T.detailW : 0,
                            child: _selectedTaskId != null && _selectedTask != null
                                ? DetailPanel(
                                    task: _selectedTask!,
                                    projects: _projects,
                                    onClose: _closeDetail,
                                    onAdvance: () => _advanceTask(_selectedTask!),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
*/

// ─── (2) _AdminSidebar — add isLoading param ─────────────────────────────────
//
// Add to _AdminSidebar's field list:
//   final bool isLoading;
//
// Add to const constructor:
//   required this.isLoading,
//
// Then in _AdminSidebarState.build(), replace the two Expanded + Padding
// sections that render project rows and nav items with the conditional below.
// Everything above and below those sections (logo, nav labels, New Project
// button, Operations, Manage) stays untouched.
//
// Replace the projects ListView section:
//
// BEFORE:
//   Expanded(
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: widget.projects.map((p) { ... }).toList(),
//       ),
//     ),
//   ),
//
// AFTER:
//   Expanded(
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       child: widget.isLoading
//           ? const _SidebarProjectsSkeleton()
//           : ListView(
//               padding: EdgeInsets.zero,
//               children: widget.projects.map((p) { ... }).toList(),
//             ),
//     ),
//   ),
//
// And wrap the workspace nav items column so the task count badge skeleton
// shows while loading — the simplest approach is to keep the nav items visible
// always (they are interactive regardless) but pass isLoading to the badge:
//
// In _SidebarNavItem, change badge rendering so when isLoading it shows a
// skeleton instead of the count. The easiest approach: pass null badge when
// isLoading:
//
//   badge: widget.isLoading ? null : (tasks.length > 0 ? tasks.length.toString() : null),

// ─── (3) NEW WIDGETS — paste these alongside the other micro-widgets ──────────

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON PULSE — shared animated shimmer primitive
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const teal = Color(0xFF38BDF8);

  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);

  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;

  static const sidebarW = 220.0;
  static const topbarH = 52.0;
  static const detailW = 400.0;

  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class Pulse extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final bool circle;

  const Pulse({
    required this.width,
    required this.height,
    this.radius = 6,
    this.circle = false,
  });

  const Pulse.full({required this.height, this.radius = 6})
    : width = double.infinity,
      circle = false;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder:
          (_, __) => Opacity(
            opacity: _anim.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                // Slightly lighter on the dark sidebar, slightly darker on white bg.
                // Callers on white pass a color override if needed.
                color: const Color(0x22FFFFFF),
                borderRadius:
                    widget.circle ? null : BorderRadius.circular(widget.radius),
                shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
              ),
            ),
          ),
    );
  }
}

// Light variant for white backgrounds
class PulseLight extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const PulseLight({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  const PulseLight.full({required this.height, this.radius = 6})
    : width = double.infinity;

  @override
  State<PulseLight> createState() => _PulseLightState();
}

class _PulseLightState extends State<PulseLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder:
          (_, __) => Opacity(
            opacity: _anim.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: _T.slate200,
                borderRadius: BorderRadius.circular(widget.radius),
              ),
            ),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR PROJECTS SKELETON
// Renders 4 ghost project rows matching _SidebarProjectRow dimensions.
// ─────────────────────────────────────────────────────────────────────────────
class SidebarProjectsSkeleton extends StatelessWidget {
  const SidebarProjectsSkeleton();

  // Varying widths make it feel more like real content
  static const _widths = [110.0, 90.0, 130.0, 75.0];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              // Color dot
              const Pulse(width: 8, height: 8, circle: true),
              const SizedBox(width: 9),
              // Project name bar
              Pulse(width: _widths[i], height: 11),
              const Spacer(),
              // Count
              const Pulse(width: 16, height: 10),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW SKELETON
// Mirrors _AdminAnalyticsView layout: 5 KPI cards + 2 chart rows.
// Fully non-blocking — rendered in place of _AdminAnalyticsView while loading.
// ─────────────────────────────────────────────────────────────────────────────
class OverviewSkeleton extends StatelessWidget {
  const OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI cards row ─────────────────────────────────────────────
          Row(
            children:
                List.generate(
                  5,
                  (i) => [
                    const Expanded(child: KpiCardSkeleton()),
                    if (i < 4) const SizedBox(width: 12),
                  ],
                ).expand((w) => w).toList(),
          ),
          const SizedBox(height: 16),

          // ── Chart row 1: stage funnel + priority donut ────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(flex: 5, child: ChartCardSkeleton(bodyHeight: 180)),
              SizedBox(width: 12),
              Expanded(flex: 4, child: ChartCardSkeleton(bodyHeight: 180)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Chart row 2: team workload + project health ───────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(flex: 4, child: ChartCardSkeleton(bodyHeight: 220)),
              SizedBox(width: 12),
              Expanded(flex: 5, child: ChartCardSkeleton(bodyHeight: 220)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI CARD SKELETON — mirrors _KpiCard padding/layout
// ─────────────────────────────────────────────────────────────────────────────
class KpiCardSkeleton extends StatelessWidget {
  const KpiCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              // Icon badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _T.slate100,
                  borderRadius: BorderRadius.circular(_T.r),
                ),
              ),
              const Spacer(),
              const PulseLight(width: 14, height: 14),
            ],
          ),
          const SizedBox(height: 12),
          // Value
          const PulseLight(width: 48, height: 26, radius: 5),
          const SizedBox(height: 8),
          // Label
          const PulseLight(width: 80, height: 11),
          const SizedBox(height: 8),
          // Delta
          const PulseLight(width: 60, height: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHART CARD SKELETON — mirrors _AnalyticsCard chrome + variable body height
// ─────────────────────────────────────────────────────────────────────────────
class ChartCardSkeleton extends StatelessWidget {
  final double bodyHeight;
  const ChartCardSkeleton({required this.bodyHeight});

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
          // Header row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  PulseLight(width: 120, height: 13),
                  SizedBox(height: 6),
                  PulseLight(width: 160, height: 11),
                ],
              ),
              const Spacer(),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: _T.slate200),
                  borderRadius: BorderRadius.circular(_T.r),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _T.slate100),
          const SizedBox(height: 16),

          // Body placeholder — staggered bars to hint at chart content
          SizedBox(
            height: bodyHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(5, (i) {
                // Varying widths so it reads as a bar chart
                final pct = [0.75, 0.55, 0.85, 0.40, 0.65][i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      PulseLight(width: 100, height: 11),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LayoutBuilder(
                          builder:
                              (_, c) => Row(
                                children: [
                                  PulseLight(
                                    width: c.maxWidth * pct,
                                    height: 22,
                                    radius: _T.r,
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
