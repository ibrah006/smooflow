// ─────────────────────────────────────────────────────────────────────────────
// desktop_viweer_home_screen.dart
//
// Viewer / Member role home screen — read-only workspace overview.
//
// Shown to users whose role is 'member' (no department assigned yet).
// Displays:
//   • Sidebar — logo + project list (read-only, no actions)
//   • Topbar  — greeting + user chip
//   • Body    — active project cards with basic progress info
//               + a prominent "pending role assignment" notice
//
// Design system mirrors admin_desktop_dashboard.dart exactly:
//   _T tokens · sidebar structure · topbar style · card language
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/logo.dart';
import 'package:smooflow/components/user_menu_chip.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/helpers/task_component_helper.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (identical to admin_desktop_dashboard.dart)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue      = Color(0xFF2563EB);
  static const blue50    = Color(0xFFEFF6FF);
  static const blue100   = Color(0xFFDBEAFE);
  static const green     = Color(0xFF10B981);
  static const green50   = Color(0xFFECFDF5);
  static const amber     = Color(0xFFF59E0B);
  static const amber50   = Color(0xFFFEF3C7);
  static const red       = Color(0xFFEF4444);
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
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DesktopViewerHomeScreen extends ConsumerStatefulWidget {
  const DesktopViewerHomeScreen({super.key});

  @override
  ConsumerState<DesktopViewerHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends ConsumerState<DesktopViewerHomeScreen> {
  bool _isLoading = true;
  String? _selectedProjectId;

  List<Project> get _projects => ref.watch(projectNotifierProvider);
  List<Task>    get _tasks    => ref.watch(taskNotifierProvider).tasks;

  List<Task> _tasksFor(String projectId) =>
      _tasks.where((t) => t.projectId == projectId).toList();

  List<Project> get _activeProjects => _projects.where((p) {
    final tasks = _tasksFor(p.id);
    return tasks.any((t) =>
        t.status != TaskStatus.completed);
  }).toList();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(projectNotifierProvider.notifier).load(projectsLastAddedLocal: null);
      await ref.read(taskNotifierProvider.notifier).loadAll();
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleProjects = _selectedProjectId == null
        ? _activeProjects
        : _activeProjects.where((p) => p.id == _selectedProjectId).toList();

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          _MemberSidebar(
            projects:          _activeProjects,
            tasks:             _tasks,
            selectedProjectId: _selectedProjectId,
            onProjectSelected: (id) => setState(() => _selectedProjectId = id),
          ),

          // ── Main ─────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _MemberTopbar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: _T.blue, strokeWidth: 2))
                      : _MemberBody(
                          projects: visibleProjects,
                          allTasks: _tasks,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _MemberSidebar extends StatelessWidget {
  final List<Project>   projects;
  final List<Task>      tasks;
  final String?         selectedProjectId;
  final ValueChanged<String?> onProjectSelected;

  const _MemberSidebar({
    required this.projects,
    required this.tasks,
    required this.selectedProjectId,
    required this.onProjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _T.sidebarW,
      color: _T.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ─────────────────────────────────────────────────────────
          Container(
            height: _T.topbarH,
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x10FFFFFF)))),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Logo(size: 25),
              const SizedBox(width: 9),
              const Text('smooflow',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: Colors.white)),
              const Spacer(),
              // Member badge instead of ADMIN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: _T.slate500.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('MEMBER',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white.withOpacity(0.55))),
              ),
            ]),
          ),

          // ── Section label ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 6),
            child: _SidebarLabel('Active Projects'),
          ),

          // ── Project list (read-only) ──────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: projects.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Text('No active projects',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.25))),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // "All projects" row
                        _SidebarProjectRow(
                          name:     'All Projects',
                          color:    _T.slate400,
                          count:    projects.length,
                          isActive: selectedProjectId == null,
                          onTap:    () => onProjectSelected(null),
                        ),
                        const SizedBox(height: 4),
                        ...projects.map((p) {
                          final cnt = tasks
                              .where((t) => t.projectId == p.id)
                              .length;
                          return _SidebarProjectRow(
                            name:     p.name,
                            color:    p.color,
                            count:    cnt,
                            isActive: selectedProjectId == p.id,
                            onTap:    () => onProjectSelected(p.id),
                          );
                        }),
                      ],
                    ),
            ),
          ),

          // ── Role notice at bottom ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _T.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_T.r),
              border: Border.all(color: _T.amber.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: _T.amber.withOpacity(0.8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Awaiting role assignment from your administrator.',
                    style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.45)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR
// ─────────────────────────────────────────────────────────────────────────────
class _MemberTopbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now      = DateTime.now();
    final hour     = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final user = LoginService.currentUser;

    return Container(
      height: _T.topbarH,
      decoration: const BoxDecoration(
          color: _T.white,
          border: Border(bottom: BorderSide(color: _T.slate200))),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Text('$greeting${user != null ? ", ${user.nameShort}" : ""}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _T.ink3)),
        const SizedBox(width: 8),
        Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
                color: _T.slate300, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(fmtDate(now),
            style: const TextStyle(fontSize: 12.5, color: _T.slate400)),
        const Spacer(),
        if (user != null)
          UserMenuChip(
            onLogout: () async {
              await LoginService.logout();
              if (context.mounted) {
                AppRoutes.navigateAndRemoveUntil(context, AppRoutes.login);
              }
            },
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────────────────────
class _MemberBody extends StatelessWidget {
  final List<Project> projects;
  final List<Task>    allTasks;

  const _MemberBody({required this.projects, required this.allTasks});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pending role banner ───────────────────────────────────────────
          _PendingRoleBanner(),
          const SizedBox(height: 28),

          // ── Section header ────────────────────────────────────────────────
          Row(children: [
            const Text('Active Projects',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: _T.ink)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: _T.slate100,
                  borderRadius: BorderRadius.circular(99)),
              child: Text('${projects.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _T.slate500)),
            ),
          ]),
          const SizedBox(height: 4),
          const Text(
            'Here\'s what\'s currently in progress across the workspace.',
            style: TextStyle(fontSize: 13, color: _T.slate400),
          ),
          const SizedBox(height: 18),

          // ── Project grid ──────────────────────────────────────────────────
          if (projects.isEmpty)
            _EmptyState()
          else
            _ProjectGrid(projects: projects, allTasks: allTasks),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING ROLE BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _PendingRoleBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
              color: _T.ink.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Accent strip
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: _T.amber,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_T.rLg),
                  bottomLeft: Radius.circular(_T.rLg)),
            ),
          ),

          // Icon
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: _T.amber50,
                borderRadius: BorderRadius.circular(_T.r)),
            child: const Icon(Icons.pending_actions_rounded,
                size: 18, color: _T.amber),
          ),

          // Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Role Assignment Pending',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: _T.ink)),
                  const SizedBox(height: 3),
                  Text(
                    'Your account is active but you haven\'t been assigned a department role yet. '
                    'An administrator will assign you shortly — you can review active projects below in the meantime.',
                    style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: _T.slate500),
                  ),
                ],
              ),
            ),
          ),

          // Right status chip
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: _T.amber50,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                      color: _T.amber.withOpacity(0.35), width: 1)),
              child: Row(children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: _T.amber, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('Pending',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _T.amber)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT GRID
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectGrid extends StatelessWidget {
  final List<Project> projects;
  final List<Task>    allTasks;

  const _ProjectGrid({required this.projects, required this.allTasks});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final cols = constraints.maxWidth > 900 ? 3 : 2;
        final itemW = (constraints.maxWidth - (cols - 1) * 16) / cols;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: projects
              .map((p) => SizedBox(
                    width: itemW,
                    child: _ProjectCard(
                      project:  p,
                      tasks: allTasks
                          .where((t) => t.projectId == p.id)
                          .toList(),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectCard extends StatefulWidget {
  final Project    project;
  final List<Task> tasks;

  const _ProjectCard({required this.project, required this.tasks});

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hovered = false;

  int get _total    => widget.tasks.length;
  int get _done     => widget.tasks.where((t) => t.status == TaskStatus.completed).length;
  int get _active   => widget.tasks.where((t) =>
      t.status == TaskStatus.designing ||
      t.status == TaskStatus.printing).length;
  int get _waiting  => widget.tasks.where((t) =>
      t.status == TaskStatus.waitingApproval ||
      t.status == TaskStatus.clientApproved).length;

  double get _progress => _total == 0 ? 0 : _done / _total;

  // Task representing the most common non-completed status
  Task? get _dominantTask {
    final active = widget.tasks.where((t) => t.status != TaskStatus.completed).toList();
    if (active.isEmpty) return widget.tasks.isNotEmpty ? widget.tasks.first : null;
    final counts = <TaskStatus, int>{};
    for (final t in active) {
      counts[t.status] = (counts[t.status] ?? 0) + 1;
    }
    final dominantStatus = counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    return active.firstWhere((t) => t.status == dominantStatus);
  }

  @override
  Widget build(BuildContext context) {
    final dominantTask = _dominantTask;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rLg),
          border: Border.all(
              color: _hovered ? _T.slate300 : _T.slate200),
          boxShadow: [
            BoxShadow(
                color: _T.ink.withOpacity(_hovered ? 0.08 : 0.04),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.slate100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    // Project colour dot
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: widget.project.color,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(widget.project.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: _T.ink)),
                    ),
                    // Status chip
                    if (dominantTask != null)
                      _StatusChip(task: dominantTask),
                  ]),

                  // Progress bar
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 4,
                          backgroundColor: _T.slate100,
                          valueColor: AlwaysStoppedAnimation(
                              widget.project.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${(_progress * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _T.slate400)),
                  ]),
                ],
              ),
            ),

            // ── Stats row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: Row(
                children: [
                  _StatCell(
                    label: 'Total',
                    value: '$_total',
                    color: _T.slate500,
                  ),
                  _StatDivider(),
                  _StatCell(
                    label: 'In Progress',
                    value: '$_active',
                    color: _T.blue,
                  ),
                  _StatDivider(),
                  _StatCell(
                    label: 'Review',
                    value: '$_waiting',
                    color: _T.amber,
                  ),
                  _StatDivider(),
                  _StatCell(
                    label: 'Done',
                    value: '$_done',
                    color: _T.green,
                  ),
                ],
              ),
            ),

            // ── Recent tasks preview ───────────────────────────────────────
            if (widget.tasks.isNotEmpty) ...[
              Container(
                height: 1,
                color: _T.slate100,
                margin: const EdgeInsets.symmetric(horizontal: 18),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RECENT TASKS',
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: _T.slate400)),
                    const SizedBox(height: 8),
                    ...widget.tasks
                        .where((t) => t.status != TaskStatus.completed)
                        .take(3)
                        .map((t) => _TaskPreviewRow(task: t)),
                    if (widget.tasks
                            .where((t) => t.status != TaskStatus.completed)
                            .length >
                        3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${widget.tasks.where((t) => t.status != TaskStatus.completed).length - 3} more tasks',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: _T.slate400),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final Task task;
  const _StatusChip({required this.task});

  @override
  Widget build(BuildContext context) {
    final helper = TaskComponentHelper.get(task);
    final color  = helper.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Text(helper.label,
          style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK PREVIEW ROW
// ─────────────────────────────────────────────────────────────────────────────
class _TaskPreviewRow extends StatelessWidget {
  final Task task;
  const _TaskPreviewRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final helper = TaskComponentHelper.get(task);
    final color  = helper.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: color.withOpacity(0.7),
                shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(task.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _T.ink3)),
        ),
        const SizedBox(width: 8),
        Text(helper.label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CELL & DIVIDER
// ─────────────────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: _T.slate400)),
      ]),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1, height: 28,
        color: _T.slate100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: _T.slate100,
                borderRadius: BorderRadius.circular(_T.rLg)),
            child: const Icon(Icons.folder_open_outlined,
                size: 22, color: _T.slate400),
          ),
          const SizedBox(height: 14),
          const Text('No active projects',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _T.ink3)),
          const SizedBox(height: 4),
          const Text('There are no projects in progress right now.',
              style: TextStyle(fontSize: 13, color: _T.slate400)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SIDEBAR PRIMITIVES  (mirrors admin_desktop_dashboard.dart)
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarLabel extends StatelessWidget {
  final String text;
  const _SidebarLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: Colors.white.withOpacity(0.28))),
      );
}

class _SidebarProjectRow extends StatelessWidget {
  final String       name;
  final Color        color;
  final int          count;
  final bool         isActive;
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
      color:        isActive
          ? Colors.white.withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(_T.r),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(_T.r),
        hoverColor:   Colors.white.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle)),
            const SizedBox(width: 9),
            Expanded(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color: Colors.white
                            .withOpacity(isActive ? 0.9 : 0.55)))),
            Text('$count',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.25))),
          ]),
        ),
      ),
    );
  }
}