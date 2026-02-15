import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/desktop/advance_stage_popup.dart';
import 'package:smooflow/core/models/company.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/repositories/company_repo.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/enums/task_priority.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Brand
  static const blue       = Color(0xFF2563EB);
  static const blueHover  = Color(0xFF1D4ED8);
  static const blue100    = Color(0xFFDBEAFE);
  static const blue50     = Color(0xFFEFF6FF);
  static const teal       = Color(0xFF38BDF8);

  // Semantic
  static const green      = Color(0xFF10B981);
  static const green50    = Color(0xFFECFDF5);
  static const amber      = Color(0xFFF59E0B);
  static const amber50    = Color(0xFFFEF3C7);
  static const red        = Color(0xFFEF4444);
  static const red50      = Color(0xFFFEE2E2);
  static const purple     = Color(0xFF8B5CF6);
  static const purple50   = Color(0xFFF3E8FF);

  // Neutrals
  static const slate50    = Color(0xFFF8FAFC);
  static const slate100   = Color(0xFFF1F5F9);
  static const slate200   = Color(0xFFE2E8F0);
  static const slate300   = Color(0xFFCBD5E1);
  static const slate400   = Color(0xFF94A3B8);
  static const slate500   = Color(0xFF64748B);
  static const ink        = Color(0xFF0F172A);
  static const ink2       = Color(0xFF1E293B);
  static const ink3       = Color(0xFF334155);
  static const white      = Colors.white;

  // Dimensions
  static const sidebarW  = 220.0;
  static const topbarH   = 52.0;
  static const detailW   = 400.0;

  // Radius
  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
enum TaskFilter { all, mine, overdue }
enum ViewMode { board, list }

class DesignStageInfo {
  final TaskStatus stage;
  final String label;
  final String shortLabel;
  final Color color;
  final Color bg;
  const DesignStageInfo(this.stage, this.label, this.shortLabel, this.color, this.bg);
}

const List<DesignStageInfo> kStages = [
  DesignStageInfo(TaskStatus.pending,      'Initialized',       'Init',     _T.slate500, _T.slate100),
  DesignStageInfo(TaskStatus.designing,    'Designing',         'Design',   _T.purple,   _T.purple50),
  DesignStageInfo(TaskStatus.waitingApproval, 'Awaiting Approval', 'Review', _T.amber,   _T.amber50),
  DesignStageInfo(TaskStatus.clientApproved,  'Client Approved',   'Approved', _T.green, _T.green50),
  DesignStageInfo(TaskStatus.printing,  'Printing',   'Printing', _T.blue, _T.blue100),
];

DesignStageInfo stageInfo(TaskStatus s) => kStages.firstWhere((i) => i.stage == s);
int stageIndex(TaskStatus s) => kStages.indexWhere((i) => i.stage == s);

/// Extension to compute the next stage in the design pipeline.
extension TaskStatusNext on TaskStatus {
  TaskStatus? get nextStage => switch (this) {
    TaskStatus.pending         => TaskStatus.designing,
    TaskStatus.designing       => TaskStatus.waitingApproval,
    TaskStatus.waitingApproval => TaskStatus.clientApproved,
    TaskStatus.clientApproved  => TaskStatus.printing,
    _                          => null,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOT DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class DesignDashboardScreen extends ConsumerStatefulWidget {
  const DesignDashboardScreen({super.key});

  @override
  ConsumerState<DesignDashboardScreen> createState() => _DesignDashboardScreenState();
}

class _DesignDashboardScreenState extends ConsumerState<DesignDashboardScreen> {
  final _currentUser = LoginService.currentUser!;

  // Read from Riverpod — never mutate directly
  List<Project> get _projects => ref.watch(projectNotifierProvider);
  List<Task> get _tasks => ref.watch(taskNotifierProvider).where((t) =>
      t.status == TaskStatus.pending ||
      t.status == TaskStatus.designing ||
      t.status == TaskStatus.waitingApproval ||
      t.status == TaskStatus.clientApproved).toList();

  String? _selectedProjectId;
  int?    _selectedTaskId;
  TaskFilter _filter   = TaskFilter.all;
  ViewMode   _viewMode = ViewMode.board;
  String     _searchQuery = '';

  final _searchCtrl = TextEditingController();

  Task? get _selectedTask => _selectedTaskId == null
      ? null
      : _tasks.cast<Task?>().firstWhere((t) => t!.id == _selectedTaskId, orElse: () => null);

  List<Task> get _visibleTasks {
    return _tasks.where((t) {
      if (_selectedProjectId != null && t.projectId != _selectedProjectId) return false;
      if (_filter == TaskFilter.mine && !t.assignees.contains(_currentUser.id)) return false;
      if (_filter == TaskFilter.overdue) {
        final d = t.dueDate;
        if (d == null || !d.isBefore(DateTime.now())) return false;
      }
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        return t.name.toLowerCase().contains(q) ||
            (t.description ?? '').toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  void _selectTask(int id) => setState(() => _selectedTaskId = id);
  void _closeDetail()      => setState(() => _selectedTaskId = null);

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

  /// Add a new project through the Riverpod notifier.
  Future<void> _addProject(Project p) async {
    // await ref.read(projectNotifierProvider.notifier).addProject(p);
    if (!mounted) return;
    _showSnack('Project "${p.name}" created', _T.green);
  }

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.slate50,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              if (_selectedTaskId != null) { _closeDetail(); return KeyEventResult.handled; }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          children: [
            // ── Sidebar ───────────────────────────────────────────────────
            _Sidebar(
              projects: _projects,
              tasks: _tasks,
              selectedProjectId: _selectedProjectId,
              viewMode: _viewMode,
              onProjectSelected: (id) => setState(() => _selectedProjectId = id),
              onViewModeChanged: (m)  => setState(() => _viewMode = m),
              onNewProject: _showProjectModal,
            ),
            // ── Main area ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  _Topbar(
                    selectedProject: _selectedProjectId != null
                        ? _projects.cast<Project?>().firstWhere((p) => p!.id == _selectedProjectId, orElse: () => null)
                        : null,
                    filter: _filter,
                    viewMode: _viewMode,
                    searchCtrl: _searchCtrl,
                    onFilterChanged: (f)  => setState(() => _filter = f),
                    onViewModeChanged: (m) => setState(() => _viewMode = m),
                    onSearchChanged: (q)  => setState(() => _searchQuery = q),
                    onNewTask: _showTaskModal,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _viewMode == ViewMode.board
                              ? _BoardView(
                                  tasks: _visibleTasks,
                                  projects: _projects,
                                  selectedTaskId: _selectedTaskId,
                                  onTaskSelected: _selectTask,
                                  onAddTask: _showTaskModal,
                                )
                              : _TaskListView(
                                  tasks: _visibleTasks,
                                  projects: _projects,
                                  selectedTaskId: _selectedTaskId,
                                  onTaskSelected: _selectTask,
                                ),
                        ),
                        // ── Detail panel ──────────────────────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          width: _selectedTaskId != null ? _T.detailW : 0,
                          child: _selectedTaskId != null && _selectedTask != null
                              ? _DetailPanel(
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
    );
  }

  // ── Modal launchers ────────────────────────────────────────────────────────

  void _showProjectModal() {
    showDialog(
      context: context,
      builder: (_) => _ProjectModal(onSave: _addProject),
    );
  }

  void _showTaskModal() async {
    // Determine next id from current task list
    final nextId = (_tasks.isEmpty ? 0 : _tasks.map((t) => t.id).reduce((a, b) => a > b ? a : b)) + 1;
    showDialog(
      context: context,
      builder: (_) => _TaskModal(
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
class _Sidebar extends ConsumerWidget {
  final List<Project> projects;
  final List<Task> tasks;
  final String? selectedProjectId;
  final ViewMode viewMode;
  final ValueChanged<String?> onProjectSelected;
  final ValueChanged<ViewMode> onViewModeChanged;
  final VoidCallback onNewProject;

  const _Sidebar({
    required this.projects, required this.tasks, required this.selectedProjectId,
    required this.viewMode, required this.onProjectSelected,
    required this.onViewModeChanged, required this.onNewProject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = tasks.where((t) => t.status != TaskStatus.clientApproved).length;
    final members = ref.watch(memberNotifierProvider).members;

    return Container(
      width: _T.sidebarW,
      color: _T.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            height: _T.topbarH,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x10FFFFFF)))),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_T.blue, _T.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Center(child: _SmooflowLogoMark(size: 16)),
                ),
                const SizedBox(width: 9),
                const Text('smooflow', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.35), borderRadius: BorderRadius.circular(4)),
                  child: const Text('DESIGN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF93C5FD))),
                ),
              ],
            ),
          ),

          // Nav
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarLabel('Workspace'),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: Icons.view_kanban_outlined,
                  label: 'Board',
                  isActive: viewMode == ViewMode.board,
                  badge: activeCount.toString(),
                  onTap: () => onViewModeChanged(ViewMode.board),
                ),
                _SidebarNavItem(
                  icon: Icons.list_alt_outlined,
                  label: 'All Tasks',
                  isActive: viewMode == ViewMode.list,
                  onTap: () => onViewModeChanged(ViewMode.list),
                ),
              ],
            ),
          ),

          // Projects
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
                    count: tasks.length,
                    isActive: selectedProjectId == null,
                    onTap: () => onProjectSelected(null),
                  ),
                  ...projects.map((p) {
                    final cnt = tasks.where((t) => t.projectId == p.id).length;
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

          // New project button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: InkWell(
              onTap: onNewProject,
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

          // Team section
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x12FFFFFF)))),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DESIGN TEAM', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Colors.white.withOpacity(0.25))),
                const SizedBox(height: 10),
                ...members.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _AvatarWidget(initials: m.initials, color: m.color, size: 26),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.5)))),
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

class _SidebarLabel extends StatelessWidget {
  final String text;
  const _SidebarLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 4),
    child: Text(text.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Colors.white.withOpacity(0.28))),
  );
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _SidebarNavItem({required this.icon, required this.label, required this.isActive, required this.onTap, this.badge});

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
              Icon(icon, size: 14, color: Colors.white.withOpacity(isActive ? 1.0 : 0.5)),
              const SizedBox(width: 9),
              Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: Colors.white.withOpacity(isActive ? 1.0 : 0.5)))),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(color: _T.blue, borderRadius: BorderRadius.circular(99)),
                  child: Text(badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
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

  const _SidebarProjectRow({required this.name, required this.color, required this.count, required this.isActive, required this.onTap});

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
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 9),
              Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: Colors.white.withOpacity(isActive ? 0.9 : 0.55)))),
              Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.25))),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final Project? selectedProject;
  final TaskFilter filter;
  final ViewMode viewMode;
  final TextEditingController searchCtrl;
  final ValueChanged<TaskFilter> onFilterChanged;
  final ValueChanged<ViewMode> onViewModeChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNewTask;

  final _currentUser = LoginService.currentUser!;

  _Topbar({
    required this.selectedProject, required this.filter, required this.viewMode,
    required this.searchCtrl, required this.onFilterChanged,
    required this.onViewModeChanged, required this.onSearchChanged, required this.onNewTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _T.topbarH,
      decoration: const BoxDecoration(color: _T.white, border: Border(bottom: BorderSide(color: _T.slate200))),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Breadcrumb
          Text('Design Board', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.ink3)),
          if (selectedProject != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('›', style: TextStyle(color: _T.slate300, fontSize: 13)),
            ),
            Text(selectedProject!.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.ink)),
          ],
          const SizedBox(width: 16),

          // Search
          Container(
            width: 200,
            height: 30,
            decoration: BoxDecoration(
              color: _T.slate50,
              border: Border.all(color: _T.slate200),
              borderRadius: BorderRadius.circular(_T.r),
            ),
            child: Row(
              children: [
                const SizedBox(width: 9),
                const Icon(Icons.search, size: 14, color: _T.slate400),
                const SizedBox(width: 7),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: onSearchChanged,
                    style: const TextStyle(fontSize: 12.5, color: _T.ink),
                    decoration: const InputDecoration(
                      hintText: 'Search tasks…',
                      hintStyle: TextStyle(color: _T.slate400, fontSize: 12.5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // View toggle
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: _T.slate100, borderRadius: BorderRadius.circular(_T.r)),
            child: Row(
              children: [
                _ViewToggleBtn(icon: Icons.view_kanban_outlined, label: 'Board', isActive: viewMode == ViewMode.board, onTap: () => onViewModeChanged(ViewMode.board)),
                _ViewToggleBtn(icon: Icons.list_alt_outlined,    label: 'List',  isActive: viewMode == ViewMode.list,  onTap: () => onViewModeChanged(ViewMode.list)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Filters
          Row(
            children: [
              _FilterChip(label: 'All',     isActive: filter == TaskFilter.all,     onTap: () => onFilterChanged(TaskFilter.all)),
              const SizedBox(width: 4),
              _FilterChip(label: 'Mine',    isActive: filter == TaskFilter.mine,    onTap: () => onFilterChanged(TaskFilter.mine)),
              const SizedBox(width: 4),
              _FilterChip(label: 'Overdue', isActive: filter == TaskFilter.overdue, onTap: () => onFilterChanged(TaskFilter.overdue)),
            ],
          ),

          const Spacer(),

          // New task button
          GestureDetector(
            onTap: onNewTask,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _T.blue,
                borderRadius: BorderRadius.circular(_T.r),
                boxShadow: [BoxShadow(color: _T.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('New Task', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User chip
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            decoration: BoxDecoration(border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(99)),
            child: Row(
              children: [
                _AvatarWidget(initials: _currentUser.initials, color: _T.blue, size: 24),
                const SizedBox(width: 7),
                Text(_currentUser.nameShort, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _T.ink3)),
                const SizedBox(width: 5),
                const Icon(Icons.keyboard_arrow_down, size: 14, color: _T.slate400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ViewToggleBtn({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? _T.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: isActive ? _T.ink : _T.slate500),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? _T.ink : _T.slate500)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? _T.ink : _T.white,
          border: Border.all(color: isActive ? _T.ink : _T.slate200),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? _T.white : _T.slate500)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOARD VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _BoardView extends StatelessWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final int? selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  final VoidCallback onAddTask;

  const _BoardView({required this.tasks, required this.projects, required this.selectedTaskId, required this.onTaskSelected, required this.onAddTask});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.slate50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        children: kStages.map((si) {
          final stageTasks = tasks.where((t) => t.status == si.stage).toList();
          return _KanbanLane(
            stageInfo: si,
            tasks: stageTasks,
            projects: projects,
            selectedTaskId: selectedTaskId,
            onTaskSelected: onTaskSelected,
            // Only allow adding from Initialized lane
            onAddTask: si.stage == TaskStatus.pending ? onAddTask : null,
          );
        }).toList(),
      ),
    );
  }
}

class _KanbanLane extends StatelessWidget {
  final DesignStageInfo stageInfo;
  final List<Task> tasks;
  final List<Project> projects;
  final int? selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  final VoidCallback? onAddTask;

  const _KanbanLane({required this.stageInfo, required this.tasks, required this.projects, required this.selectedTaskId, required this.onTaskSelected, this.onAddTask});

  @override
  Widget build(BuildContext context) {
    final isApproved = stageInfo.stage == TaskStatus.clientApproved;

    return Container(
      width: 258,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: _T.white,
        border: Border.all(color: _T.slate200),
        borderRadius: BorderRadius.circular(_T.rLg),
      ),
      child: Column(
        children: [
          // Lane header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _T.slate100))),
            child: Row(
              children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: stageInfo.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Expanded(child: Text(stageInfo.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _T.ink))),
                if (isApproved) ...[
                  Icon(Icons.lock_outline, size: 12, color: stageInfo.color),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isApproved ? stageInfo.bg : _T.slate100,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('${tasks.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isApproved ? stageInfo.color : _T.slate500)),
                ),
              ],
            ),
          ),

          // Cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                if (tasks.isEmpty)
                  _LaneEmpty()
                else
                  ...tasks.map((t) {
                    final proj = projects.cast<Project?>().firstWhere((p) => p!.id == t.projectId, orElse: () => null) ?? projects.first;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TaskCard(
                        task: t,
                        project: proj,
                        isSelected: selectedTaskId == t.id,
                        onTap: () => onTaskSelected(t.id),
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Add button (Initialized lane only)
          if (onAddTask != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: _AddCardButton(onTap: onAddTask!),
            ),
        ],
      ),
    );
  }
}

class _LaneEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(Icons.assignment_outlined, size: 28, color: _T.slate300),
        SizedBox(height: 8),
        Text('No tasks here', style: TextStyle(fontSize: 12, color: _T.slate300)),
      ],
    ),
  );
}

class _AddCardButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_T.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_T.r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: _T.slate200, width: 1.5),
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 13, color: _T.slate400),
              SizedBox(width: 6),
              Text('Add task', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: _T.slate400)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TaskCard extends ConsumerWidget {
  final Task task;
  final Project project;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.project, required this.isSelected, required this.onTap});

  Color get _priorityColor => switch (task.priority) {
    TaskPriority.urgent => _T.red,
    TaskPriority.high   => _T.amber,
    TaskPriority.normal => _T.slate200,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = task.dueDate;
    final now = DateTime.now();
    final isOverdue = d != null && d.isBefore(now);
    final isSoon    = d != null && !isOverdue && d.difference(now).inDays <= 3;

    Member? member;
    try {
      member = ref.watch(memberNotifierProvider).members.firstWhere((m) => task.assignees.contains(m.id));
    } catch (_) {
      member = null;
    }

    return Material(
      color: _T.white,
      borderRadius: BorderRadius.circular(_T.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_T.r),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? _T.blue : _T.slate200, width: isSelected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(_T.r),
            boxShadow: isSelected ? [BoxShadow(color: _T.blue.withOpacity(0.12), blurRadius: 8, spreadRadius: 1)] : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Priority accent bar
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: _priorityColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(_T.r), bottomLeft: Radius.circular(_T.r)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.ink, height: 1.4)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: project.color, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Expanded(child: Text(project.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: _T.slate400))),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _PriorityPill(priority: task.priority),
                            const SizedBox(width: 6),
                            if (member != null) _AvatarWidget(initials: member.initials, color: member.color, size: 20),
                            const Spacer(),
                            if (d != null)
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 10, color: isOverdue ? _T.red : isSoon ? _T.amber : _T.slate400),
                                  const SizedBox(width: 4),
                                  Text(_fmtDate(d), style: TextStyle(fontSize: 11, fontWeight: isOverdue || isSoon ? FontWeight.w600 : FontWeight.w500, color: isOverdue ? _T.red : isSoon ? _T.amber : _T.slate400)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST VIEW  (renamed to _TaskListView to avoid conflict with Flutter's ListView)
// ─────────────────────────────────────────────────────────────────────────────
class _TaskListView extends ConsumerWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final int? selectedTaskId;
  final ValueChanged<int> onTaskSelected;

  const _TaskListView({required this.tasks, required this.projects, required this.selectedTaskId, required this.onTaskSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: _T.slate50,
      child: Column(
        children: [
          // Table header
          Container(
            color: _T.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TableHeader('Task')),
                Expanded(flex: 2, child: _TableHeader('Project')),
                Expanded(flex: 2, child: _TableHeader('Stage')),
                Expanded(flex: 2, child: _TableHeader('Assignee')),
                Expanded(flex: 1, child: _TableHeader('Due')),
                Expanded(flex: 1, child: _TableHeader('Priority')),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _T.slate200),
          // Rows
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: _T.slate100),
              itemBuilder: (_, i) {
                final t = tasks[i];
                final p = projects.cast<Project?>().firstWhere((pr) => pr!.id == t.projectId, orElse: () => null) ?? projects.first;

                Member? m;
                try {
                  m = ref.watch(memberNotifierProvider).members.firstWhere((mem) => t.assignees.contains(mem.id));
                } catch (_) {
                  m = null;
                }

                final s = stageInfo(t.status);
                final d = t.dueDate;
                final now = DateTime.now();
                final isOverdue = d != null && d.isBefore(now);
                final isSoon    = d != null && !isOverdue && d.difference(now).inDays <= 3;

                return Material(
                  color: selectedTaskId == t.id ? _T.blue50 : _T.white,
                  borderRadius: BorderRadius.circular(_T.r),
                  child: InkWell(
                    onTap: () => onTaskSelected(t.id),
                    borderRadius: BorderRadius.circular(_T.r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          // Task name + description
                          Expanded(flex: 3, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.ink)),
                              if (t.description != null && t.description!.isNotEmpty)
                                Text(
                                  t.description!.length > 55 ? '${t.description!.substring(0, 55)}…' : t.description!,
                                  style: const TextStyle(fontSize: 11.5, color: _T.slate400),
                                ),
                            ]),
                          )),
                          // Project
                          Expanded(flex: 2, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(children: [
                              Container(width: 7, height: 7, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: _T.slate500))),
                            ]),
                          )),
                          // Stage
                          Expanded(flex: 2, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _StagePill(stageInfo: s),
                          )),
                          // Assignee — always occupies its flex slot
                          Expanded(flex: 2, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: m != null
                                ? Row(children: [
                                    _AvatarWidget(initials: m.initials, color: m.color, size: 22),
                                    const SizedBox(width: 7),
                                    Expanded(child: Text(m.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: _T.slate500))),
                                  ])
                                : const Text('—', style: TextStyle(color: _T.slate400)),
                          )),
                          // Due date
                          Expanded(flex: 1, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              d != null ? _fmtDate(d) : '—',
                              style: TextStyle(fontSize: 12.5, fontWeight: isOverdue || isSoon ? FontWeight.w600 : FontWeight.w400, color: isOverdue ? _T.red : isSoon ? _T.amber : _T.slate500),
                            ),
                          )),
                          // Priority
                          Expanded(flex: 1, child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _PriorityPill(priority: t.priority),
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: _T.slate400));
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _DetailPanel extends ConsumerStatefulWidget {
  final Task task;
  final List<Project> projects;
  final VoidCallback onClose;
  final VoidCallback onAdvance;

  const _DetailPanel({required this.task, required this.projects, required this.onClose, required this.onAdvance});

  @override
  ConsumerState<_DetailPanel> createState() => __DetailPanelState();
}

class __DetailPanelState extends ConsumerState<_DetailPanel> {

  // GlobalKey for the button
  final GlobalKey _advanceButtonKey = GlobalKey();

  // if (task.status.nextStage == TaskStatus.printing) 
  void approveDesignStage() async {
    await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: widget.task.id, newStatus: TaskStatus.clientApproved);
    setState(() {});
  }

  void _showMoveToNextStageDialog() {

    final nextStage = widget.task.status.nextStage;

    if (nextStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No explicit next stage from current phase")));
      return;
    }

    AdvanceStagePopup.show(
      context: context,
      buttonKey: _advanceButtonKey,
      taskId: widget.task.id,
      onConfirm: (notes) async {
        await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: widget.task.id, newStatus: nextStage);
        setState(() {
          // Update task status
          // task.status = getNextStatus(task.status);
        });
        
        if (notes != null) {
          // Save notes to activity timeline
          // task.addActivity(notes);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final curIdx = stageIndex(widget.task.status);
    final si     = stageInfo(widget.task.status);
    final proj   = widget.projects.cast<Project?>().firstWhere((p) => p!.id == widget.task.projectId, orElse: () => null) ?? widget.projects.first;

    Member? member;
    try {
      member = ref.watch(memberNotifierProvider).members.firstWhere((m) => widget.task.assignees.contains(m.id));
    } catch (_) {
      member = null;
    }

    final d = widget.task.dueDate;
    final now = DateTime.now();
    final isOverdue = d != null && d.isBefore(now);
    final isSoon    = d != null && !isOverdue && d.difference(now).inDays <= 3;
    final next      = widget.task.status.nextStage;

    return Container(
      width: _T.detailW,
      decoration: const BoxDecoration(color: _T.white, border: Border(left: BorderSide(color: _T.slate200))),
      child: Column(
        children: [
          // Detail topbar
          Container(
            height: _T.topbarH,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _T.slate200))),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                    child: const Icon(Icons.close, size: 13, color: _T.slate400),
                  ),
                ),
                const SizedBox(width: 10),
                Text('TASK-${widget.task.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: _T.slate400)),
                const Spacer(),
              ],
            ),
          ),

          // Stage stepper
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _T.slate200))),
            child: Row(
              children: List.generate(kStages.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stageIdx = i ~/ 2;
                  final done = stageIdx < curIdx;
                  return Expanded(child: Container(height: 2, color: done ? _T.blue : _T.slate200));
                }
                final idx = i ~/ 2;
                final s = kStages[idx];
                final isDone    = idx < curIdx;
                final isCurrent = idx == curIdx;
                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? _T.blue : isCurrent ? _T.white : _T.slate100,
                        border: Border.all(color: isDone ? _T.blue : isCurrent ? _T.blue : _T.slate200, width: isCurrent ? 2 : 1.5),
                        boxShadow: isCurrent ? [BoxShadow(color: _T.blue.withOpacity(0.15), blurRadius: 6, spreadRadius: 1)] : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : isCurrent
                                ? Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle))
                                : Container(width: 5, height: 5, decoration: const BoxDecoration(color: _T.slate300, shape: BoxShape.circle)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(s.shortLabel, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isCurrent ? _T.blue : isDone ? _T.ink3 : _T.slate400)),
                  ],
                );
              }),
            ),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(widget.task.name, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: _T.ink, letterSpacing: -0.3, height: 1.35)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: proj.color, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(proj.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _T.slate500)),
                  ]),
                  const SizedBox(height: 18),

                  // Details grid
                  const _DetailSectionTitle('Details'),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _DetailMetaCell(label: 'Current Stage', child: _StagePill(stageInfo: si)),
                      _DetailMetaCell(label: 'Priority', child: _PriorityPill(priority: widget.task.priority)),
                      if (member != null)
                        _DetailMetaCell(label: 'Assignee', child: Row(children: [
                          _AvatarWidget(initials: member.initials, color: member.color, size: 22),
                          const SizedBox(width: 6),
                          Expanded(child: Text(member.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _T.ink3))),
                        ])),
                      _DetailMetaCell(
                        label: 'Due Date',
                        child: d != null
                            ? Row(children: [
                                Text(_fmtDate(d), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isOverdue ? _T.red : isSoon ? _T.amber : _T.ink3)),
                                if (isOverdue) ...[const SizedBox(width: 6), const _Badge('Overdue', _T.red, _T.red50)],
                                if (isSoon && !isOverdue) ...[const SizedBox(width: 6), const _Badge('Due soon', _T.amber, _T.amber50)],
                              ])
                            : const Text('—', style: TextStyle(color: _T.slate400)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Description
                  if (widget.task.description.trim().isNotEmpty) ...[
                    const _DetailSectionTitle('Description'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _T.slate50, border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                      child: Text(widget.task.description, style: const TextStyle(fontSize: 13, color: _T.slate500, height: 1.65)),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Stage pipeline
                  const _DetailSectionTitle('Stage Pipeline'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                    child: Column(
                      children: kStages.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final s = entry.value;
                        final isDone    = idx < curIdx;
                        final isCurrent = idx == curIdx;
                        final isLast    = idx == kStages.length - 1;
                        return Container(
                          decoration: BoxDecoration(
                            color: isCurrent ? s.bg : Colors.transparent,
                            border: isLast ? null : const Border(bottom: BorderSide(color: _T.slate100)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(color: isDone ? _T.blue : isCurrent ? s.color : _T.slate100, shape: BoxShape.circle),
                                child: Center(
                                  child: isDone
                                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                                      : isCurrent
                                          ? Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
                                          : Container(width: 5, height: 5, decoration: const BoxDecoration(color: _T.slate300, shape: BoxShape.circle)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(s.label, style: TextStyle(fontSize: 12.5, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500, color: isCurrent ? s.color : isDone ? _T.ink3 : _T.slate400))),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(color: s.bg, border: Border.all(color: s.color.withOpacity(0.3)), borderRadius: BorderRadius.circular(99)),
                                  child: Text('Current', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: s.color)),
                                ),
                              if (isDone)
                                const Text('✓ Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _T.slate400)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer action
          Container(
            decoration: const BoxDecoration(color: _T.slate50, border: Border(top: BorderSide(color: _T.slate200))),
            padding: const EdgeInsets.all(14),
            child: next != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('ADVANCE STAGE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: _T.slate400)),
                      const SizedBox(height: 9),
                      GestureDetector(
                        key: _advanceButtonKey,
                        onTap: next == TaskStatus.clientApproved ? approveDesignStage : (next == TaskStatus.printing || next == TaskStatus.designing || next == TaskStatus.waitingApproval) ? _showMoveToNextStageDialog : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color:  next == TaskStatus.clientApproved ? _T.green : (next == TaskStatus.printing || next == TaskStatus.designing || next == TaskStatus.waitingApproval)? _T.blue : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(_T.r),
                            boxShadow: next == TaskStatus.clientApproved || next == TaskStatus.printing || next == TaskStatus.designing || next == TaskStatus.waitingApproval || next == TaskStatus.waitingApproval? [BoxShadow(color: (next == TaskStatus.clientApproved ? _T.green : _T.blue).withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 2))] : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                next == TaskStatus.clientApproved ? Icons.check : Icons.arrow_forward,
                                size: 15, color: next == TaskStatus.clientApproved || next == TaskStatus.printing || next == TaskStatus.designing || next == TaskStatus.waitingApproval || next == TaskStatus.waitingApproval ? Colors.white : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                next == TaskStatus.clientApproved ? 'Confirm Client Approval' : 'Move to "${stageInfo(next).label}"',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: next == TaskStatus.clientApproved || next == TaskStatus.printing || next == TaskStatus.designing || next == TaskStatus.waitingApproval || next == TaskStatus.waitingApproval? Colors.white : Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: const [
                      Icon(Icons.lock_outline, size: 14, color: _T.slate400),
                      SizedBox(width: 8),
                      Expanded(child: Text('Handed off to production — design locked', style: TextStyle(fontSize: 12.5, color: _T.slate400))),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  final String text;
  const _DetailSectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: _T.slate400));
}

class _DetailMetaCell extends StatelessWidget {
  final String label;
  final Widget child;
  const _DetailMetaCell({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _T.slate400)),
      const SizedBox(height: 4),
      child,
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  const _AvatarWidget({required this.initials, required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
    child: Center(child: Text(initials, style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w700, color: color))),
  );
}

class _PriorityPill extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityPill({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (text, color, bg) = switch (priority) {
      TaskPriority.urgent => ('Urgent', _T.red,    _T.red50),
      TaskPriority.high   => ('High',   _T.amber,  _T.amber50),
      TaskPriority.normal => ('Normal', _T.slate500, _T.slate100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _StagePill extends StatelessWidget {
  final DesignStageInfo stageInfo;
  const _StagePill({required this.stageInfo});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: stageInfo.bg, borderRadius: BorderRadius.circular(99)),
    child: Text(stageInfo.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stageInfo.color)),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color, bg;
  const _Badge(this.text, this.color, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
    child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
  );
}

class _SmooflowLogoMark extends StatelessWidget {
  final double size;
  const _SmooflowLogoMark({required this.size});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.19, h * 0.66), w * 0.065, paint..color = Colors.white.withOpacity(0.5));
    canvas.drawCircle(Offset(w * 0.48, h * 0.34), w * 0.065, paint..color = Colors.white.withOpacity(0.7));

    final flowPaint = Paint()..color = Colors.white.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = w * 0.055..strokeCap = StrokeCap.round;
    final flowPath = Path()
      ..moveTo(w * 0.19, h * 0.66)
      ..cubicTo(w * 0.19, h * 0.66, w * 0.30, h * 0.34, w * 0.48, h * 0.34)
      ..cubicTo(w * 0.66, h * 0.34, w * 0.64, h * 0.66, w * 0.81, h * 0.55);
    canvas.drawPath(flowPath, flowPaint);

    final checkPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = w * 0.077..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
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
// MODALS
// ─────────────────────────────────────────────────────────────────────────────

// ── Project Modal ─────────────────────────────────────────────────────────────
class _ProjectModal extends ConsumerStatefulWidget {
  final Future<void> Function(Project) onSave;
  const _ProjectModal({required this.onSave});
  @override
  ConsumerState<_ProjectModal> createState() => _ProjectModalState();
}

class _ProjectModalState extends ConsumerState<_ProjectModal> {
  final _name  = TextEditingController();
  final _desc  = TextEditingController();
  Color _color = _T.blue;
  DateTime? _due;
  bool _saving = false;
  Company? _client;

  static const _colors = [_T.blue, _T.purple, _T.green, _T.amber, _T.red, Color(0xFF0EA5E9)];

  final List<Company> _clients = [...CompanyRepo.companies];
 
  @override
  void dispose() { _name.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _client == null) return;
    setState(() => _saving = true);

    // Optional: Unfocus keyboard
    FocusScope.of(context).unfocus();

    // Proceed with form submission

    try {
      await ref
        .read(projectNotifierProvider.notifier)
        .create(
          Project.create(
            name: _name.text,
            description: _desc.text,
            // TODO: let user assign incharge men when creating project
            assignedManagers: [],
            client: _client!,
            priority: 1,
            dueDate: _due,
            estimatedProductionStart: DateTime.now(),
          ),
        );
        // Notify organization state about this adding of a project to update projectsLastAdded
        ref.read(organizationNotifierProvider.notifier).projectAdded();

        if (mounted) Navigator.pop(context);
    } catch(e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to Create Project")));
      return;
    }

    setState(() => _saving = true);
    
  }

  @override
  Widget build(BuildContext context) => _ModalShell(
    icon: Icons.folder_outlined,
    iconColor: _T.blue,
    title: 'New Project',
    subtitle: 'Create a project to group design tasks',
    onClose: () => Navigator.pop(context),
    onSave: _saving ? null : _submit,
    saveLabel: _saving ? 'Creating…' : 'Create Project',
    child: Column(children: [
      _ModalField(
        label: 'Project Name', required: true,
        child: _ModalInput(ctrl: _name, hint: 'e.g. Spring Campaign 2026'),
      ),
      const SizedBox(height: 16),
      _ModalField(
        label: 'Customer',
        required: true,
        child: _clients.isEmpty
            ? const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : _ModalDropdown<Company?>(
                value: _client,
                items: _clients.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.name, style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (v) => setState(() => _client = v),
              ),
      ),
      const SizedBox(height: 16),
      _ModalField(
        label: 'Description',
        child: _ModalTextarea(ctrl: _desc, hint: 'What is this project about?'),
      ),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _ModalField(
          label: 'Due Date',
          child: GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(), lastDate: DateTime(2028),
                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _T.blue)), child: child!),
              );
              if (d != null) setState(() => _due = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: _T.slate50, border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: _T.slate400),
                const SizedBox(width: 8),
                Text(_due != null ? _fmtDate(_due!) : 'Select date', style: TextStyle(fontSize: 13, color: _due != null ? _T.ink : _T.slate400)),
              ]),
            ),
          ),
        )),
        const SizedBox(width: 12),
        Expanded(child: _ModalField(
          label: 'Colour',
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: _colors.map((c) => GestureDetector(
              onTap: () => setState(() => _color = c),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: _color == c ? _T.ink : Colors.transparent, width: 2)),
                child: _color == c ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
            )).toList(),
          ),
        )),
      ]),
    ]),
  );
}

// ── Task Modal ────────────────────────────────────────────────────────────────
class _TaskModal extends ConsumerStatefulWidget {
  final List<Project> projects;
  final String? preselectedProjectId;
  final int nextId;

  const _TaskModal({required this.projects, this.preselectedProjectId, required this.nextId});

  @override
  ConsumerState<_TaskModal> createState() => _TaskModalState();
}

class _TaskModalState extends ConsumerState<_TaskModal> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  late String? _projectId;
  String? _assigneeId;
  DateTime? _due;
  TaskPriority _priority = TaskPriority.normal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _projectId = widget.preselectedProjectId;
  }

  @override
  void dispose() { _name.dispose(); _desc.dispose(); super.dispose(); }

  List<Member> get _members => ref.watch(memberNotifierProvider).members;

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _projectId == null) return;
    setState(() => _saving = true);

    final assignees = _assigneeId != null ? [_assigneeId!] : <String>[];

    final newTask = Task.create(
      name: _name.text.trim(),
      description: _desc.text.trim(),
      dueDate: null,
      assignees: assignees,
      projectId: _projectId!,
    );

    await ref.read(createProjectTaskProvider(newTask));

    setState(() => _saving = false);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Task created")));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    
    return _ModalShell(
      icon: Icons.assignment_outlined,
      iconColor: _T.blue,
      title: 'New Task',
      subtitle: 'Initializes in the Initialized stage',
      onClose: () => Navigator.pop(context),
      onSave: _saving ? null : _submit,
      saveLabel: _saving ? 'Creating…' : 'Create Task',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _ModalField(
          label: 'Task Name', required: true,
          child: _ModalInput(ctrl: _name, hint: 'e.g. Hero banner — Spring campaign'),
        ),
        const SizedBox(height: 16),
        _ModalField(
          label: 'Description',
          child: _ModalTextarea(ctrl: _desc, hint: 'Deliverable details, dimensions, notes…'),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _ModalField(
            label: 'Project', required: true,
            child: _ModalDropdown<String?>(
              value: _projectId,
              items: widget.projects.map((p) => DropdownMenuItem(
                value: p.id,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  ]
                ),
              )).toList(),
              onChanged: (v) => setState(() => _projectId = v!),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: _ModalField(
            label: 'Assign To',
            child: _members.isEmpty
                ? const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : _ModalDropdown<String?>(
                    value: _assigneeId,
                    items: _members.map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Row(children: [
                        _AvatarWidget(initials: m.initials, color: m.color, size: 20),
                        const SizedBox(width: 8),
                        Text(m.name, style: const TextStyle(fontSize: 13)),
                      ]),
                    )).toList(),
                    onChanged: (v) => setState(() => _assigneeId = v),
                  ),
          )),
        ]),
        // const SizedBox(height: 16),
        // Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        //   Expanded(child: _ModalField(
        //     label: 'Due Date',
        //     child: GestureDetector(
        //       onTap: () async {
        //         final d = await showDatePicker(
        //           context: context,
        //           initialDate: DateTime.now().add(const Duration(days: 7)),
        //           firstDate: DateTime.now(), lastDate: DateTime(2028),
        //           builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _T.blue)), child: child!),
        //         );
        //         if (d != null) setState(() => _due = d);
        //       },
        //       child: Container(
        //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        //         decoration: BoxDecoration(color: _T.slate50, border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
        //         child: Row(children: [
        //           const Icon(Icons.calendar_today_outlined, size: 14, color: _T.slate400),
        //           const SizedBox(width: 8),
        //           Text(_due != null ? _fmtDate(_due!) : 'Select date', style: TextStyle(fontSize: 13, color: _due != null ? _T.ink : _T.slate400)),
        //         ]),
        //       ),
        //     ),
        //   )),
        //   const SizedBox(width: 12),
        //   Expanded(child: _ModalField(
        //     label: 'Priority',
        //     child: _ModalDropdown<TaskPriority>(
        //       value: _priority,
        //       items: TaskPriority.values.map((p) => DropdownMenuItem(
        //         value: p,
        //         child: Text(_priorityLabel(p), style: const TextStyle(fontSize: 13)),
        //       )).toList(),
        //       onChanged: (v) => setState(() => _priority = v!),
        //     ),
        //   )),
        // ]),
      ]),
    );
  }
}

String _priorityLabel(TaskPriority p) => switch (p) {
  TaskPriority.normal => 'Normal',
  TaskPriority.high   => 'High',
  TaskPriority.urgent => 'Urgent',
};

// ── Modal Shell ───────────────────────────────────────────────────────────────
class _ModalShell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, saveLabel;
  final VoidCallback onClose;
  final VoidCallback? onSave;   // nullable so caller can disable during async
  final Widget child;

  const _ModalShell({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle, required this.saveLabel,
    required this.onClose, required this.onSave, required this.child,
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: _T.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.rXl)),
    elevation: 24,
    child: SizedBox(
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w800, color: _T.ink, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: _T.slate500)),
              ])),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                  child: const Icon(Icons.close, size: 13, color: _T.slate400),
                ),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(22, 18, 22, 0), child: child),
          const SizedBox(height: 14),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _T.slate200))),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.slate500)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSave,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: onSave != null ? _T.blue : _T.slate300,
                    borderRadius: BorderRadius.circular(_T.r),
                  ),
                  child: Text(saveLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ],
      ),
    ),
  );
}

class _ModalField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  const _ModalField({required this.label, required this.child, this.required = false});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _T.ink3)),
      if (required) const Text(' *', style: TextStyle(color: _T.red, fontSize: 12)),
    ]),
    const SizedBox(height: 6),
    child,
  ]);
}

class _ModalInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const _ModalInput({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    style: const TextStyle(fontSize: 13, color: _T.ink),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _T.slate400),
      filled: true, fillColor: _T.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.blue, width: 2)),
    ),
  );
}

class _ModalTextarea extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const _ModalTextarea({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    maxLines: 3,
    style: const TextStyle(fontSize: 13, color: _T.ink),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _T.slate400),
      filled: true, fillColor: _T.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.blue, width: 2)),
    ),
  );
}

class _ModalDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _ModalDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    items: items,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 13, color: _T.ink),
    decoration: InputDecoration(
      filled: true, fillColor: _T.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.blue, width: 2)),
    ),
    dropdownColor: Colors.white,
    borderRadius: BorderRadius.circular(_T.r),
    icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: _T.slate400),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
String _fmtDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}