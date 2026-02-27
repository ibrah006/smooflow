import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/desktop/project_empty_state.dart';
import 'package:smooflow/components/logo.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/board_view.dart';
import 'package:smooflow/screens/desktop/components/detail_panel.dart';
import 'package:smooflow/screens/desktop/components/project_modal.dart';
import 'package:smooflow/screens/desktop/components/task_list_view.dart';
import 'package:smooflow/screens/desktop/components/task_modal.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

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

  final FocusNode _addTaskFocusNode = FocusNode();

  // Read from Riverpod — never mutate directly
  List<Project> get _projects => ref.watch(projectNotifierProvider);
  List<Task> get _tasks => ref.watch(taskNotifierProvider).tasks.where((t) =>
      t.status == TaskStatus.pending ||
      t.status == TaskStatus.designing ||
      t.status == TaskStatus.waitingApproval ||
      t.status == TaskStatus.clientApproved).toList();

  String? _selectedProjectId;
  int?    _selectedTaskId;
  TaskFilter _filter   = TaskFilter.all;
  ViewMode   _viewMode = ViewMode.board;
  String     _searchQuery = '';

  bool _isAddingTask = false;

  final _searchCtrl = TextEditingController();

  String? get _selectedProjectName {
    try {
      return _selectedProjectId != null? ref.watch(projectNotifierProvider).firstWhere((p)=> p.id == _selectedProjectId).name : null;
    } catch(e) {
      return "Loading Project";
    }
  }

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

    setState(() {});
  }

  /// Add a new project through the Riverpod notifier.
  Future<void> _addProject(Project p) async {
    await ref.read(projectNotifierProvider.notifier).create(p);
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
                                ?  _visibleTasks.isEmpty
                                  ? ProjectEmptyState(
                                      onCreateTask: () {},
                                      onClearFilters: () {},
                                      onProjectSelected: (p) {},
                                      projectName: _selectedProjectName,
                                      otherProjects: _projects,
                                      // _visibleTasks.isEmpty && _projects.isNotEmpty
                                      hasActiveFilters: false,
                                    )
                                    : BoardView(
                                      tasks: _visibleTasks,
                                      projects: _projects,
                                      selectedTaskId: _selectedTaskId,
                                      onTaskSelected: _selectTask,
                                      onAddTask: _showTaskModal,
                                      addTaskFocusNode: _addTaskFocusNode,
                                      isAddingTask: _isAddingTask,
                                      selectedProjectId: _selectedProjectId
                                    )
                                : TaskListView(
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

  // ── Modal launchers ────────────────────────────────────────────────────────

  void _showProjectModal() {
    showDialog(
      context: context,
      builder: (_) => ProjectModal(onSave: _addProject),
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
                Logo(size: 25),
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
                  label: 'List',
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
                      AvatarWidget(initials: m.initials, color: m.color, size: 26),
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
          // Container(
          //   padding: const EdgeInsets.all(2),
          //   decoration: BoxDecoration(color: _T.slate100, borderRadius: BorderRadius.circular(_T.r)),
          //   child: Row(
          //     children: [
          //       _ViewToggleBtn(icon: Icons.view_kanban_outlined, label: 'Board', isActive: viewMode == ViewMode.board, onTap: () => onViewModeChanged(ViewMode.board)),
          //       _ViewToggleBtn(icon: Icons.list_alt_outlined,    label: 'List',  isActive: viewMode == ViewMode.list,  onTap: () => onViewModeChanged(ViewMode.list)),
          //     ],
          //   ),
          // ),
          // const SizedBox(width: 12),

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
          // GestureDetector(
          //   onTap: onNewTask,
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: _T.blue,
          //       borderRadius: BorderRadius.circular(_T.r),
          //       boxShadow: [BoxShadow(color: _T.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
          //     ),
          //     child: const Row(
          //       children: [
          //         Icon(Icons.add, size: 14, color: Colors.white),
          //         SizedBox(width: 6),
          //         Text('New Task', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          //       ],
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 12),

          // User chip
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            decoration: BoxDecoration(border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(99)),
            child: Row(
              children: [
                AvatarWidget(initials: _currentUser.initials, color: _T.blue, size: 24),
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
// HOW TO INTEGRATE INTO _KanbanLane
// ─────────────────────────────────────────────────────────────────────────────
//
// In your _KanbanLane's Column > Expanded > ListView, keep track of whether
// the creation card is open in the parent board or lane:
//
//   bool _addingTask = false;
//
//   // At the end of the cards list, before the add button:
//   if (_addingTask)
//     _TaskCard.add(
//       projects: widget.projects,
//       onCreated: (task) {
//         widget.onTaskCreated(task);     // call your Riverpod notifier
//         setState(() => _addingTask = false);
//       },
//       onDismiss: () => setState(() => _addingTask = false),
//     ),
//
//   // Replace the old _AddCardButton with:
//   if (!_addingTask)
//     _AddCardButton(onTap: () => setState(() => _addingTask = true)),
//
// The creation card will auto-focus, animate in, and close cleanly on
// submit (Enter) or dismiss (Escape / ✕ button).

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
// class _AvatarWidget extends StatelessWidget {
//   final String initials;
//   final Color color;
//   final double size;
//   const _AvatarWidget({required this.initials, required this.color, required this.size});

//   @override
//   Widget build(BuildContext context) => Container(
//     width: size, height: size,
//     decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
//     child: Center(child: Text(initials, style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w700, color: color))),
//   );
// }

// class _PriorityPill extends StatelessWidget {
//   final TaskPriority priority;
//   const _PriorityPill({required this.priority});

//   @override
//   Widget build(BuildContext context) {
//     final (text, color, bg) = switch (priority) {
//       TaskPriority.urgent => ('Urgent', _T.red,    _T.red50),
//       TaskPriority.high   => ('High',   _T.amber,  _T.amber50),
//       TaskPriority.normal => ('Normal', _T.slate500, _T.slate100),
//     };
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//       decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
//       child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
//     );
//   }
// }

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
