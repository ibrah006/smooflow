// ─────────────────────────────────────────────────────────────────────────────
// ADMIN ANALYTICS DASHBOARD — updated
//
// Changes from previous version:
//   • Board and List nav items removed from sidebar — view switching now lives
//     inside TaskListView's own header bar.
//   • _AdminView enum no longer has .board — just .overview / .list / .clients
//     / .team.
//   • selectedProjectId is passed down to TaskListView so it can hide the
//     project column and display the correct header label.
//   • onAddTask / addTaskFocusNode / isAddingTask forwarded to TaskListView
//     so the embedded BoardView can still create tasks.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/components/logo.dart';
import 'package:smooflow/components/user_menu_chip.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/api/api_logger.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/create_task_args.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/macos_update.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/message_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/accounts_management_screen.dart';
import 'package:smooflow/screens/desktop/clients_page.dart';
import 'package:smooflow/screens/desktop/components/dashboard_skeleton.dart';
import 'package:smooflow/screens/desktop/components/detail_panel.dart';
import 'package:smooflow/screens/desktop/components/notification_toast.dart';
import 'package:smooflow/screens/desktop/components/project_modal.dart';
import 'package:smooflow/screens/desktop/components/task_list_view.dart';
import 'package:smooflow/screens/desktop/components/task_modal.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';
import 'package:smooflow/screens/desktop/desktop_materials_management_screen.dart';
import 'package:smooflow/screens/desktop/desktop_printer_management_screen.dart';
import 'package:smooflow/screens/desktop/desktop_reports_screen.dart';
import 'package:smooflow/screens/desktop/home_view.dart';
import 'package:smooflow/screens/desktop/inbox_view.dart';
import 'package:smooflow/screens/desktop/manage_members_page.dart';
import 'package:smooflow/screens/desktop/desktop_projects_screen.dart';
import 'package:smooflow/screens/desktop/settings_page.dart';
import 'package:smooflow/screens/printers_management_screen.dart';

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
  static const topbarH = 60.0;
  static const detailW = 400.0;

  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

const String _pinnedProjectsKey = 'pinned_project_ids';

// ─────────────────────────────────────────────────────────────────────────────
// Stage metadata
// ─────────────────────────────────────────────────────────────────────────────
DesignStageInfo _stageInfo(TaskStatus s) =>
    kStages.firstWhere((i) => i.stage == s, orElse: () => kStages.first);

// ─────────────────────────────────────────────────────────────────────────────
// VIEW ENUM — board removed; view switching lives inside TaskListView
// ─────────────────────────────────────────────────────────────────────────────
enum _AdminView {
  overview,
  inbox,
  list,
  clients,
  team,
  printers,
  inventory,
  reports,
  accounts,
  settings,
  projects,
}

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
    extends ConsumerState<AdminDesktopDashboardScreen>
    with SingleTickerProviderStateMixin {
  _AdminView _view = _AdminView.overview;
  String? _selectedProjectId;
  int? _selectedTaskId;
  String _searchQuery = '';

  late final AnimationController _mountCtrl;

  final FocusNode _addTaskFocusNode = FocusNode();
  bool _isAddingTask = false;
  bool _isInitLoading = true;

  List<String> _pinnedProjectIds = [];

  void _selectTask(int id) async {
    // if (id == _selectedTaskId) return; // already selected
    setState(() => _selectedTaskId = id);
  }

  void _closeDetail() => setState(() => _selectedTaskId = null);

  Task? get _selectedTask =>
      _selectedTaskId == null
          ? null
          : _tasks.cast<Task?>().firstWhere(
            (t) => t!.id == _selectedTaskId,
            orElse: () => null,
          );

  Future<void> _advanceTask(Task advancedTask) async {
    // final next = advancedTask.status;
    // _showSnack(
    //   context,
    //   next == TaskStatus.clientApproved
    //       ? '✓ Task marked as Client Approved — handed off to production'
    //       : 'Task moved to "${stageInfo(next).label}"',
    //   next == TaskStatus.clientApproved ? _T.green : _T.blue,
    // );
    setState(() {});
  }

  List<Task> get _pipelineTasks => ref.watch(taskNotifierProvider).tasks;

  List<Project> get _projects => ref.watch(projectNotifierProvider);
  List<Member> get _members => ref.watch(memberNotifierProvider).members;
  List<Task> get _tasks => ref.watch(taskNotifierProvider).tasks;

  // List<Task> get _visibleTasks => _tasks.where((t) {
  //   if (_selectedProjectId != null && t.projectId != _selectedProjectId) return false;
  //   final q = _searchQuery.toLowerCase().trim();
  //   if (q.isNotEmpty) {
  //     return t.name.toLowerCase().contains(q) ||
  //         (t.description ?? '').toLowerCase().contains(q);
  //   }
  //   return true;
  // }).toList();

  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    AppToast.init(kNavigatorKey);

    _mountCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    Future.microtask(() async {
      // Load in message notifier provider and task notifier provider so that even, not being in task list view, our state is up to date
      ref.read(messageNotifierProvider.notifier);
      ref.read(taskNotifierProvider.notifier);

      try {
        await Future.wait([
          (() async {
            try {
              await ref
                  .read(projectNotifierProvider.notifier)
                  .load(projectsLastAddedLocal: null);
            } catch (e, s) {
              await AppLogger.logError(
                message: "Failed to load projects",
                error: e,
                stackTrace: s,
              );
            }
          })(),

          // (() async {
          //   try {
          //     await ref.read(taskNotifierProvider.notifier).loadAll();
          //   } catch (e, s) {
          //     await AppLogger.logError(
          //       message: "Failed to load tasks",
          //       error: e,
          //       stackTrace: s,
          //     );
          //   }
          // })(),
          (() async {
            try {
              await ref.read(memberNotifierProvider.notifier).members;
            } catch (e, s) {
              await AppLogger.logError(
                message: "Failed to load members",
                error: e,
                stackTrace: s,
              );
            }
          })(),
        ]);

        Future.wait([
          (() async {
            try {
              await ref
                  .read(materialNotifierProvider.notifier)
                  .fetchMaterials();
            } catch (e, s) {
              await AppLogger.logError(
                message: "Failed to fetch materials",
                error: e,
                stackTrace: s,
              );
            }
          })(),

          (() async {
            try {
              await ref
                  .read(materialNotifierProvider.notifier)
                  .fetchTransactions();
            } catch (e, s) {
              await AppLogger.logError(
                message: "Failed to fetch transactions",
                error: e,
                stackTrace: s,
              );
            }
          })(),
        ]);

        if (mounted) setState(() => _isInitLoading = false);
      } catch (e, s) {
        await AppLogger.logError(
          message: "Unexpected init failure",
          error: e,
          stackTrace: s,
        );
      }
    });

    checkForUpdate(context);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _selectedTaskId != null) {
      _closeDetail();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Returns a staggered fade+slide animation for a given slot (0-based).
  Animation<double> _fade(int slot) => CurvedAnimation(
    parent: _mountCtrl,
    curve: Interval(slot * 0.08, (slot * 0.08) + 0.55, curve: Curves.easeOut),
  );

  Future<void> _togglePinProject(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedPins = List<String>.from(_pinnedProjectIds);

      if (updatedPins.contains(projectId)) {
        updatedPins.remove(projectId);
        _showSnack('Project removed from pins', _T.slate400);
      } else {
        updatedPins.add(projectId);
        _showSnack('Project pinned to sidebar', _T.green);
      }

      await prefs.setStringList(_pinnedProjectsKey, updatedPins);
      if (mounted) {
        setState(() {
          _pinnedProjectIds = updatedPins;
        });
      }
    } catch (e, s) {
      await AppLogger.logError(
        message: "Failed to update pinned projects state in shared preferences",
        error: e,
        stackTrace: s,
      );
      _showSnack('Error saving pin configurations', _T.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _T.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, right: 24, left: 200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.rLg),
        ),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Not very performance efficient
    ref.listen<AsyncValue<TaskChangeEvent>>(taskChangesStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((event) {
        // TODO: RIELIABALLY FIX THIS IN THE NEXT PATCH RELEASE
        Future.delayed(Duration(seconds: 5)).then((value) {
          if (mounted) setState(() {});
        });
      });
    });

    ;
    return GestureDetector(
      onTap: () {
        _addTaskFocusNode.unfocus();
        setState(() => _isAddingTask = false);
      },
      child: Scaffold(
        body: Focus(
          autofocus: true,
          onKeyEvent: _handleKey,
          child: Row(
            children: [
              // ── Sidebar ─────────────────────────────────────────────
              _AdminSidebar(
                currentView: _view,
                selectedProjectId: _selectedProjectId,
                projects: _projects,
                tasks: _pipelineTasks,
                members: _members,
                isLoading: _isInitLoading,
                isCollapsed: _isSidebarCollapsed,
                togglePinProject: _togglePinProject,
                onToggleCollapse:
                    () => setState(
                      () => _isSidebarCollapsed = !_isSidebarCollapsed,
                    ),
                pinnedProjectIds: _pinnedProjectIds,
                onViewChanged: (v) {
                  setState(() {
                    _view = v;
                  });
                  _closeDetail();
                },
                onLoadProjects: (value) {
                  setState(() {
                    _pinnedProjectIds = value;
                  });
                },
                onProjectSelected:
                    (id) => setState(() {
                      _selectedProjectId = id;
                      // Switch to list view when a project is selected so the
                      // user immediately sees filtered results.
                      if (_view == _AdminView.overview) _view = _AdminView.list;
                    }),
              ),

              // ── Main content ────────────────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fade(0),
                      child: _AdminTopbar(
                        currentView: _view,
                        selectedProjectId: _selectedProjectId,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeInOutCubic,
                              switchOutCurve: Curves.easeInOutCubic,
                              transitionBuilder: (
                                Widget child,
                                Animation<double> animation,
                              ) {
                                // Combines a clean cross-fade with a tiny, professional forward slide
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(
                                        0.01,
                                        0.0,
                                      ), // Subtle horizontal slide-in
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey<_AdminView>(
                                  _view,
                                ), // Required so switcher knows when the view enum shifts
                                child:
                                    _view == _AdminView.overview
                                        ? (_isInitLoading
                                            ? const OverviewSkeleton()
                                            : HomeView())
                                        : _view == _AdminView.inbox
                                        ? InboxView()
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
                                        ? DesktopMaterialsManagementScreen(
                                          onNavigateToReports: () {
                                            setState(() {
                                              _view = _AdminView.reports;
                                            });
                                            _closeDetail();
                                          },
                                        )
                                        : _view == _AdminView.reports
                                        ? DesktopReportsScreen()
                                        : _view == _AdminView.accounts
                                        ? AccountsManagementScreen()
                                        : _view == _AdminView.projects
                                        ? DesktopProjectsScreen(
                                          initialProjects: _projects,
                                          onProjectSelected: (id) {
                                            // Trigger state alterations sequentially
                                            setState(() {
                                              _selectedProjectId = id;
                                              _view = _AdminView.list;
                                            });
                                          },
                                          onTogglePinProject: _togglePinProject,
                                        )
                                        : SettingsPage(),
                              ),
                            ),
                          ),

                          // ── Detail panel ──────────────────────────
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            width: _selectedTaskId != null ? _T.detailW : 0,
                            child:
                                _selectedTaskId != null
                                    ? DetailPanel(
                                      key: ValueKey(_selectedTaskId),
                                      task: _selectedTask!,
                                      onClose: _closeDetail,
                                      onAdvance:
                                          () => _advanceTask(_selectedTask!),
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

  void _showTaskModal() {
    final nextId =
        (_tasks.isEmpty
            ? 0
            : _tasks.map((t) => t.id).reduce((a, b) => a > b ? a : b)) +
        1;
    showDialog(
      context: context,
      builder:
          (_) => TaskModal(
            projects: _projects,
            preselectedProjectId: _selectedProjectId,
            nextId: nextId,
          ),
    );
    setState(() {});
  }
}

class _AdminSidebar extends ConsumerStatefulWidget {
  final _AdminView currentView;
  final String? selectedProjectId;
  final List<Project> projects;
  final List<Task> tasks;
  final List<Member> members;
  final ValueChanged<_AdminView> onViewChanged;
  final ValueChanged<String?> onProjectSelected;
  final bool isLoading;
  final ValueChanged<String> togglePinProject;
  final List<String> pinnedProjectIds;
  final ValueChanged<List<String>> onLoadProjects;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const _AdminSidebar({
    required this.currentView,
    required this.selectedProjectId,
    required this.projects,
    required this.tasks,
    required this.members,
    required this.onViewChanged,
    required this.onProjectSelected,
    required this.isLoading,
    required this.togglePinProject,
    required this.pinnedProjectIds,
    required this.onLoadProjects,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  ConsumerState<_AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends ConsumerState<_AdminSidebar> {
  bool _loadingPins = true;

  @override
  void initState() {
    super.initState();
    _loadPinnedProjects();
  }

  Future<void> _loadPinnedProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedPins = prefs.getStringList(_pinnedProjectsKey);
      widget.onLoadProjects(savedPins ?? []);
      _loadingPins = false;
    } catch (e, s) {
      await AppLogger.logError(
        message: "Failed to load pinned projects from shared preferences",
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        setState(() => _loadingPins = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinnedProjectsList =
        widget.projects
            .where((p) => widget.pinnedProjectIds.contains(p.id))
            .toList();

    // Compute dynamic width parameters explicitly
    final double targetWidth = widget.isCollapsed ? 64.0 : _T.sidebarW;
    final horizontalPadding = widget.isCollapsed ? 8.0 : 10.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: targetWidth,
      color: _T.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo & Collapse Action Trigger ─────────────────────────────
          Container(
            height: _T.topbarH,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x10FFFFFF))),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 12 : 16,
            ),
            child: Row(
              mainAxisAlignment:
                  widget.isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
              children: [
                if (!widget.isCollapsed) ...[
                  Logo(size: 25),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'smooflow',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                // Premium Toggle Button
                IconButton(
                  onPressed: widget.onToggleCollapse,
                  splashRadius: 16,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    widget.isCollapsed
                        ? Icons.menu_open_rounded
                        : Icons.menu_rounded,
                    size: 18,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          // ── Primary Workspace Navigation Block ─────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              15,
              horizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarLabel('Workspace', isHidden: widget.isCollapsed),
                const SizedBox(height: 3),
                _SidebarNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Overview',
                  isCollapsed: widget.isCollapsed,
                  isActive: widget.currentView == _AdminView.overview,
                  onTap: () => widget.onViewChanged(_AdminView.overview),
                ),
                if (kDebugMode)
                  _SidebarNavItem(
                    icon: Icons.notifications_outlined,
                    label: 'Inbox',
                    isCollapsed: widget.isCollapsed,
                    isActive: widget.currentView == _AdminView.inbox,
                    onTap: () => widget.onViewChanged(_AdminView.inbox),
                  ),

                widget.isLoading
                    ? _SidebarItemRowSkeleton(isCollapsed: widget.isCollapsed)
                    : _SidebarNavItem(
                      icon: Icons.assignment_outlined,
                      label: 'All Tasks',
                      isCollapsed: widget.isCollapsed,
                      isActive:
                          widget.currentView == _AdminView.list &&
                          widget.selectedProjectId == null,
                      badgeWidget:
                          widget.tasks.isNotEmpty
                              ? Text(widget.tasks.length.toString())
                              : null,
                      onTap: () {
                        widget.onProjectSelected(null);
                        widget.onViewChanged(_AdminView.list);
                      },
                    ),

                widget.isLoading
                    ? _SidebarItemRowSkeleton(isCollapsed: widget.isCollapsed)
                    : _SidebarNavItem(
                      icon: Icons.folder_open_rounded,
                      label: 'Projects',
                      isCollapsed: widget.isCollapsed,
                      isActive: widget.currentView == _AdminView.projects,
                      badgeWidget:
                          widget.projects.isNotEmpty
                              ? Text(widget.projects.length.toString())
                              : null,
                      onTap: () {
                        widget.onProjectSelected(null);
                        widget.onViewChanged(_AdminView.projects);
                      },
                    ),
              ],
            ),
          ),

          // ── Pinned Projects Core Panel ─────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SidebarLabel(
                      'Pinned Projects',
                      isHidden: widget.isCollapsed,
                    ),
                    if (pinnedProjectsList.isNotEmpty && !widget.isCollapsed)
                      PopupMenuButton<Project>(
                        tooltip: 'Pin another project',
                        icon: Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                          maxWidth: 220,
                        ),
                        offset: const Offset(0, 12),
                        color: _T.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_T.r),
                        ),
                        onSelected: (p) => widget.togglePinProject(p.id),
                        itemBuilder: (ctx) {
                          final unpinned =
                              widget.projects
                                  .where(
                                    (p) =>
                                        !widget.pinnedProjectIds.contains(p.id),
                                  )
                                  .toList();
                          if (unpinned.isEmpty) {
                            return [
                              const PopupMenuItem(
                                enabled: false,
                                child: Text(
                                  'All projects pinned',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _T.slate400,
                                  ),
                                ),
                              ),
                            ];
                          }
                          return unpinned
                              .map(
                                (p) => PopupMenuItem<Project>(
                                  value: p,
                                  height: 34,
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _T.ink3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList();
                        },
                      ),
                  ],
                ),
                if (widget.isCollapsed)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        width: 12,
                        height: 1,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child:
                  widget.isLoading || _loadingPins
                      ? (widget.isCollapsed
                          ? const SizedBox.shrink()
                          : const SidebarProjectsSkeleton())
                      : pinnedProjectsList.isEmpty
                      ? (widget.isCollapsed
                          ? const SizedBox.shrink()
                          : Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: _DottedPinButton(
                                allProjects: widget.projects,
                                pinnedIds: widget.pinnedProjectIds,
                                onProjectSelectedToPin: widget.togglePinProject,
                                onNavigateToProjects: () {
                                  widget.onProjectSelected(null);
                                  widget.onViewChanged(_AdminView.projects);
                                },
                              ),
                            ),
                          ))
                      : ListView(
                        padding: EdgeInsets.zero,
                        children:
                            pinnedProjectsList.map((p) {
                              final cnt =
                                  widget.tasks
                                      .where((t) => t.projectId == p.id)
                                      .length;
                              final isActive =
                                  widget.selectedProjectId == p.id &&
                                  widget.currentView == _AdminView.list;

                              if (widget.isCollapsed) {
                                // Compact micro-dot indicator row mapping targets safely
                                if (widget.isCollapsed) {
                                  // Compact micro-dot indicator row mapping targets safely
                                  return Tooltip(
                                    message: p.name,
                                    preferBelow: false,
                                    verticalOffset: 0,
                                    margin: const EdgeInsets.only(left: 48),
                                    child: _SidebarNavItem(
                                      icon: Icons.lens,
                                      label: '',
                                      isCollapsed: true,
                                      isActive: isActive,
                                      customIconColor: p.color,
                                      onTap: () {
                                        widget.onProjectSelected(p.id);
                                        widget.onViewChanged(_AdminView.list);
                                      },
                                    ),
                                  );
                                }
                              }

                              return _SidebarProjectRow(
                                name: p.name,
                                color: p.color,
                                count: cnt,
                                isActive: isActive,
                                onTap: () {
                                  widget.onProjectSelected(p.id);
                                  widget.onViewChanged(_AdminView.list);
                                },
                              );
                            }).toList(),
                      ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Operations Navigation Block ────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              5,
              horizontalPadding,
              4,
            ),
            child: _SidebarLabel('Operations', isHidden: widget.isCollapsed),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                _SidebarNavItem(
                  icon: Icons.print_rounded,
                  label: 'Printers',
                  isCollapsed: widget.isCollapsed,
                  isActive: widget.currentView == _AdminView.printers,
                  onTap: () => widget.onViewChanged(_AdminView.printers),
                ),
                _SidebarNavItem(
                  icon: CupertinoIcons.cube_box,
                  label: 'Materials',
                  isCollapsed: widget.isCollapsed,
                  isActive:
                      widget.currentView == _AdminView.inventory ||
                      widget.currentView == _AdminView.reports,
                  onTap: () => widget.onViewChanged(_AdminView.inventory),
                ),
                _SidebarNavItem(
                  icon: Icons.account_balance,
                  label: 'Accounts',
                  showBeta: !widget.isCollapsed,
                  isCollapsed: widget.isCollapsed,
                  isActive: widget.currentView == _AdminView.accounts,
                  onTap: () => widget.onViewChanged(_AdminView.accounts),
                ),
              ],
            ),
          ),

          // ── Management Navigation Block ────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              0,
            ),
            child: _SidebarLabel('Manage', isHidden: widget.isCollapsed),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                _SidebarNavItem(
                  icon: Icons.supervisor_account_sharp,
                  label: 'Clients',
                  isCollapsed: widget.isCollapsed,
                  isActive: widget.currentView == _AdminView.clients,
                  onTap: () => widget.onViewChanged(_AdminView.clients),
                ),
                _SidebarNavItem(
                  icon: Icons.people_outline_rounded,
                  label: 'Manage Team',
                  isCollapsed: widget.isCollapsed,
                  isActive: widget.currentView == _AdminView.team,
                  onTap: () => widget.onViewChanged(_AdminView.team),
                ),
                _SidebarNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isCollapsed: widget.isCollapsed,
                  isActive: widget.currentView == _AdminView.settings,
                  onTap: () => widget.onViewChanged(_AdminView.settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _DottedPinButton extends StatefulWidget {
  final List<Project> allProjects;
  final List<String> pinnedIds;
  final ValueChanged<String> onProjectSelectedToPin;
  final VoidCallback onNavigateToProjects;

  const _DottedPinButton({
    required this.allProjects,
    required this.pinnedIds,
    required this.onProjectSelectedToPin,
    required this.onNavigateToProjects,
  });

  @override
  State<_DottedPinButton> createState() => _DottedPinButtonState();
}

class _DottedPinButtonState extends State<_DottedPinButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final unpinnedProjects =
        widget.allProjects
            .where((p) => !widget.pinnedIds.contains(p.id))
            .toList();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PopupMenuButton<String>(
        tooltip: 'Quick pin dropdown menu',
        offset: const Offset(0, 42),
        constraints: const BoxConstraints(maxHeight: 280, maxWidth: 230),
        color: _T.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.r),
          side: const BorderSide(color: _T.slate200),
        ),
        onSelected: (value) {
          if (value == '_view_all_') {
            widget.onNavigateToProjects();
          } else {
            widget.onProjectSelectedToPin(value);
          }
        },
        itemBuilder: (ctx) {
          if (unpinnedProjects.isEmpty) {
            return [
              const PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  'No other projects to pin',
                  style: TextStyle(fontSize: 12, color: _T.slate400),
                ),
              ),
            ];
          }

          final List<PopupMenuEntry<String>> items = [];
          items.add(
            const PopupMenuItem<String>(
              enabled: false,
              height: 26,
              child: Text(
                'SELECT A PROJECT TO PIN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _T.slate400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );

          items.addAll(
            unpinnedProjects.map(
              (p) => PopupMenuItem<String>(
                value: p.id,
                height: 36,
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _T.ink3,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          items.add(const PopupMenuDivider(height: 1));
          items.add(
            const PopupMenuItem<String>(
              value: '_view_all_',
              height: 36,
              child: Row(
                children: [
                  Icon(Icons.fullscreen_rounded, size: 15, color: _T.blue),
                  SizedBox(width: 8),
                  Text(
                    'Open Projects Page...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _T.blue,
                    ),
                  ),
                ],
              ),
            ),
          );

          return items;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          height: 38,
          decoration: BoxDecoration(
            color:
                _hovered ? Colors.white.withOpacity(0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: CustomPaint(
            painter: _DottedBorderPainter(
              color: Colors.white.withOpacity(_hovered ? 0.3 : 0.15),
              radius: _T.r,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.push_pin_outlined,
                  size: 13,
                  color: Colors.white.withOpacity(_hovered ? 0.6 : 0.4),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pin a Project',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(_hovered ? 0.6 : 0.4),
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

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DottedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);

    // Manual dash processing calculations for precise rendering across desktop frames
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;

    final Path dashPath = Path();
    double distance = 0.0;

    for (final PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DottedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR — Redesigned
//
// Design language: matches the board view and filter bar system.
//   • slate100 bottom border (lighter, less heavy than slate200)
//   • Greeting: name in ink2, date in a ghost slate100 chip
//   • Section views: muted category prefix + "/" + bold section name
//   • Create Task: custom tight button — blue fill, no Material artifacts
//   • UserMenuChip: untouched, right-anchored
// ─────────────────────────────────────────────────────────────────────────────

class _AdminTopbar extends ConsumerStatefulWidget {
  final _AdminView currentView;
  final String? selectedProjectId;
  const _AdminTopbar({required this.currentView, this.selectedProjectId});

  @override
  ConsumerState<_AdminTopbar> createState() => _AdminTopbarState();
}

class _AdminTopbarState extends ConsumerState<_AdminTopbar> {
  // ── Section metadata ───────────────────────────────────────────────────────
  ({String category, String label}) _sectionMeta() => switch (widget
      .currentView) {
    _AdminView.inbox => (category: 'Workspace', label: 'Inbox'),
    _AdminView.list => (category: 'Workspace', label: 'Tasks'),
    _AdminView.reports => (
      category: 'Workspace  /  Materials',
      label: 'Reports',
    ),
    _AdminView.printers => (category: 'Operations', label: 'Printers'),
    _AdminView.inventory => (category: 'Operations', label: 'Inventory'),
    _AdminView.overview => (category: '', label: ''),
    _AdminView.accounts => (category: 'Operations', label: 'Accounts'),
    _ => (category: 'Management', label: widget.currentView.name.capitalize()),
  };

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

  Future<void> _showSnack(String msg, Color color) async {
    kRootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _T.ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, right: 24, left: 200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_T.rLg),
        ),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting =
        hour < 12
            ? 'Good morning'
            : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final user = LoginService.currentUser;

    return Container(
      height: _T.topbarH,
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: greeting or section breadcrumb ───────────────────────────
          if (widget.currentView == _AdminView.overview)
            _GreetingSection(greeting: greeting, user: user, now: now)
          else
            _BreadcrumbSection(meta: _sectionMeta()),

          const Spacer(),

          // ── Right: create + user ───────────────────────────────────────────
          _OutlinedSecondaryButton(
            label: "New Project",
            icon: Icons.folder_open_rounded,
            onTap: _showProjectModal,
          ),
          const SizedBox(width: 8),

          // Explicit primary callout
          _PrimaryButton(
            label: "New Task",
            icon: Icons.add_rounded,
            onTap:
                () => AppRoutes.navigateTo(
                  context,
                  AppRoutes.designCreateTaskScreen,
                  arguments: CreateTaskArgs(
                    preselectedProjectId: widget.selectedProjectId,
                  ),
                ),
          ),
          const SizedBox(width: 12),
          if (user != null)
            UserMenuChip(
              onLogout: () async {
                await LoginService.logout();
                if (context.mounted) {
                  AppRoutes.navigateAndRemoveUntil(context, AppRoutes.login);
                }
              },
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GREETING SECTION
//
// Layout:
//   Good morning, Alex  ·  [Wed, 18 Mar 2026]
//
// The date sits in a ghost chip (slate100 bg, slate200 border) so it reads
// as metadata rather than competing with the greeting text.
// ─────────────────────────────────────────────────────────────────────────────
class _GreetingSection extends StatelessWidget {
  final String greeting;
  final dynamic user; // LoginService.currentUser type
  final DateTime now;

  const _GreetingSection({
    required this.greeting,
    required this.user,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateString =
        '${dayNames[now.weekday - 1]}, ${monthNames[now.month - 1]} ${now.day}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Greeting
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  color: _T.ink,
                  height: 1.2,
                ),
                children: [
                  TextSpan(
                    text: '$greeting, ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _T.slate500,
                    ),
                  ),
                  TextSpan(
                    text: '${LoginService.currentUser!.name}.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _T.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(width: 16),

        // Date pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _T.slate100,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 11,
                color: _T.slate400,
              ),
              const SizedBox(width: 5),
              Text(
                dateString,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _T.slate500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BREADCRUMB SECTION
//
// Layout:
//   Workspace  /  Tasks
//
// Category: slate400, w400 — recedes
// Slash:    slate300
// Label:    ink2, w600 — foreground
// ─────────────────────────────────────────────────────────────────────────────
class _BreadcrumbSection extends StatelessWidget {
  final ({String category, String label}) meta;
  const _BreadcrumbSection({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (meta.category.isNotEmpty) ...[
          Text(
            meta.category,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _T.slate400,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '/',
              style: TextStyle(fontSize: 13, color: _T.slate300),
            ),
          ),
        ],

        Text(
          meta.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _T.ink2,
          ),
        ),
      ],
    );
  }
}

/// Primary CTA button (matches inbox "View Full Task" style).
class _PrimaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? _T.blueHover : _T.blue,
            borderRadius: BorderRadius.circular(_T.r),
            boxShadow: [
              BoxShadow(
                color: _T.blue.withOpacity(_hovered ? 0.35 : 0.2),
                blurRadius: _hovered ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYTICS VIEW — unchanged from previous version
// ─────────────────────────────────────────────────────────────────────────────
class _AdminAnalyticsView extends StatefulWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final List<Member> members;

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

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
    parent: _ac,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks;
    final projects = widget.projects;
    final members = widget.members;

    final totalActive =
        tasks
            .where(
              (t) =>
                  !(t.status == TaskStatus.completed ||
                      t.status == TaskStatus.blocked),
            )
            .length;

    final inReview =
        tasks.where((t) => t.status == TaskStatus.waitingApproval).length;

    final overdue =
        tasks
            .where(
              (t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now()),
            )
            .length;

    final approvedToday =
        tasks
            .where(
              (t) =>
                  t.status == TaskStatus.clientApproved &&
                  t.dueDate != null &&
                  _sameDay(t.dueDate!, DateTime.now()),
            )
            .length;

    final printQueue =
        tasks.where((t) => t.status == TaskStatus.printing).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: _stagger(0.0, 0.4),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(_stagger(0.0, 0.4)),
              child: Row(
                children: [
                  _KpiCard(
                    label: 'Active Tasks',
                    value: '$totalActive',
                    delta:
                        totalActive > 0
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _stagger(0.15, 0.55),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(_stagger(0.15, 0.55)),
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
          FadeTransition(
            opacity: _stagger(0.3, 0.7),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(_stagger(0.3, 0.7)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _AnalyticsCard(
                      title: 'Team Workload',
                      subtitle: 'Active tasks per designer',
                      child: _TeamWorkloadChart(members: members, tasks: tasks),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: _AnalyticsCard(
                      title: 'Project Health',
                      subtitle: 'Stage breakdown & overdue risk per project',
                      child: _ProjectHealthGrid(
                        projects: projects,
                        tasks: tasks,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (overdue > 0)
            FadeTransition(
              opacity: _stagger(0.45, 0.85),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(_stagger(0.45, 0.85)),
                child: _AnalyticsCard(
                  title: 'Overdue Tasks',
                  subtitle: 'Past due date — needs action',
                  child: _OverdueTasksList(
                    tasks: tasks,
                    projects: projects,
                    members: members,
                  ),
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
    final deltaColor =
        deltaPositive == null
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
                child: const Icon(
                  Icons.more_horiz,
                  size: 13,
                  color: _T.slate400,
                ),
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
// ─────────────────────────────────────────────────────────────────────────────
class _StageFunnelChart extends StatelessWidget {
  final List<Task> tasks;
  const _StageFunnelChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final counts =
        kStages
            .map((s) => tasks.where((t) => t.status == s.stage).length)
            .toList();
    final total = counts.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No tasks in pipeline',
            style: TextStyle(fontSize: 12, color: _T.slate400),
          ),
        ),
      );
    }

    return Column(
      children:
          kStages.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final count = counts[i];
            final pct = count / total;

            return count < 1
                ? const SizedBox()
                : Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          s.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _T.ink3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
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
                                  child:
                                      count > 0
                                          ? Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
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
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
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
// TEAM WORKLOAD CHART
// ─────────────────────────────────────────────────────────────────────────────
class _TeamWorkloadChart extends StatelessWidget {
  final List<Member> members;
  final List<Task> tasks;
  const _TeamWorkloadChart({required this.members, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No team members',
            style: TextStyle(fontSize: 12, color: _T.slate400),
          ),
        ),
      );
    }

    const capacity = 8;

    return Column(
      children:
          members.map((m) {
            final active =
                tasks
                    .where(
                      (t) =>
                          t.assignees.contains(m.id) &&
                          t.status != TaskStatus.clientApproved &&
                          t.status != TaskStatus.printing,
                    )
                    .length;
            final overdueCount =
                tasks
                    .where(
                      (t) =>
                          t.assignees.contains(m.id) &&
                          t.dueDate != null &&
                          t.dueDate!.isBefore(DateTime.now()),
                    )
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
                            if (overdueCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: _T.red50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$overdueCount overdue',
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
                        LayoutBuilder(
                          builder: (context, constraints) {
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
                          },
                        ),
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
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectHealthGrid extends StatelessWidget {
  final List<Project> projects;
  final List<Task> tasks;
  const _ProjectHealthGrid({required this.projects, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final projectsWithTasks =
        projects.where((p) => tasks.any((t) => t.projectId == p.id)).toList();

    if (projectsWithTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No active projects',
            style: TextStyle(fontSize: 12, color: _T.slate400),
          ),
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(flex: 3, child: _ColHeader('Project')),
              Expanded(flex: 4, child: _ColHeader('Stage breakdown')),
              Expanded(flex: 1, child: _ColHeader('Total')),
              Expanded(flex: 1, child: _ColHeader('⚠︎')),
            ],
          ),
        ),
        ...projectsWithTasks.map((p) {
          final ptasks = tasks.where((t) => t.projectId == p.id).toList();
          final total = ptasks.length;
          final overdueCount =
              ptasks
                  .where(
                    (t) =>
                        t.dueDate != null &&
                        t.dueDate!.isBefore(DateTime.now()),
                  )
                  .length;
          final stageCounts =
              kStages
                  .map((s) => ptasks.where((t) => t.status == s.stage).length)
                  .toList();
          final stageColors = kStages.map((s) => s.color).toList();

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
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Row(
                        children: List.generate(5, (i) {
                          if (stageCounts[i] == 0)
                            return const SizedBox.shrink();
                          return Flexible(
                            flex: stageCounts[i],
                            child: Container(height: 8, color: stageColors[i]),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
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
                Expanded(
                  flex: 1,
                  child: Center(
                    child:
                        overdueCount > 0
                            ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
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
                              style: TextStyle(
                                fontSize: 12,
                                color: _T.slate300,
                              ),
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

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY DONUT CHART
// ─────────────────────────────────────────────────────────────────────────────
class _PriorityDonutChart extends StatelessWidget {
  final List<Task> tasks;
  const _PriorityDonutChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final urgent = tasks.where((t) => t.priority == TaskPriority.urgent).length;
    final high = tasks.where((t) => t.priority == TaskPriority.high).length;
    final normal = tasks.where((t) => t.priority == TaskPriority.normal).length;
    final total = tasks.length;

    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No tasks',
            style: TextStyle(fontSize: 12, color: _T.slate400),
          ),
        ),
      );
    }

    return Column(
      children: [
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
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _T.ink,
                      letterSpacing: -1,
                      height: 1,
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
            _DonutLegendItem(color: _T.red, label: 'Urgent', count: urgent),
            _DonutLegendItem(color: _T.amber, label: 'High', count: high),
            _DonutLegendItem(
              color: _T.slate300,
              label: 'Normal',
              count: normal,
            ),
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
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.values != values;
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERDUE TASKS LIST
// ─────────────────────────────────────────────────────────────────────────────
class _OverdueTasksList extends StatelessWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final List<Member> members;
  const _OverdueTasksList({
    required this.tasks,
    required this.projects,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final overdue =
        tasks
            .where(
              (t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    if (overdue.isEmpty) return const SizedBox.shrink();

    return Column(
      children:
          overdue.map((t) {
            final proj = projects.cast<Project?>().firstWhere(
              (p) => p!.id == t.projectId,
              orElse: () => null,
            );
            Member? assignee;
            try {
              assignee = members.firstWhere((m) => t.assignees.contains(m.id));
            } catch (_) {}

            final daysLate = DateTime.now().difference(t.dueDate!).inDays;
            final si = _stageInfo(t.status);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _T.red50,
                border: Border.all(color: _T.red.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(_T.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color:
                          t.priority == TaskPriority.urgent
                              ? _T.red
                              : t.priority == TaskPriority.high
                              ? _T.amber
                              : _T.slate400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _T.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (proj != null) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: proj.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                proj.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _T.slate500,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: si.bg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                si.shortLabel,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: si.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (assignee != null) ...[
                    _AvatarWidget(
                      initials: assignee.initials,
                      color: assignee.color,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _T.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      daysLate == 0 ? 'Due today' : '$daysLate d late',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
  const _AvatarWidget({
    required this.initials,
    required this.color,
    required this.size,
  });

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

// ── Refactored Sub-Widgets Supporting Compact Dimensions ────────────────────

class _SidebarLabel extends StatelessWidget {
  final String text;
  final bool isHidden;
  const _SidebarLabel(this.text, {this.isHidden = false});

  @override
  Widget build(BuildContext context) {
    if (isHidden) return const SizedBox(height: 10);
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.white.withOpacity(0.25),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Widget? badgeWidget;
  final VoidCallback onTap;
  final bool showBeta;
  final bool isCollapsed;
  final Color? customIconColor; // Custom track override for pinned dots

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.badgeWidget,
    required this.onTap,
    this.showBeta = false,
    this.isCollapsed = false,
    this.customIconColor,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Widget mainItem = Container(
      height: 34,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 0 : 10),
      decoration: BoxDecoration(
        color:
            widget.isActive
                ? Colors.white.withOpacity(0.06)
                : (_hovered
                    ? Colors.white.withOpacity(0.03)
                    : Colors.transparent),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment:
            widget.isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
        children: [
          Icon(
            widget.icon,
            size: widget.customIconColor != null ? 8 : 16,
            color:
                widget.customIconColor ??
                Colors.white.withOpacity(widget.isActive ? 0.9 : 0.4),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: Colors.white.withOpacity(widget.isActive ? 0.9 : 0.55),
                ),
              ),
            ),
            if (widget.showBeta) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: _T.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'BETA',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: _T.blue,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (widget.badgeWidget != null) ...[
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.25),
                ),
                child: widget.badgeWidget!,
              ),
            ],
          ],
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child:
            widget.isCollapsed
                ? Tooltip(
                  message: widget.label.isEmpty ? "" : widget.label,
                  preferBelow: false,
                  verticalOffset: 0,
                  margin: const EdgeInsets.only(left: 48),
                  child: mainItem,
                )
                : mainItem,
      ),
    );
  }
}

class _SidebarItemRowSkeleton extends StatefulWidget {
  final bool isCollapsed;
  const _SidebarItemRowSkeleton({this.isCollapsed = false});

  @override
  State<_SidebarItemRowSkeleton> createState() =>
      _SidebarItemRowSkeletonState();
}

class _SidebarItemRowSkeletonState extends State<_SidebarItemRowSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double pulseOpacity = Tween<double>(
          begin: 0.1,
          end: 0.25,
        ).evaluate(_controller);

        return Container(
          height: 34,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 0 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(pulseOpacity * 0.2),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisAlignment:
                widget.isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(pulseOpacity),
                  shape: BoxShape.circle,
                ),
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 10),
                Container(
                  width: 76,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(pulseOpacity),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 16,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(pulseOpacity * 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: Colors.white.withOpacity(isActive ? 0.9 : 0.55),
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

class _OutlinedSecondaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlinedSecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_OutlinedSecondaryButton> createState() =>
      _OutlinedSecondaryButtonState();
}

class _OutlinedSecondaryButtonState extends State<_OutlinedSecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hovered ? _T.slate50 : _T.white,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _hovered ? _T.slate300 : _T.slate200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: _T.slate500),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _T.ink3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
