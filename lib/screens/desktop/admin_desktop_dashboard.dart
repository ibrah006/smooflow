// ─────────────────────────────────────────────────────────────────────────────
// ADMIN ANALYTICS DASHBOARD — real data edition
// Drop this file alongside your existing design_dashboard.dart.
// All mock data replaced with real Riverpod providers + your actual models.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/logo.dart';
import 'package:smooflow/components/user_menu_chip.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/clients_page.dart';
import 'package:smooflow/screens/desktop/components/board_view.dart';
import 'package:smooflow/screens/desktop/components/detail_panel.dart';
import 'package:smooflow/screens/desktop/components/project_modal.dart';
import 'package:smooflow/screens/desktop/components/task_list_view.dart';
import 'package:smooflow/screens/desktop/components/task_modal.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (identical to your _T class in design_dashboard.dart)
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
  static const detailW  = 400.0;

  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage metadata — mirrors kStages from design_dashboard.dart
// ─────────────────────────────────────────────────────────────────────────────
// class _StageInfo {
//   final TaskStatus status;
//   final String label;
//   final String shortLabel;
//   final Color color;
//   final Color bg;
//   const _StageInfo(this.status, this.label, this.shortLabel, this.color, this.bg);
// }

DesignStageInfo _stageInfo(TaskStatus s) =>
    kStages.firstWhere((i) => i.stage == s, orElse: () => kStages.first);

// ─────────────────────────────────────────────────────────────────────────────
// VIEW ENUM
// ─────────────────────────────────────────────────────────────────────────────
enum _AdminView { overview, board, list, clients }

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class AdminDesktopDashboardScreen extends ConsumerStatefulWidget {
  const AdminDesktopDashboardScreen({super.key});

  @override
  ConsumerState<AdminDesktopDashboardScreen> createState() =>
      _AdminDesktopDashboardScreenState();
}

class _AdminDesktopDashboardScreenState
    extends ConsumerState<AdminDesktopDashboardScreen> {
  _AdminView _view = _AdminView.overview;
  String? _selectedProjectId;
  int?    _selectedTaskId;

  String _searchQuery = '';

  final FocusNode _addTaskFocusNode = FocusNode();
  bool _isAddingTask = false;

  void _selectTask(int id) => setState(() => _selectedTaskId = id);
  void _closeDetail()      => setState(() => _selectedTaskId = null);

  Task? get _selectedTask => _selectedTaskId == null
      ? null
      : _tasks.cast<Task?>().firstWhere((t) => t!.id == _selectedTaskId, orElse: () => null);

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Flexible(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: _T.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, right: 24, left: 200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.rLg)),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  /// Advance the selected task to the next stage via the Riverpod notifier.
  Future<void> _advanceTask(Task task) async {
    final next = task.status.nextStage;
    if (next == null) return;

    // Persist through notifier
    // await ref.read(taskNotifierProvider.notifier).updateTaskStatus(task.id, next);

    if (!mounted) return;
    _showSnack(
      next == TaskStatus.clientApproved
          ? '✓ Task marked as Client Approved — handed off to production'
          : 'Task moved to "${stageInfo(next).label}"',
      next == TaskStatus.clientApproved ? _T.green : _T.blue,
    );
  }

  // All pipeline tasks (same filter as DesignDashboardScreen)
  List<Task> get _pipelineTasks =>
      ref.watch(taskNotifierProvider).tasks.where((t) =>
          t.status == TaskStatus.pending ||
          t.status == TaskStatus.designing ||
          t.status == TaskStatus.waitingApproval ||
          t.status == TaskStatus.clientApproved ||
          t.status == TaskStatus.printing).toList();

  List<Project> get _projects => ref.watch(projectNotifierProvider);
  List<Member>  get _members  => ref.watch(memberNotifierProvider).members;
  List<Task> get _tasks => ref.watch(taskNotifierProvider).tasks.where((t) =>
      t.status == TaskStatus.pending ||
      t.status == TaskStatus.designing ||
      t.status == TaskStatus.waitingApproval ||
      t.status == TaskStatus.clientApproved ||
      t.status == TaskStatus.printing ||
      t.status == TaskStatus.finishing).toList();

  List<Task> get _visibleTasks {
    return _tasks.where((t) {
      if (_selectedProjectId != null && t.projectId != _selectedProjectId) return false;
      // if (_filter == TaskFilter.mine && !t.assignees.contains(_currentUser.id)) return false;
      // if (_filter == TaskFilter.overdue) {
      //   final d = t.dueDate;
      //   if (d == null || !d.isBefore(DateTime.now())) return false;
      // }
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        return t.name.toLowerCase().contains(q) ||
            (t.description ?? '').toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(projectNotifierProvider.notifier).load(projectsLastAddedLocal: null);
      await ref.read(materialNotifierProvider.notifier).fetchMaterials();
      await ref.read(taskNotifierProvider.notifier).loadAll();
      await ref.read(taskNotifierProvider.notifier).fetchProductionScheduleToday();
      await ref.read(memberNotifierProvider.notifier).members;
    });
  }

  @override
  Widget build(BuildContext context) {

    print("task ln: ${_visibleTasks.length}");

    print("selected task: ${_selectedTaskId}");

    return GestureDetector(
      onTap: () {
        // unfocus from add new task 
        print("unfocus now from add new task");
        _addTaskFocusNode.unfocus();

        setState(() {
          _isAddingTask = false;          
        });
      },
      child: Scaffold(
        backgroundColor: _T.slate50,
        body: Focus(
          autofocus: true,
          onKeyEvent: (_, event) => KeyEventResult.ignored,
          child: Row(
            children: [
              _AdminSidebar(
                currentView: _view,
                selectedProjectId: _selectedProjectId,
                projects: _projects,
                tasks: _pipelineTasks,
                members: _members,
                onViewChanged: (v) => setState(() => _view = v),
                onProjectSelected: (id) => setState(() {
                  _selectedProjectId = id;
                  _view = _AdminView.board;
                }),
              ),
              Expanded(
                child: Column(
                  children: [
                    _AdminTopbar(currentView: _view),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: 
                            _view == _AdminView.overview
                          ? _AdminAnalyticsView(
                              tasks: _pipelineTasks,
                              projects: _projects,
                              members: _members,
                            )
                          : _view == _AdminView.board? BoardView(
                                        tasks: _visibleTasks,
                                        projects: _projects,
                                        selectedTaskId: _selectedTaskId,
                                        onTaskSelected: _selectTask,
                                        onAddTask: _showTaskModal,
                                        addTaskFocusNode: _addTaskFocusNode,
                                        isAddingTask: _isAddingTask,
                                        selectedProjectId: _selectedProjectId
                                      ) :  _view == _AdminView.list? TaskListView(
                                      tasks: _visibleTasks,
                                      projects: _projects,
                                      selectedTaskId: _selectedTaskId,
                                      onTaskSelected: _selectTask,
                                    ) : ClientsPage()
                                    
                          ),
                          // ── Detail panel ──────────────────────────────────
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
                      )
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

  void _showTaskModal() async {
    // Determine next id from current task list
    final nextId = (_tasks.isEmpty ? 0 : _tasks.map((t) => t.id).reduce((a, b) => a > b ? a : b)) + 1;
    showDialog(
      context: context,
      builder: (_) => TaskModal(
        projects: _projects,
        preselectedProjectId: _selectedProjectId,
        nextId: nextId,
      ),
    );

    setState(() {});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _AdminSidebar extends ConsumerStatefulWidget {
  final _AdminView currentView;
  final String? selectedProjectId;
  final List<Project> projects;
  final List<Task> tasks;
  final List<Member> members;
  final ValueChanged<_AdminView> onViewChanged;
  final ValueChanged<String?> onProjectSelected;

  const _AdminSidebar({
    required this.currentView,
    required this.selectedProjectId,
    required this.projects,
    required this.tasks,
    required this.members,
    required this.onViewChanged,
    required this.onProjectSelected,
  });

  @override
  ConsumerState<_AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends ConsumerState<_AdminSidebar> {
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Flexible(child: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: _T.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, right: 24, left: 200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.rLg)),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  /// Add a new project through the Riverpod notifier.
  Future<void> _addProject(Project p) async {
    await ref.read(projectNotifierProvider.notifier).create(p);
    if (!mounted) return;
    _showSnack('Project "${p.name}" created', _T.green);
  }

  void _showProjectModal() {
    showDialog(
      context: context,
      builder: (_) => ProjectModal(onSave: _addProject),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                border: Border(bottom: BorderSide(color: Color(0x10FFFFFF)))),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Logo(size: 25),
                const SizedBox(width: 9),
                const Text('smooflow',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: Colors.white)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: _T.amber.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('ADMIN',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFFFCD34D))),
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
                  isActive: widget.currentView == _AdminView.overview,
                  onTap: () => widget.onViewChanged(_AdminView.overview),
                ),
                _SidebarNavItem(
                  icon: Icons.view_kanban_outlined,
                  label: 'Board',
                  isActive: widget.currentView == _AdminView.board,
                  badge: widget.tasks
                      .where((t) => t.status != TaskStatus.clientApproved)
                      .length
                      .toString(),
                  onTap: () => widget.onViewChanged(_AdminView.board),
                ),
                _SidebarNavItem(
                  icon: Icons.list_alt_outlined,
                  label: 'List',
                  isActive: widget.currentView == _AdminView.list,
                  onTap: () => widget.onViewChanged(_AdminView.list),
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
                    count: widget.tasks.length,
                    isActive: widget.selectedProjectId == null,
                    onTap: () => widget.onProjectSelected(null),
                  ),
                  ...widget.projects.map((p) {
                    final cnt =
                        widget.tasks.where((t) => t.projectId == p.id).length;
                    return _SidebarProjectRow(
                      name: p.name,
                      color: p.color,
                      count: cnt,
                      isActive: widget.selectedProjectId == p.id,
                      onTap: () => widget.onProjectSelected(p.id),
                    );
                  }),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: InkWell(
              onTap: _showProjectModal,
              borderRadius: BorderRadius.circular(_T.r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.5),
                  borderRadius: BorderRadius.circular(_T.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 14, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 7),
                    Text('New Project', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.4))),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
            child: _SidebarLabel('Manage'),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                _SidebarNavItem(
                  icon: Icons.supervisor_account_sharp,
                  label: 'Clients',
                  isActive: widget.currentView == _AdminView.clients,
                  onTap: () => widget.onViewChanged(_AdminView.clients),
                )
              ],
            ),
          ),

          // ── Team ─────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x12FFFFFF)))),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DESIGN TEAM',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Colors.white.withOpacity(0.25))),
                const SizedBox(height: 10),
                ...widget.members.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        _AvatarWidget(
                            initials: m.initials, color: m.color, size: 26),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(m.name,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.5)))),
                        // Online dot — always green for simplicity since Member has no isOnline field
                        Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: _T.green, shape: BoxShape.circle)),
                      ]),
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
// TOPBAR
// ─────────────────────────────────────────────────────────────────────────────
class _AdminTopbar extends StatelessWidget {
  final _AdminView currentView;

  const _AdminTopbar({required this.currentView});

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final hour  = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final user  = LoginService.currentUser;

    return Container(
      height: _T.topbarH,
      decoration: const BoxDecoration(
          color: _T.white,
          border: Border(bottom: BorderSide(color: _T.slate200))),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (currentView == _AdminView.overview) ...[
            Text('$greeting${user != null ? ", ${user.nameShort}" : ""}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _T.ink3)),
            const SizedBox(width: 8),
            Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: _T.slate300, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(_fmtDateFull(now),
                style: const TextStyle(fontSize: 12.5, color: _T.slate400)),
          ] else
            Text(
              currentView == _AdminView.board ? 'Design Board' : 'Task List',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _T.ink3),
            ),

          const Spacer(),

          // Live indicator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _T.green50,
                border:
                    Border.all(color: _T.green.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(99)),
            child: Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: _T.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Live',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _T.green)),
            ]),
          ),
          const SizedBox(width: 12),

          // User chip — real user from LoginService
          if (user != null)
            UserMenuChip(
              onLogout: () async {
                await LoginService.logout();
                if (context.mounted) {
                  AppRoutes.navigateAndRemoveUntil(context, AppRoutes.login);
                }
              },
            )
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYTICS VIEW — receives real Task / Project / Member lists
// ─────────────────────────────────────────────────────────────────────────────
class _AdminAnalyticsView extends StatefulWidget {
  final List<Task>    tasks;
  final List<Project> projects;
  final List<Member>  members;

  const _AdminAnalyticsView({
    required this.tasks,
    required this.projects,
    required this.members,
  });

  @override
  State<_AdminAnalyticsView> createState() => _AdminAnalyticsViewState();
}

class _AdminAnalyticsViewState extends State<_AdminAnalyticsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

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

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
      parent: _ac,
      curve: Interval(start, end, curve: Curves.easeOutCubic));

  @override
  Widget build(BuildContext context) {
    final tasks    = widget.tasks;
    final projects = widget.projects;
    final members  = widget.members;

    // ── Computed stats from real data ─────────────────────────────────────
    final totalActive = tasks
        .where((t) =>
            t.status != TaskStatus.clientApproved &&
            t.status != TaskStatus.printing)
        .length;

    final inReview =
        tasks.where((t) => t.status == TaskStatus.waitingApproval).length;

    final overdue = tasks
        .where((t) =>
            t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
        .length;

    final approvedToday = tasks
        .where((t) =>
            t.status == TaskStatus.clientApproved &&
            t.dueDate != null &&
            _sameDay(t.dueDate!, DateTime.now()))
        .length;

    final printQueue =
        tasks.where((t) => t.status == TaskStatus.printing).length;

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
              child: Row(children: [
                _KpiCard(
                  label: 'Active Tasks',
                  value: '$totalActive',
                  delta: totalActive > 0
                      ? '$totalActive in flight'
                      : 'All clear',
                  deltaPositive: null,
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
                  deltaPositive: approvedToday > 0,
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
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Row 2: Stage distribution + Throughput ─────────────────────
          FadeTransition(
            opacity: _stagger(0.15, 0.55),
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(_stagger(0.15, 0.55)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _AnalyticsCard(
                      title: 'Stage Distribution',
                      subtitle: 'Tasks by pipeline stage',
                      child: _StageFunnelChart(tasks: tasks),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: _AnalyticsCard(
                      title: 'Priority Breakdown',
                      subtitle: 'Across all active tasks',
                      child: _PriorityDonutChart(tasks: tasks),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Row 3: Team workload + Project health ──────────────────────
          FadeTransition(
            opacity: _stagger(0.3, 0.7),
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(_stagger(0.3, 0.7)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _AnalyticsCard(
                      title: 'Team Workload',
                      subtitle: 'Active tasks per designer',
                      child: _TeamWorkloadChart(
                          members: members, tasks: tasks),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: _AnalyticsCard(
                      title: 'Project Health',
                      subtitle: 'Stage breakdown & overdue risk per project',
                      child: _ProjectHealthGrid(
                          projects: projects, tasks: tasks),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Row 4: Overdue tasks list ──────────────────────────────────
          if (overdue > 0)
            FadeTransition(
              opacity: _stagger(0.45, 0.85),
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.04), end: Offset.zero)
                    .animate(_stagger(0.45, 0.85)),
                child: _AnalyticsCard(
                  title: 'Overdue Tasks',
                  subtitle: 'Past due date — needs action',
                  child: _OverdueTasksList(
                      tasks: tasks,
                      projects: projects,
                      members: members),
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
  final bool? deltaPositive;
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
            borderRadius: BorderRadius.circular(_T.rLg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(_T.r)),
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
            ]),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _T.ink,
                    letterSpacing: -1,
                    height: 1)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _T.ink3)),
            const SizedBox(height: 6),
            Text(delta,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: deltaColor)),
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
          borderRadius: BorderRadius.circular(_T.rLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _T.ink,
                          letterSpacing: -0.2)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: _T.slate400,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                  border: Border.all(color: _T.slate200),
                  borderRadius: BorderRadius.circular(_T.r)),
              child: const Icon(Icons.more_horiz,
                  size: 13, color: _T.slate400),
            ),
          ]),
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
// STAGE FUNNEL CHART — real Task list
// ─────────────────────────────────────────────────────────────────────────────
class _StageFunnelChart extends StatelessWidget {
  final List<Task> tasks;
  const _StageFunnelChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final counts = kStages
        .map((s) => tasks.where((t) => t.status == s.stage).length)
        .toList();
    final total = counts.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: Text('No tasks in pipeline',
                style: TextStyle(fontSize: 12, color: _T.slate400))),
      );
    }

    return Column(
      children: kStages.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final count = counts[i];
        final pct   = count / total;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
              width: 130,
              child: Text(s.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _T.ink3)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                return Stack(children: [
                  Container(
                      height: 26,
                      decoration: BoxDecoration(
                          color: _T.slate100,
                          borderRadius: BorderRadius.circular(_T.r))),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 26,
                    width: constraints.maxWidth * pct,
                    decoration: BoxDecoration(
                        color: s.bg,
                        border: Border.all(
                            color: s.color.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(_T.r)),
                    child: count > 0
                        ? Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('$count',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: s.color)),
                            ))
                        : null,
                  ),
                ]);
              }),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 38,
              child: Text('${(pct * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _T.slate500)),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEAM WORKLOAD CHART — real Member + Task lists
// ─────────────────────────────────────────────────────────────────────────────
class _TeamWorkloadChart extends StatelessWidget {
  final List<Member> members;
  final List<Task>   tasks;
  const _TeamWorkloadChart({required this.members, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text('No team members',
                style: TextStyle(fontSize: 12, color: _T.slate400))),
      );
    }

    const capacity = 8;

    return Column(
      children: members.map((m) {
        final active = tasks
            .where((t) =>
                t.assignees.contains(m.id) &&
                t.status != TaskStatus.clientApproved &&
                t.status != TaskStatus.printing)
            .length;

        final overdueCount = tasks
            .where((t) =>
                t.assignees.contains(m.id) &&
                t.dueDate != null &&
                t.dueDate!.isBefore(DateTime.now()))
            .length;

        final frac        = (active / capacity).clamp(0.0, 1.0);
        final isOverloaded = frac > 0.75;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            _AvatarWidget(initials: m.initials, color: m.color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(m.name,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _T.ink3)),
                    const Spacer(),
                    Text('$active / $capacity',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isOverloaded
                                ? _T.amber
                                : _T.slate400)),
                    if (overdueCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: _T.red50,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('$overdueCount overdue',
                            style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: _T.red)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 5),
                  LayoutBuilder(builder: (context, constraints) {
                    return Stack(children: [
                      Container(
                          height: 6,
                          decoration: BoxDecoration(
                              color: _T.slate100,
                              borderRadius: BorderRadius.circular(3))),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        height: 6,
                        width: constraints.maxWidth * frac,
                        decoration: BoxDecoration(
                            color: isOverloaded ? _T.amber : m.color,
                            borderRadius: BorderRadius.circular(3)),
                      ),
                    ]);
                  }),
                ],
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT HEALTH GRID — real Project + Task lists
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectHealthGrid extends StatelessWidget {
  final List<Project> projects;
  final List<Task>    tasks;
  const _ProjectHealthGrid({required this.projects, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final projectsWithTasks =
        projects.where((p) => tasks.any((t) => t.projectId == p.id)).toList();

    if (projectsWithTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text('No active projects',
                style: TextStyle(fontSize: 12, color: _T.slate400))),
      );
    }

    return Column(
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Expanded(flex: 3, child: _ColHeader('Project')),
            Expanded(flex: 4, child: _ColHeader('Stage breakdown')),
            Expanded(flex: 1, child: _ColHeader('Total')),
            Expanded(flex: 1, child: _ColHeader('⚠︎')),
          ]),
        ),
        ...projectsWithTasks.map((p) {
          final ptasks = tasks.where((t) => t.projectId == p.id).toList();
          final total  = ptasks.length;

          final overdueCount = ptasks
              .where((t) =>
                  t.dueDate != null &&
                  t.dueDate!.isBefore(DateTime.now()))
              .length;

          final stageCounts = kStages
              .map((s) =>
                  ptasks.where((t) => t.status == s.stage).length)
              .toList();
          final stageColors = kStages.map((s) => s.color).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _T.slate50,
                borderRadius: BorderRadius.circular(_T.r),
                border: Border.all(color: _T.slate100)),
            child: Row(children: [
              // Name
              Expanded(
                flex: 3,
                child: Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: p.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(p.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _T.ink3))),
                ]),
              ),
              // Stage micro-bar
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Row(
                      children: List.generate(5, (i) {
                        if (stageCounts[i] == 0) return const SizedBox.shrink();
                        return Flexible(
                          flex: stageCounts[i],
                          child: Container(
                              height: 8, color: stageColors[i]),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              // Total
              Expanded(
                flex: 1,
                child: Text('$total',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _T.ink3)),
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
                              borderRadius: BorderRadius.circular(99)),
                          child: Text('$overdueCount',
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _T.red)))
                      : const Text('—',
                          style: TextStyle(
                              fontSize: 12, color: _T.slate300)),
                ),
              ),
            ]),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY DONUT CHART — real Task list
// ─────────────────────────────────────────────────────────────────────────────
class _PriorityDonutChart extends StatelessWidget {
  final List<Task> tasks;
  const _PriorityDonutChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final urgent = tasks.where((t) => t.priority == TaskPriority.urgent).length;
    final high   = tasks.where((t) => t.priority == TaskPriority.high).length;
    final normal = tasks.where((t) => t.priority == TaskPriority.normal).length;
    final total  = tasks.length;

    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: Text('No tasks',
                style: TextStyle(fontSize: 12, color: _T.slate400))),
      );
    }

    return Column(children: [
      SizedBox(
        height: 140,
        child: CustomPaint(
          painter: _DonutPainter(
            values: [urgent.toDouble(), high.toDouble(), normal.toDouble()],
            colors: [_T.red, _T.amber, _T.slate300],
            strokeWidth: 20,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$total',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _T.ink,
                        letterSpacing: -1,
                        height: 1)),
                const Text('tasks',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _T.slate400)),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DonutLegendItem(color: _T.red,    label: 'Urgent', count: urgent),
          _DonutLegendItem(color: _T.amber,  label: 'High',   count: high),
          _DonutLegendItem(color: _T.slate300, label: 'Normal', count: normal),
        ],
      ),
    ]);
  }
}

class _DonutLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _DonutLegendItem({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(height: 4),
    Text('$count',
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: _T.ink)),
    Text(label,
        style: const TextStyle(
            fontSize: 10.5, color: _T.slate400, fontWeight: FontWeight.w500)),
  ]);
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color>  colors;
  final double strokeWidth;
  const _DonutPainter({required this.values, required this.colors, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final total  = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -math.pi / 2;
    const gap = 0.04;
    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = (values[i] / total) * 2 * math.pi - gap;
      canvas.drawArc(
          rect, startAngle, sweep, false,
          Paint()
            ..color = colors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.values != values;
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERDUE TASKS LIST — replaces activity feed; shows real overdue tasks
// ─────────────────────────────────────────────────────────────────────────────
class _OverdueTasksList extends StatelessWidget {
  final List<Task>    tasks;
  final List<Project> projects;
  final List<Member>  members;
  const _OverdueTasksList({required this.tasks, required this.projects, required this.members});

  @override
  Widget build(BuildContext context) {
    final overdue = tasks
        .where((t) =>
            t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!)); // oldest first

    if (overdue.isEmpty) return const SizedBox.shrink();

    return Column(
      children: overdue.map((t) {
        final proj = projects.cast<Project?>()
                .firstWhere((p) => p!.id == t.projectId, orElse: () => null);

        Member? assignee;
        try {
          assignee = members.firstWhere((m) => t.assignees.contains(m.id));
        } catch (_) {}

        final daysLate = DateTime.now().difference(t.dueDate!).inDays;
        final si       = _stageInfo(t.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _T.red50,
            border: Border.all(color: _T.red.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: Row(children: [
            // Priority accent
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: t.priority == TaskPriority.urgent
                    ? _T.red
                    : t.priority == TaskPriority.high
                        ? _T.amber
                        : _T.slate400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _T.ink)),
                  const SizedBox(height: 3),
                  Row(children: [
                    if (proj != null) ...[
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: proj.color, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(proj.name,
                          style: const TextStyle(
                              fontSize: 11, color: _T.slate500)),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                          color: si.bg,
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(si.shortLabel,
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: si.color)),
                    ),
                  ]),
                ],
              ),
            ),
            // Assignee
            if (assignee != null) ...[
              _AvatarWidget(
                  initials: assignee.initials,
                  color: assignee.color,
                  size: 24),
              const SizedBox(width: 10),
            ],
            // Days late badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: _T.red,
                  borderRadius: BorderRadius.circular(6)),
              child: Text(
                daysLate == 0 ? 'Due today' : '$daysLate d late',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ]),
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
  final Color  color;
  final double size;
  const _AvatarWidget({required this.initials, required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            color: color.withOpacity(0.15), shape: BoxShape.circle),
        child: Center(
          child: Text(initials,
              style: TextStyle(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
      );
}

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

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isActive;
  final String?  badge;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon, required this.label, required this.isActive,
    required this.onTap, this.badge,
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
          child: Row(children: [
            Icon(icon,
                size: 14,
                color: Colors.white.withOpacity(isActive ? 1.0 : 0.5)),
            const SizedBox(width: 9),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: Colors.white.withOpacity(isActive ? 1.0 : 0.5)))),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                    color: _T.blue, borderRadius: BorderRadius.circular(99)),
                child: Text(badge!,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
          ]),
        ),
      ),
    );
  }
}

class _SidebarProjectRow extends StatelessWidget {
  final String name;
  final Color  color;
  final int    count;
  final bool   isActive;
  final VoidCallback onTap;

  const _SidebarProjectRow({
    required this.name, required this.color, required this.count,
    required this.isActive, required this.onTap,
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
          child: Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
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

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: _T.slate400));
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
    final w = size.width, h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.19, h * 0.66), w * 0.065,
        paint..color = Colors.white.withOpacity(0.5));
    canvas.drawCircle(Offset(w * 0.48, h * 0.34), w * 0.065,
        paint..color = Colors.white.withOpacity(0.7));

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.19, h * 0.66)
        ..cubicTo(w * 0.19, h * 0.66, w * 0.30, h * 0.34, w * 0.48, h * 0.34)
        ..cubicTo(w * 0.66, h * 0.34, w * 0.64, h * 0.66, w * 0.81, h * 0.55),
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.35, h * 0.51)
        ..lineTo(w * 0.48, h * 0.65)
        ..lineTo(w * 0.81, h * 0.33),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.077
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
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