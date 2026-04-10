// ─────────────────────────────────────────────────────────────────────────────
// task_list_view.dart
//
// Complete task list view with real-time WebSocket updates.
// Professional redesign for agency/printing industry productivity software.
//
// Design improvements:
//   • Refined typography with better hierarchy
//   • Sophisticated row interactions with micro-animations
//   • Professional shadows and depth
//   • Quick actions on row hover
//   • Better visual separation and spacing
//   • Enhanced status indicators
//   • Agency-grade polish throughout
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/local_http.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/board_view.dart';
import 'package:smooflow/screens/desktop/components/notification_toast.dart';
import 'package:smooflow/screens/desktop/components/priority_pill.dart';
import 'package:smooflow/screens/desktop/components/stage_pill.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';
import 'package:smooflow/enums/billing_status.dart';
import 'package:smooflow/providers/task_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue600 = Color(0xFF1D4ED8);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFF8B5CF6);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;
  static const r = 6.0;
  static const rLg = 12.0;
  static const red50 = Color(0xFFFEE2E2);

  // Professional shadows for depth
  static final shadowSm = BoxShadow(
    color: Colors.black.withOpacity(0.02),
    blurRadius: 2,
    offset: const Offset(0, 1),
  );
  static final shadowMd = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 6,
    offset: const Offset(0, 2),
  );
  static final shadowLg = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const double _kRowHPad = 20.0;
const double _kRowVPad = 12.0;
const double _kCellHPad = 6.0;
const _kColAnimDuration = Duration(milliseconds: 280);
const kNotificationDuration = const Duration(seconds: 3);

// ─────────────────────────────────────────────────────────────────────────────
// VIEW MODE
// ─────────────────────────────────────────────────────────────────────────────
enum _ViewMode { list, board }

// ─────────────────────────────────────────────────────────────────────────────
// COLUMN DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────────
class _ColDef {
  final String id;
  final String label;
  final String pickerLabel;
  final String description;
  final IconData icon;
  final bool mandatory;
  final bool defaultOn;
  final int flex;

  const _ColDef({
    required this.id,
    required this.label,
    required this.pickerLabel,
    required this.description,
    required this.icon,
    required this.mandatory,
    required this.defaultOn,
    required this.flex,
  });
}

const _kCols = [
  _ColDef(
    id: 'date',
    label: 'DATE',
    pickerLabel: 'Date Created',
    description: 'Date the task was created',
    icon: Icons.calendar_today_outlined,
    mandatory: true,
    defaultOn: true,
    flex: 1,
  ),
  _ColDef(
    id: 'project',
    label: 'PROJECT',
    pickerLabel: 'Project',
    description: 'Colour-coded project name',
    icon: Icons.folder_outlined,
    mandatory: false,
    defaultOn: true,
    flex: 2,
  ),
  _ColDef(
    id: 'task',
    label: 'TASK',
    pickerLabel: 'Task Name',
    description: 'Task name',
    icon: Icons.drive_file_rename_outline_rounded,
    mandatory: true,
    defaultOn: true,
    flex: 3,
  ),
  _ColDef(
    id: 'ref',
    label: 'REF',
    pickerLabel: 'Reference',
    description: 'Client reference or PO number',
    icon: Icons.tag_rounded,
    mandatory: true,
    defaultOn: true,
    flex: 3,
  ),
  _ColDef(
    id: 'stage',
    label: 'STAGE',
    pickerLabel: 'Stage',
    description: 'Current pipeline stage pill',
    icon: Icons.view_kanban_outlined,
    mandatory: true,
    defaultOn: true,
    flex: 2,
  ),
  _ColDef(
    id: 'priority',
    label: 'PRIORITY',
    pickerLabel: 'Priority',
    description: 'Urgent / High / Normal priority pill',
    icon: Icons.flag_outlined,
    mandatory: false,
    defaultOn: true,
    flex: 1,
  ),
  _ColDef(
    id: 'size',
    label: 'SIZE',
    pickerLabel: 'Size',
    description: 'Print dimensions (W × H cm)',
    icon: Icons.straighten_outlined,
    mandatory: false,
    defaultOn: false,
    flex: 2,
  ),
  _ColDef(
    id: 'qty',
    label: 'QTY',
    pickerLabel: 'Quantity',
    description: 'Number of printed pieces',
    icon: Icons.inventory_2_outlined,
    mandatory: false,
    defaultOn: false,
    flex: 1,
  ),
];

const _kBillingCol = _ColDef(
  id: 'billing',
  label: 'BILLING',
  pickerLabel: 'Billing Status',
  description: 'Invoice and payment status',
  icon: Icons.receipt_long_outlined,
  mandatory: true,
  defaultOn: true,
  flex: 1,
);

Set<String> get _kDefaultOptionalOn =>
    _kCols.where((c) => !c.mandatory && c.defaultOn).map((c) => c.id).toSet();

Set<String> get _kMandatoryIds =>
    _kCols.where((c) => c.mandatory).map((c) => c.id).toSet();

const _kPrefsKey = 'smooflow.task_list.visible_optional_cols';
const _kViewModeKey = 'smooflow.task_list.view_mode';

// ─────────────────────────────────────────────────────────────────────────────
// TASK LIST VIEW (WebSocket-powered)
// ─────────────────────────────────────────────────────────────────────────────
class TaskListView extends ConsumerStatefulWidget {
  final List<Project> projects;
  final String? selectedProjectId;
  final int? selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  final bool isDetailOpen;
  final VoidCallback? onAddTask;
  final FocusNode? addTaskFocusNode;
  final bool isAddingTask;

  const TaskListView({
    super.key,
    required this.projects,
    required this.selectedTaskId,
    required this.onTaskSelected,
    this.selectedProjectId,
    this.isDetailOpen = false,
    this.onAddTask,
    this.addTaskFocusNode,
    this.isAddingTask = false,
  });

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> {
  Set<String> _visibleOptional = {};
  _ViewMode _viewMode = _ViewMode.list;

  bool get _singleProject => widget.selectedProjectId != null;
  static const _kDetailCols = {'date', 'task'};

  int? lastNotifiedTaskId;
  DateTime? lastNotificationTime;

  Set<String> get _effectiveVisible {
    final base =
        widget.isDetailOpen
            ? _kDetailCols
            : {..._kMandatoryIds, ..._visibleOptional};

    if (_singleProject) {
      return base.difference({'project'});
    }
    return base;
  }

  Project? get _activeProject =>
      widget.selectedProjectId == null
          ? null
          : widget.projects.cast<Project?>().firstWhere(
            (p) => p!.id == widget.selectedProjectId,
            orElse: () => null,
          );

  @override
  void initState() {
    super.initState();
    _visibleOptional = Set.from(_kDefaultOptionalOn);
    _loadPrefs();
  }

  void _loadTasks() {
    final filters = <String, dynamic>{};
    if (widget.selectedProjectId != null) {
      filters['projectId'] = widget.selectedProjectId;
    }
    ref.read(taskNotifierProvider.notifier).loadTasks(filters: filters);
  }

  void _loadPrefs() {
    final raw = LocalHttp.prefs.getString(_kPrefsKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<String>();
      if (mounted) setState(() => _visibleOptional = Set.from(list));
    } else {
      _saveColPrefs().then((value) {});
    }

    final vm = LocalHttp.prefs.getString(_kViewModeKey);
    if (vm != null && mounted) {
      setState(
        () => _viewMode = vm == 'board' ? _ViewMode.board : _ViewMode.list,
      );
    }
  }

  Future<void> _saveColPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(_visibleOptional.toList()));
  }

  Future<void> _saveViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kViewModeKey,
      _viewMode == _ViewMode.board ? 'board' : 'list',
    );
  }

  void _toggleColumn(String id) {
    setState(
      () =>
          _visibleOptional.contains(id)
              ? _visibleOptional.remove(id)
              : _visibleOptional.add(id),
    );
    _saveColPrefs();
  }

  void _resetToDefaults() {
    setState(() => _visibleOptional = Set.from(_kDefaultOptionalOn));
    _saveColPrefs();
  }

  void _setViewMode(_ViewMode mode) {
    if (_viewMode == mode) return;
    setState(() => _viewMode = mode);
    _saveViewMode();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(memberNotifierProvider).members;
    final taskState = ref.watch(taskNotifierProvider);
    final allTasks = taskState.tasks;
    final isLoading = taskState.isLoading;
    final error = taskState.error;
    final connectionStatus = ref.watch(taskConnectionStatusProvider);

    final tasks =
        widget.selectedProjectId != null
            ? allTasks
                .where(
                  (t) => t.projectId.toString() == widget.selectedProjectId,
                )
                .toList()
            : allTasks;

    final reversedTasks = tasks.reversed.toList();
    final effective = _effectiveVisible;

    ref.listen<AsyncValue<TaskChangeEvent>>(taskChangesStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((event) {
        if (event.taskId != lastNotifiedTaskId ||
            (lastNotificationTime
                    ?.add(kNotificationDuration)
                    .isBefore(DateTime.now()) ??
                false)) {
          _showTaskChangeNotification(context, event);
          lastNotifiedTaskId = event.taskId;
          lastNotificationTime = DateTime.now();
        }
      });
    });

    return Container(
      color: _T.slate50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProjectHeader(
            activeProject: _activeProject,
            viewMode: _viewMode,
            onViewModeChanged: _setViewMode,
            connectionStatus: connectionStatus,
          ),

          if (_viewMode == _ViewMode.board)
            Expanded(
              child: BoardView(
                tasks: tasks,
                projects: widget.projects,
                selectedTaskId: widget.selectedTaskId,
                onTaskSelected: widget.onTaskSelected,
                onAddTask: widget.onAddTask ?? () {},
                addTaskFocusNode: widget.addTaskFocusNode ?? FocusNode(),
                isAddingTask: widget.isAddingTask,
                selectedProjectId: widget.selectedProjectId,
              ),
            )
          else ...[
            _Toolbar(
              visibleOptional: _visibleOptional,
              isDetailOpen: widget.isDetailOpen,
              singleProject: _singleProject,
              onToggle: _toggleColumn,
              onReset: _resetToDefaults,
            ),

            // Professional column header with refined styling
            Container(
              decoration: BoxDecoration(
                color: _T.white,
                border: Border(
                  bottom: BorderSide(color: _T.slate200, width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _kRowHPad,
                  10,
                  _kRowHPad,
                  10,
                ),
                child: _AnimatedColRow(
                  effectiveVisible: effective,
                  pinnedTrailingCol: _kBillingCol,
                  builder:
                      (col, animFraction) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _kCellHPad,
                        ),
                        child: Opacity(
                          opacity: animFraction,
                          child: Text(
                            col.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: _T.slate500,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                ),
              ),
            ),

            // Data rows with professional spacing
            Expanded(
              child:
                  isLoading && tasks.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                      ? _ErrorState(
                        error: error,
                        onRetry: () {
                          ref.read(taskNotifierProvider.notifier).clearError();
                          _loadTasks();
                        },
                      )
                      : tasks.isEmpty
                      ? _EmptyState()
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _kRowHPad,
                          vertical: 10,
                        ),
                        itemCount: reversedTasks.length,
                        itemBuilder: (_, i) {
                          final t = reversedTasks[i];
                          final p =
                              widget.projects.cast<Project?>().firstWhere(
                                (pr) => pr!.id == t.projectId.toString(),
                                orElse: () => null,
                              ) ??
                              widget.projects.firstOrNull;

                          Member? m;
                          try {
                            m = members.firstWhere(
                              (mem) => t.assignees.contains(mem.id),
                            );
                          } catch (_) {
                            m = null;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _TaskRow(
                              task: t,
                              project: p,
                              assignee: m,
                              effectiveVisible: effective,
                              isSelected: widget.selectedTaskId == t.id,
                              onTap: () => widget.onTaskSelected(t.id),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTaskChangeNotification(
    BuildContext context,
    TaskChangeEvent event,
  ) {
    String message;
    IconData icon;
    Color color;

    switch (event.type) {
      case TaskChangeType.created:
        message = 'New task created';
        icon = Icons.add_task;
        color = _T.green;
        break;
      case TaskChangeType.updated:
        message = 'Task updated';
        icon = Icons.update;
        color = _T.blue;
        break;
      case TaskChangeType.deleted:
        message = 'Task deleted';
        icon = Icons.delete;
        color = _T.red;
        break;
      case TaskChangeType.statusChanged:
        message = 'Task status changed';
        icon = Icons.swap_horiz;
        color = _T.amber;
        break;
      case TaskChangeType.assigneeAdded:
        message = 'Assignee added';
        icon = Icons.person_add;
        color = _T.purple;
        break;
      case TaskChangeType.assigneeRemoved:
        message = 'Assignee removed';
        icon = Icons.person_remove;
        color = _T.slate400;
        break;
      case TaskChangeType.nameUpdated:
        return;
      case TaskChangeType.newMessage:
        return;
    }

    AppToast.show(
      message: message,
      icon: icon,
      color: color,
      subtitle: event.task!.name,
      duration: kNotificationDuration,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT HEADER - Enhanced with professional styling
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectHeader extends StatelessWidget {
  final Project? activeProject;
  final _ViewMode viewMode;
  final ValueChanged<_ViewMode> onViewModeChanged;
  final AsyncValue<ConnectionStatus> connectionStatus;

  const _ProjectHeader({
    required this.activeProject,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.connectionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isFiltered = activeProject != null;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate200, width: 1)),
        boxShadow: [_T.shadowSm],
      ),
      padding: const EdgeInsets.symmetric(horizontal: _kRowHPad),
      child: Row(
        children: [
          if (isFiltered) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: activeProject!.color,
                shape: BoxShape.circle,
                // boxShadow: [
                //   BoxShadow(
                //     color: activeProject!.color.withOpacity(0.3),
                //     blurRadius: 4,
                //     spreadRadius: 1,
                //   ),
                // ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              activeProject!.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _T.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _T.blue50,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _T.blue.withOpacity(0.2)),
              ),
              child: const Text(
                'Filtered',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _T.blue,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _T.slate100,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.workspaces_rounded,
                size: 16,
                color: _T.slate600,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'All Projects',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _T.ink,
                letterSpacing: -0.3,
              ),
            ),
          ],

          const Spacer(),

          connectionStatus.when(
            data: (status) => _ConnectionIndicator(status: status),
            loading: () => const SizedBox(width: 8),
            error: (_, __) => const SizedBox(width: 8),
          ),

          const SizedBox(width: 16),

          _ViewToggle(current: viewMode, onChange: onViewModeChanged),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONNECTION INDICATOR
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectionIndicator extends StatelessWidget {
  final ConnectionStatus status;

  const _ConnectionIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String tooltip;

    switch (status) {
      case ConnectionStatus.connected:
        color = _T.green;
        icon = Icons.cloud_done;
        tooltip = 'Connected - Real-time updates active';
        break;
      case ConnectionStatus.connecting:
        color = _T.amber;
        icon = Icons.cloud_sync;
        tooltip = 'Connecting...';
        break;
      case ConnectionStatus.reconnecting:
        color = _T.amber;
        icon = Icons.cloud_sync;
        tooltip = 'Reconnecting...';
        break;
      case ConnectionStatus.disconnected:
        color = _T.slate400;
        icon = Icons.cloud_off;
        tooltip = 'Disconnected';
        break;
      case ConnectionStatus.error:
        color = _T.red;
        icon = Icons.cloud_off;
        tooltip = 'Connection error';
        break;
    }

    return status == ConnectionStatus.connected
        ? SizedBox()
        : Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 5),
                Text(
                  status == ConnectionStatus.connected ? 'Live' : 'Offline',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _T.red50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [_T.shadowSm],
            ),
            child: const Icon(Icons.error_outline, size: 28, color: _T.red),
          ),
          const SizedBox(height: 18),
          const Text(
            'Failed to load tasks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _T.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 13, color: _T.slate500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW TOGGLE - Professional pill tabs
// ─────────────────────────────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final _ViewMode current;
  final ValueChanged<_ViewMode> onChange;

  const _ViewToggle({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.slate100,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _T.slate200),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleTab(
            icon: Icons.list_alt_outlined,
            label: 'List',
            isActive: current == _ViewMode.list,
            onTap: () => onChange(_ViewMode.list),
          ),
          const SizedBox(width: 2),
          _ToggleTab(
            icon: Icons.view_kanban_outlined,
            label: 'Board',
            isActive: current == _ViewMode.board,
            onTap: () => onChange(_ViewMode.board),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ToggleTab> createState() => _ToggleTabState();
}

class _ToggleTabState extends State<_ToggleTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isActive ? _T.white : Colors.transparent;
    final Color iconColor = widget.isActive ? _T.blue : _T.slate500;
    final Color textColor = widget.isActive ? _T.ink : _T.slate600;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(5),
            boxShadow: widget.isActive ? [_T.shadowSm] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                  letterSpacing: -0.2,
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
// ANIMATED COLUMN ROW
// ─────────────────────────────────────────────────────────────────────────────
typedef _ColCellBuilder = Widget Function(_ColDef col, double opacityFraction);

class _AnimatedColRow extends StatefulWidget {
  final Set<String> effectiveVisible;
  final _ColCellBuilder builder;
  final _ColDef? pinnedTrailingCol;

  const _AnimatedColRow({
    required this.effectiveVisible,
    required this.builder,
    this.pinnedTrailingCol,
  });

  @override
  State<_AnimatedColRow> createState() => _AnimatedColRowState();
}

class _AnimatedColRowState extends State<_AnimatedColRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  Map<String, double> _prevWidths = {};
  Map<String, double> _targetWidths = {};
  double _lastAvailableWidth = 0;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: _kColAnimDuration)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  double _pinnedWidth(double availWidth) {
    final p = widget.pinnedTrailingCol;
    if (p == null) return 0;
    final visibleCols =
        _kCols.where((c) => widget.effectiveVisible.contains(c.id)).toList();
    final totalFlex = visibleCols.fold<int>(0, (s, c) => s + c.flex) + p.flex;
    return totalFlex > 0 ? (p.flex / totalFlex) * availWidth : 0;
  }

  Map<String, double> _computeTargets(double availWidth) {
    final animAvail = availWidth - _pinnedWidth(availWidth);
    final visibleCols =
        _kCols.where((c) => widget.effectiveVisible.contains(c.id)).toList();
    final totalFlex = visibleCols.fold<int>(0, (s, c) => s + c.flex);
    final result = <String, double>{};
    for (final col in _kCols) {
      result[col.id] =
          (widget.effectiveVisible.contains(col.id) && totalFlex > 0)
              ? (col.flex / totalFlex) * animAvail
              : 0;
    }
    return result;
  }

  void _startTransition(double availWidth) {
    final newTargets = _computeTargets(availWidth);
    final changed = newTargets.entries.any(
      (e) => (e.value - (_targetWidths[e.key] ?? 0)).abs() > 0.5,
    );
    if (!changed && availWidth == _lastAvailableWidth) return;
    _prevWidths = _currentWidths(availWidth);
    _targetWidths = newTargets;
    _lastAvailableWidth = availWidth;
    _ac.forward(from: 0);
  }

  Map<String, double> _currentWidths(double availWidth) {
    if (_targetWidths.isEmpty) return _computeTargets(availWidth);
    final t = _ac.value;
    return {
      for (final col in _kCols)
        col.id: _lerpD(
          _prevWidths[col.id] ?? _targetWidths[col.id] ?? 0,
          _targetWidths[col.id] ?? 0,
          t,
        ),
    };
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;

  @override
  void didUpdateWidget(_AnimatedColRow old) {
    super.didUpdateWidget(old);
    if (old.effectiveVisible != widget.effectiveVisible &&
        _lastAvailableWidth > 0) {
      _startTransition(_lastAvailableWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final avail = constraints.maxWidth;
        if (_lastAvailableWidth == 0) {
          _targetWidths = _computeTargets(avail);
          _prevWidths = Map.from(_targetWidths);
          _lastAvailableWidth = avail;
        } else if ((avail - _lastAvailableWidth).abs() > 1) {
          _targetWidths = _computeTargets(avail);
          _prevWidths = Map.from(_targetWidths);
          _lastAvailableWidth = avail;
        }

        final widths = _currentWidths(avail);
        final pinnedW = _pinnedWidth(avail);
        final pinned = widget.pinnedTrailingCol;

        return Row(
          children: [
            ..._kCols.map((col) {
              final w = widths[col.id] ?? 0;
              final visible = widget.effectiveVisible.contains(col.id);
              final opacity =
                  visible
                      ? Curves.easeOut.transform(
                        _ac.isAnimating ? _ac.value : 1.0,
                      )
                      : Curves.easeIn.transform(
                        _ac.isAnimating ? (1 - _ac.value) : 0.0,
                      );
              return SizedBox(
                width: w,
                child:
                    w < 1
                        ? const SizedBox.shrink()
                        : widget.builder(col, opacity.clamp(0.0, 1.0)),
              );
            }),
            if (pinned != null)
              SizedBox(width: pinnedW, child: widget.builder(pinned, 1.0)),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOOLBAR - Enhanced professional styling
// ─────────────────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final Set<String> visibleOptional;
  final bool isDetailOpen;
  final bool singleProject;
  final void Function(String) onToggle;
  final VoidCallback onReset;

  const _Toolbar({
    required this.visibleOptional,
    required this.isDetailOpen,
    required this.singleProject,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate100, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _kRowHPad),
      child: Row(
        children: [
          if (singleProject)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _T.blue50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _T.blue.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.filter_alt, size: 12, color: _T.blue),
                  SizedBox(width: 5),
                  Text(
                    'Project column auto-hidden',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _T.blue,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          if (isDetailOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _T.slate100,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _T.slate200),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_sidebar_outlined,
                    size: 13,
                    color: _T.slate500,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Core columns only',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _T.slate600,
                    ),
                  ),
                ],
              ),
            )
          else
            _ColumnPickerButton(
              visibleOptional: visibleOptional,
              singleProject: singleProject,
              onToggle: onToggle,
              onReset: onReset,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLUMN PICKER BUTTON + OVERLAY
// ─────────────────────────────────────────────────────────────────────────────
class _ColumnPickerButton extends StatefulWidget {
  final Set<String> visibleOptional;
  final bool singleProject;
  final void Function(String) onToggle;
  final VoidCallback onReset;

  const _ColumnPickerButton({
    required this.visibleOptional,
    required this.singleProject,
    required this.onToggle,
    required this.onReset,
  });

  @override
  State<_ColumnPickerButton> createState() => _ColumnPickerButtonState();
}

class _ColumnPickerButtonState extends State<_ColumnPickerButton>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;
  late Set<String> _overlayVisible;

  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ac,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _overlayVisible = Set.from(widget.visibleOptional);
  }

  @override
  void didUpdateWidget(_ColumnPickerButton old) {
    super.didUpdateWidget(old);
    _overlayVisible = Set.from(widget.visibleOptional);
    if (_open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _overlay?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _ac.dispose();
    super.dispose();
  }

  void _toggle() => _open ? _close() : _show();

  void _show() {
    _overlayVisible = Set.from(widget.visibleOptional);
    setState(() => _open = true);
    _overlay = _buildOverlay();
    Overlay.of(context).insert(_overlay!);
    _ac.forward(from: 0);
  }

  Future<void> _close() async {
    await _ac.reverse();
    _removeOverlay();
    if (mounted) setState(() => _open = false);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  OverlayEntry _buildOverlay() => OverlayEntry(
    builder:
        (_) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 8),
              child: AnimatedBuilder(
                animation: _ac,
                builder:
                    (_, child) => FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(position: _slide, child: child),
                    ),
                child: _ColumnPickerPanel(
                  visibleOptional: _overlayVisible,
                  singleProject: widget.singleProject,
                  onToggle: widget.onToggle,
                  onReset: widget.onReset,
                  onClose: _close,
                ),
              ),
            ),
          ],
        ),
  );

  @override
  Widget build(BuildContext context) {
    final optionalOnCount = widget.visibleOptional.length;
    final hasCustom = !_setsEqual(widget.visibleOptional, _kDefaultOptionalOn);

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _open ? _T.slate100 : (hasCustom ? _T.blue50 : _T.white),
              border: Border.all(
                color:
                    _open
                        ? _T.slate300
                        : (hasCustom ? _T.blue.withOpacity(0.3) : _T.slate200),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: _open ? [_T.shadowSm] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_column_outlined,
                  size: 14,
                  color: _open || hasCustom ? _T.blue : _T.slate500,
                ),
                const SizedBox(width: 7),
                Text(
                  'Columns',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _open || hasCustom ? _T.blue : _T.ink2,
                    letterSpacing: -0.2,
                  ),
                ),
                if (optionalOnCount > 0) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: hasCustom ? _T.blue : _T.slate200,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$optionalOnCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: hasCustom ? Colors.white : _T.slate600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 5),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: _open || hasCustom ? _T.blue : _T.slate400,
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
// COLUMN PICKER PANEL
// ─────────────────────────────────────────────────────────────────────────────
class _ColumnPickerPanel extends StatelessWidget {
  final Set<String> visibleOptional;
  final bool singleProject;
  final void Function(String) onToggle;
  final VoidCallback onReset;
  final VoidCallback onClose;

  const _ColumnPickerPanel({
    required this.visibleOptional,
    required this.singleProject,
    required this.onToggle,
    required this.onReset,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final mandatoryCols = _kCols.where((c) => c.mandatory).toList();
    final optionalCols =
        _kCols.where((c) => !c.mandatory && c.id != 'project').toList();
    final projectCol = _kCols.firstWhere((c) => c.id == 'project');
    final isDefault = _setsEqual(visibleOptional, _kDefaultOptionalOn);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_T.rLg),
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 540),
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rLg),
          border: Border.all(color: _T.slate200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            _T.shadowMd,
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.slate100)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _T.blue50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _T.blue.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.view_column_outlined,
                      size: 16,
                      color: _T.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Columns',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Customize your view',
                          style: TextStyle(fontSize: 11.5, color: _T.slate500),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _T.slate100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: _T.slate500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Always visible'),
                    const SizedBox(height: 10),
                    ...mandatoryCols.map((c) => _LockedColRow(col: c)),
                    _LockedColRow(
                      col: _kBillingCol,
                      trailingHint: 'Always last',
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: _T.slate100),
                    const SizedBox(height: 16),

                    _SectionLabel('Auto-managed'),
                    const SizedBox(height: 10),
                    _AutoColRow(
                      col: projectCol,
                      label:
                          singleProject
                              ? 'Hidden — project filter active'
                              : 'Visible — all projects shown',
                      active: !singleProject,
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: _T.slate100),
                    const SizedBox(height: 16),

                    _SectionLabel('Optional columns'),
                    const SizedBox(height: 10),
                    ...optionalCols.map(
                      (c) => _ToggleColRow(
                        col: c,
                        enabled: visibleOptional.contains(c.id),
                        onTap: () => onToggle(c.id),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _T.slate100)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.restart_alt_rounded,
                    size: 14,
                    color: isDefault ? _T.slate300 : _T.slate500,
                  ),
                  const SizedBox(width: 7),
                  GestureDetector(
                    onTap: isDefault ? null : onReset,
                    child: MouseRegion(
                      cursor:
                          isDefault
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                      child: Text(
                        'Reset to defaults',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDefault ? _T.slate300 : _T.slate600,
                          decoration:
                              isDefault
                                  ? TextDecoration.none
                                  : TextDecoration.underline,
                          decorationColor: _T.slate500,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${optionalCols.where((c) => visibleOptional.contains(c.id)).length}/${optionalCols.length} optional',
                    style: const TextStyle(fontSize: 11.5, color: _T.slate400),
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
// AUTO-MANAGED COLUMN ROW
// ─────────────────────────────────────────────────────────────────────────────
class _AutoColRow extends StatelessWidget {
  final _ColDef col;
  final String label;
  final bool active;

  const _AutoColRow({
    required this.col,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? _T.blue50 : _T.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? _T.blue.withOpacity(0.2) : _T.slate200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: active ? _T.blue.withOpacity(0.1) : _T.slate100,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              col.icon,
              size: 14,
              color: active ? _T.blue : _T.slate400,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  col.pickerLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? _T.ink : _T.ink3,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: _T.slate500),
                ),
              ],
            ),
          ),
          Icon(
            active ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 14,
            color: active ? _T.blue : _T.slate300,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCKED COLUMN ROW
// ─────────────────────────────────────────────────────────────────────────────
class _LockedColRow extends StatelessWidget {
  final _ColDef col;
  final String? trailingHint;
  const _LockedColRow({required this.col, this.trailingHint});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(col.icon, size: 14, color: _T.slate400),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              col.pickerLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _T.ink3,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (trailingHint != null) ...[
            Text(
              trailingHint!,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _T.slate400,
              ),
            ),
            const SizedBox(width: 7),
          ],
          const Icon(Icons.lock_outline_rounded, size: 13, color: _T.slate300),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE COLUMN ROW
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleColRow extends StatefulWidget {
  final _ColDef col;
  final bool enabled;
  final VoidCallback onTap;
  const _ToggleColRow({
    required this.col,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ToggleColRow> createState() => _ToggleColRowState();
}

class _ToggleColRowState extends State<_ToggleColRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color:
                widget.enabled
                    ? _T.blue.withOpacity(0.06)
                    : (_hovering ? _T.slate50 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  widget.enabled
                      ? _T.blue.withOpacity(0.25)
                      : (_hovering ? _T.slate200 : Colors.transparent),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      widget.enabled ? _T.blue.withOpacity(0.12) : _T.slate100,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  widget.col.icon,
                  size: 14,
                  color: widget.enabled ? _T.blue : _T.slate400,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.col.pickerLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.enabled ? _T.ink : _T.ink3,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.col.description,
                      style: const TextStyle(fontSize: 11, color: _T.slate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _MiniSwitch(
                value: widget.enabled,
                onChanged: (_) => widget.onTap(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI SWITCH
// ─────────────────────────────────────────────────────────────────────────────
class _MiniSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _MiniSwitch({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 22,
    child: Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeColor: _T.blue,
      inactiveThumbColor: _T.slate300,
      inactiveTrackColor: _T.slate200,
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Colors.white : _T.slate300,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.9,
      color: _T.slate500,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK ROW - Professional redesign with sophisticated interactions
// ─────────────────────────────────────────────────────────────────────────────
class _TaskRow extends StatefulWidget {
  final Task task;
  final Project? project;
  final Member? assignee;
  final Set<String> effectiveVisible;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskRow({
    required this.task,
    required this.project,
    required this.assignee,
    required this.effectiveVisible,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _hovered = false;

  static const _completeBg = Color(0xFFF0FDF4);
  static const _completeBorder = Color(0xFFBBF7D0);
  static const _completeText = Color(0xFF166534);
  static const _completeMuted = Color.fromARGB(255, 31, 220, 129);

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final p = widget.project;
    final m = widget.assignee;
    final now = DateTime.now();
    final s = stageInfo(t.status);
    final d = t.date ?? t.createdAt;

    final isCompleted = t.status == TaskStatus.completed;

    final dateFormatted = fmtDate(d);
    final dateParts = dateFormatted.split(' ');
    final dateDisplay =
        d.year == now.year && dateParts.length > 2
            ? dateParts.take(dateParts.length - 1).join(' ')
            : dateFormatted;

    // Professional row styling with micro-interactions
    final Color rowColor =
        isCompleted
            ? (_hovered ? const Color(0xFFDCFCE7) : _completeBg)
            : widget.isSelected
            ? _T.blue50
            : _hovered
            ? _T.white
            : _T.white;

    final List<BoxShadow> rowShadows =
        isCompleted
            ? []
            : _hovered && !widget.isSelected
            ? [_T.shadowMd]
            : widget.isSelected
            ? [_T.shadowSm]
            : [];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: rowColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isCompleted
                    ? _completeBorder.withOpacity(0.4)
                    : widget.isSelected
                    ? _T.blue.withOpacity(0.3)
                    : _hovered
                    ? _T.slate200
                    : _T.slate100,
            width: isCompleted ? 1 : 1,
          ),
          boxShadow: rowShadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            splashColor: _T.blue.withOpacity(0.05),
            highlightColor: _T.blue.withOpacity(0.03),
            child: Stack(
              children: [
                // Completion indicator stripe
                if (isCompleted)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: _completeMuted,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(7),
                          bottomLeft: Radius.circular(7),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompleted ? 12 : _kRowHPad - 8,
                    _kRowVPad,
                    _kRowHPad - 8,
                    _kRowVPad,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AnimatedColRow(
                          effectiveVisible: widget.effectiveVisible,
                          pinnedTrailingCol: _kBillingCol,
                          builder:
                              (col, opacity) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _kCellHPad,
                                ),
                                child: Opacity(
                                  opacity:
                                      isCompleted ? (opacity * 0.7) : opacity,
                                  child: _cellFor(
                                    col,
                                    t,
                                    p,
                                    m,
                                    s,
                                    dateDisplay,
                                    isCompleted: isCompleted,
                                  ),
                                ),
                              ),
                        ),
                      ),

                      // TODO: Quick actions on hover (hidden for completed tasks)
                      // if (_hovered && !isCompleted) ...[
                      //   const SizedBox(width: 8),
                      //   _QuickActions(),
                      // ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cellFor(
    _ColDef col,
    Task t,
    Project? p,
    Member? m,
    dynamic s,
    String date, {
    required bool isCompleted,
  }) {
    TextStyle completedBody(TextStyle base) =>
        isCompleted
            ? base.copyWith(
              color: _completeText.withOpacity(0.6),
              decorationColor: _completeMuted.withOpacity(0.7),
              decorationThickness: 1.5,
            )
            : base;

    return switch (col.id) {
      'task' => Row(
        children: [
          Expanded(
            child: Text(
              "${t.name}",
              style: completedBody(
                const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _T.ink,
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),

      'project' =>
        p != null
            ? Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        isCompleted ? _completeMuted.withOpacity(0.5) : p.color,
                    shape: BoxShape.circle,
                    boxShadow:
                        isCompleted
                            ? null
                            : [
                              BoxShadow(
                                color: p.color.withOpacity(0.3),
                                blurRadius: 3,
                                spreadRadius: 0.5,
                              ),
                            ],
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    p.name,
                    overflow: TextOverflow.ellipsis,
                    style: completedBody(
                      const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _T.slate600,
                      ),
                    ),
                  ),
                ),
              ],
            )
            : const Text('—', style: TextStyle(color: _T.slate300)),

      'ref' =>
        t.ref != null && t.ref!.isNotEmpty
            ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted ? _T.slate50 : _T.slate100,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isCompleted ? _T.slate100 : _T.slate200,
                ),
              ),
              child: Text(
                t.ref!,
                overflow: TextOverflow.ellipsis,
                style: completedBody(
                  const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _T.ink3,
                    fontFamily: 'monospace',
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            )
            : const Text(
              '—',
              style: TextStyle(fontSize: 13, color: _T.slate300),
            ),

      'stage' => isCompleted ? _CompletedStagePill() : StagePill(stageInfo: s),

      'date' => Text(
        date,
        style: completedBody(
          const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _T.slate500,
          ),
        ),
      ),

      'priority' =>
        isCompleted
            ? Opacity(opacity: 0.5, child: PriorityPill(priority: t.priority))
            : PriorityPill(priority: t.priority),

      'size' =>
        t.size != null && !t.size!.contains("null")
            ? RichText(
              text: TextSpan(
                style: completedBody(
                  const TextStyle(fontSize: 13, color: _T.ink3),
                ),
                children: [
                  TextSpan(
                    text: t.size!.split(' ')[0],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text:
                        t.size!.split(' ').length > 1
                            ? ' ${t.size!.split(' ')[1]}'
                            : '',
                    style: TextStyle(
                      fontSize: 11.5,
                      color:
                          isCompleted
                              ? _completeText.withOpacity(0.4)
                              : _T.slate400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
            : const Text(
              '—',
              style: TextStyle(fontSize: 13, color: _T.slate300),
            ),

      'qty' =>
        t.quantity != null
            ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted ? _T.slate50 : _T.slate100,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '${t.quantity}',
                style: completedBody(
                  const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _T.ink3,
                  ),
                ),
              ),
            )
            : const Text(
              '—',
              style: TextStyle(fontSize: 13, color: _T.slate300),
            ),

      'assignee' =>
        m != null
            ? Row(
              children: [
                Opacity(
                  opacity: isCompleted ? 0.5 : 1.0,
                  child: AvatarWidget(
                    initials: m.initials,
                    color: m.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m.name,
                    overflow: TextOverflow.ellipsis,
                    style: completedBody(
                      const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _T.slate600,
                      ),
                    ),
                  ),
                ),
              ],
            )
            : const Text(
              '—',
              style: TextStyle(fontSize: 13, color: _T.slate300),
            ),

      'billing' => _BillingStatusCell(
        status: t.billingStatus,
        dimmed: isCompleted,
      ),

      _ => const SizedBox.shrink(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS - Appears on row hover for quick task interactions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.more_horiz_rounded,
            tooltip: 'More options',
            onTap: () {
              // Handle more options
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hovered ? _T.slate100 : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered ? _T.ink2 : _T.slate400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETED STAGE PILL
// ─────────────────────────────────────────────────────────────────────────────
class _CompletedStagePill extends StatelessWidget {
  const _CompletedStagePill();

  static const _fg = Color(0xFF166534);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'Completed',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _fg,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILLING STATUS CELL
// ─────────────────────────────────────────────────────────────────────────────
class _BillingStatusCell extends StatelessWidget {
  final BillingStatus? status;
  final bool dimmed;

  const _BillingStatusCell({required this.status, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const Text(
        '—',
        style: TextStyle(fontSize: 13, color: _T.slate300),
      );
    }

    final (String label, Color fg, Color bg) = switch (status!) {
      BillingStatus.pending => ('-', _T.amber, const Color(0xFFFEF3C7)),
      BillingStatus.invoiced => ('Invoiced', _T.blue, _T.blue50),
      BillingStatus.foc => ('FOC', _T.green, const Color(0xFFECFDF5)),
      BillingStatus.cancelled => ('Cancelled', _T.red, const Color(0xFFFEE2E2)),
      BillingStatus.quoteGiven => ('Quote', _T.slate400, _T.slate100),
    };

    return Opacity(
      opacity: dimmed ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: fg.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _T.slate100,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [_T.shadowSm],
          ),
          child: const Icon(
            Icons.assignment_outlined,
            size: 32,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No tasks yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _T.ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tasks you create will appear here',
          style: TextStyle(fontSize: 13.5, color: _T.slate500),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
bool _setsEqual(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
