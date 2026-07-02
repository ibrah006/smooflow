// ─────────────────────────────────────────────────────────────────────────────
// task_list_view.dart
//
// Task list view with RESIZABLE columns.
//
// Architecture change from original:
//   • ColumnWidthNotifier (InheritedNotifier) owns pixel widths for every col.
//   • Header row renders columns at exact pixel widths from the notifier, with
//     a _ResizeHandle drag-divider between each pair of adjacent visible cols.
//   • Every _TaskRow reads the same notifier so all cells stay pixel-aligned
//     with the headers at all times — no layout mismatch possible.
//   • Show/hide toggles update the notifier (width → 0 or → default). No
//     separate animation controller needed; the notifier drives everything.
//   • The previous _AnimatedColRow is replaced by a simpler _ColRow widget
//     that reads widths from ColumnWidthScope and clips/fades hidden cols.
//   • All other behaviour (board view, connection indicator, column picker,
//     notifications, completed-row styling, billing pinned col) is unchanged.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/local_http.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/desktop/admin_desktop_dashboard.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/board_view.dart';
import 'package:smooflow/screens/desktop/components/notification_toast.dart';
import 'package:smooflow/screens/desktop/components/selection_pill.dart';
import 'package:smooflow/screens/desktop/components/stage_pill.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';
import 'package:smooflow/enums/billing_status.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/project_overview_screen.concept.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS
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
  static const green50 = Color(0xFFECFDF5);
  static const amber50 = Color(0xFFFEF3C7);

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
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const double _kRowHPad = 16.0;
const double _kCellHPad = 8.0;
const double _kResizeHandleWidth = 8.0;
const double _kMinColWidth = 48.0;
const double _kMaxColWidth = 480.0;

const kNotificationDuration = Duration(seconds: 3);

// ─────────────────────────────────────────────────────────────────────────────
// VIEW MODE
// ─────────────────────────────────────────────────────────────────────────────
enum _ViewMode { list, board, overview }

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
  final double defaultWidth;

  const _ColDef({
    required this.id,
    required this.label,
    required this.pickerLabel,
    required this.description,
    required this.icon,
    required this.mandatory,
    required this.defaultOn,
    required this.defaultWidth,
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
    defaultWidth: 100,
  ),
  _ColDef(
    id: 'project',
    label: 'PROJECT',
    pickerLabel: 'Project',
    description: 'Colour-coded project name',
    icon: Icons.folder_outlined,
    mandatory: false,
    defaultOn: true,
    defaultWidth: 130,
  ),
  _ColDef(
    id: 'task',
    label: 'TASK',
    pickerLabel: 'Task Name',
    description: 'Task name',
    icon: Icons.drive_file_rename_outline_rounded,
    mandatory: true,
    defaultOn: true,
    defaultWidth: 240,
  ),
  _ColDef(
    id: 'ref',
    label: 'REF',
    pickerLabel: 'Reference',
    description: 'Client reference or PO number',
    icon: Icons.tag_rounded,
    mandatory: false,
    defaultOn: true,
    defaultWidth: 160,
  ),
  _ColDef(
    id: 'stage',
    label: 'STAGE',
    pickerLabel: 'Stage',
    description: 'Current pipeline stage pill',
    icon: Icons.view_kanban_outlined,
    mandatory: true,
    defaultOn: true,
    defaultWidth: 120,
  ),
  _ColDef(
    id: 'priority',
    label: 'PRIORITY',
    pickerLabel: 'Priority',
    description: 'Urgent / High / Normal priority pill',
    icon: Icons.flag_outlined,
    mandatory: false,
    defaultOn: true,
    defaultWidth: 90,
  ),
  _ColDef(
    id: 'size',
    label: 'SIZE',
    pickerLabel: 'Size',
    description: 'Print dimensions (W × H cm)',
    icon: Icons.straighten_outlined,
    mandatory: false,
    defaultOn: false,
    defaultWidth: 120,
  ),
  _ColDef(
    id: 'qty',
    label: 'QTY',
    pickerLabel: 'Quantity',
    description: 'Number of printed pieces',
    icon: Icons.inventory_2_outlined,
    mandatory: false,
    defaultOn: false,
    defaultWidth: 64,
  ),
];

const _kBillingCol = _ColDef(
  id: 'billing',
  label: 'BILLING',
  pickerLabel: 'Billing Status',
  description: 'Invoice and payment status',
  icon: Icons.receipt_long_outlined,
  mandatory: false,
  defaultOn: true,
  defaultWidth: 100,
);

Set<String> get _kDefaultOptionalOn =>
    _kCols.where((c) => !c.mandatory && c.defaultOn).map((c) => c.id).toSet();

Set<String> get _kMandatoryIds =>
    _kCols.where((c) => c.mandatory).map((c) => c.id).toSet();

const _kPrefsKey = 'smooflow.task_list.visible_optional_cols';
const _kViewModeKey = 'smooflow.task_list.view_mode';
const _kColWidthsKey = 'smooflow.task_list.col_widths';

Map<String, double> _defaultWidthMap() => {
  for (final c in _kCols) c.id: c.defaultWidth,
  _kBillingCol.id: _kBillingCol.defaultWidth,
};

// ─────────────────────────────────────────────────────────────────────────────
// COLUMN WIDTH NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

/// Holds current pixel widths for all columns.
/// Hidden columns have width 0. The billing column is always visible.
class _ColumnWidthNotifier extends ChangeNotifier {
  final Map<String, double> _widths;
  final Map<String, double> _defaults;

  _ColumnWidthNotifier(Map<String, double> defaults)
    : _widths = Map.from(defaults),
      _defaults = Map.from(defaults);

  double widthOf(String id) => _widths[id] ?? 0;

  Map<String, double> snapshot() => Map.from(_widths);

  void resize(String id, double delta, {double? maxAllowedWidth}) {
    final w = (_widths[id] ?? 0) + delta;
    // Ensure the upper limit is bound by both the screen edge and the global maximum constraint
    final maxW = maxAllowedWidth ?? _kMaxColWidth;
    _widths[id] = w.clamp(
      _kMinColWidth,
      maxW.clamp(_kMinColWidth, _kMaxColWidth),
    );
    notifyListeners();
  }

  void setVisible(String id, bool visible) {
    _widths[id] = visible ? (_defaults[id] ?? 100) : 0;
    notifyListeners();
  }

  void resetToDefaults(Set<String> visibleIds) {
    for (final c in _kCols) {
      _widths[c.id] = visibleIds.contains(c.id) ? (_defaults[c.id] ?? 100) : 0;
    }
    _widths[_kBillingCol.id] = _defaults[_kBillingCol.id] ?? 110;
    notifyListeners();
  }

  void loadSaved(Map<String, double> saved) {
    _widths.addAll(saved);
    notifyListeners();
  }
}

/// InheritedNotifier — lets header + every task row share widths without prop drilling.
class _WidthScope extends InheritedNotifier<_ColumnWidthNotifier> {
  const _WidthScope({
    required _ColumnWidthNotifier super.notifier,
    required super.child,
  });

  static _ColumnWidthNotifier of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WidthScope>()!.notifier!;
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK LIST VIEW
// ─────────────────────────────────────────────────────────────────────────────
class TaskListView extends ConsumerStatefulWidget {
  final List<Project> projects;
  final String? selectedProjectId;
  final int? selectedTaskId;
  final Function(int taskId, String detailPanelProjectId) onTaskSelected;
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
  late final _ColumnWidthNotifier _widthNotifier;

  bool get _singleProject => widget.selectedProjectId != null;

  // static const _kDetailCols = {'date', 'task'};

  int? lastNotifiedTaskId;
  DateTime? lastNotificationTime;

  Set<String> get _effectiveVisible {
    // Always use the full set of mandatory and chosen optional columns
    final base = {..._kMandatoryIds, ..._visibleOptional};
    return _singleProject ? base.difference({'project'}) : base;
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

    // Build notifier with defaults; hide optional-off columns
    final defaults = _defaultWidthMap();
    for (final c in _kCols) {
      if (!c.mandatory && !c.defaultOn) defaults[c.id] = 0;
    }
    _widthNotifier = _ColumnWidthNotifier(defaults);

    _loadPrefs();
  }

  @override
  void dispose() {
    _widthNotifier.dispose();
    super.dispose();
  }

  void _loadPrefs() {
    // Column visibility
    final rawVis = LocalHttp.prefs.getString(_kPrefsKey);
    if (rawVis != null) {
      final list = (jsonDecode(rawVis) as List).cast<String>();
      _visibleOptional = Set.from(list);
    }

    // View mode
    final vm = LocalHttp.prefs.getString(_kViewModeKey);
    if (vm != null) {
      _viewMode = vm == 'board' ? _ViewMode.board : _ViewMode.list;
    }

    // Column widths
    final rawW = LocalHttp.prefs.getString(_kColWidthsKey);
    if (rawW != null) {
      final map = (jsonDecode(rawW) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
      _widthNotifier.loadSaved(map);
    } else {
      // Apply visibility to notifier from freshly loaded prefs
      for (final c in _kCols) {
        if (!c.mandatory) {
          _widthNotifier.setVisible(c.id, _visibleOptional.contains(c.id));
        }
      }
      if (_singleProject) _widthNotifier.setVisible('project', false);
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveColPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(_visibleOptional.toList()));
  }

  Future<void> _saveWidths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kColWidthsKey,
      jsonEncode(_widthNotifier.snapshot()),
    );
  }

  Future<void> _saveViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kViewModeKey,
      _viewMode == _ViewMode.board ? 'board' : 'list',
    );
  }

  void _toggleColumn(String id) {
    setState(() {
      if (_visibleOptional.contains(id)) {
        _visibleOptional.remove(id);
        _widthNotifier.setVisible(id, false);
      } else {
        _visibleOptional.add(id);
        _widthNotifier.setVisible(id, true);
      }
    });
    _saveColPrefs();
    _saveWidths();
  }

  void _resetToDefaults() {
    setState(() => _visibleOptional = Set.from(_kDefaultOptionalOn));
    _widthNotifier.resetToDefaults(_effectiveVisible);
    _saveColPrefs();
    _saveWidths();
  }

  void _setViewMode(_ViewMode mode) {
    if (_viewMode == mode) return;
    setState(() => _viewMode = mode);
    _saveViewMode();
  }

  @override
  void didUpdateWidget(TaskListView old) {
    super.didUpdateWidget(old);
    // If the project filter changed, show/hide project column
    if (old.selectedProjectId != widget.selectedProjectId) {
      _widthNotifier.setVisible('project', !_singleProject);
    }
    // If detail panel opened/closed, show/hide non-core columns
    if (old.isDetailOpen != widget.isDetailOpen) {
      _applyDetailMode();
    }
  }

  void _applyDetailMode() {
    // Always maintain standard visibility and keep the billing column visible
    final effective = _effectiveVisible;
    for (final c in _kCols) {
      _widthNotifier.setVisible(c.id, effective.contains(c.id));
    }
    _widthNotifier.setVisible(_kBillingCol.id, true);
  }

  void _loadTasks() {
    final filters = <String, dynamic>{};
    if (widget.selectedProjectId != null) {
      filters['projectId'] = widget.selectedProjectId;
    }
    ref.read(taskNotifierProvider.notifier).loadTasks(filters: filters);
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

    final Project? _selectedProject =
        widget.selectedProjectId != null
            ? ref.read(projectByIdProvider(widget.selectedProjectId!))
            : null;

    return _WidthScope(
      notifier: _widthNotifier,
      child: Container(
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
            else if (_viewMode == _ViewMode.overview)
              Expanded(
                child: DesktopProjectOverviewScreen(
                  selectedProjectId: widget.selectedProjectId,
                  project: _selectedProject,
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

              // ── HORIZONTAL SCROLL CONTEXT FOR HEADERS & ROWS ──
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedBuilder(
                      animation: _widthNotifier,
                      builder: (context, _) {
                        // 1. Calculate the exact content width matching all columns + spacers
                        double tableWidth = 0;
                        for (final col in _kCols) {
                          if (effective.contains(col.id)) {
                            tableWidth += _widthNotifier.widthOf(col.id);
                            tableWidth += _kResizeHandleWidth;
                          }
                        }
                        tableWidth += _widthNotifier.widthOf(_kBillingCol.id);
                        tableWidth +=
                            2 * _kRowHPad; // Include list's horizontal padding

                        // 2. Ensure layout expands to at least the available viewport width
                        final scrollableWidth =
                            tableWidth > constraints.maxWidth
                                ? tableWidth
                                : constraints.maxWidth;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: scrollableWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Column header row with resize handles ───────────
                                Container(
                                  color: _T.white,
                                  child: Column(
                                    children: [
                                      _HeaderRow(
                                        effectiveVisible: effective,
                                        onResizeEnd: _saveWidths,
                                        isDetailOpen: widget.isDetailOpen,
                                        constraintsMaxWidth:
                                            constraints
                                                .maxWidth, // Pass the bounding constraint width here
                                      ),
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: _T.slate200,
                                      ),
                                    ],
                                  ),
                                ),

                                // ── Data rows ──────────────────────────────────────
                                Expanded(
                                  child:
                                      isLoading && tasks.isEmpty
                                          ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                          : error != null
                                          ? _ErrorState(
                                            error: error,
                                            onRetry: () {
                                              ref
                                                  .read(
                                                    taskNotifierProvider
                                                        .notifier,
                                                  )
                                                  .clearError();
                                              _loadTasks();
                                            },
                                          )
                                          : tasks.isEmpty
                                          ? _EmptyState()
                                          : ListView.separated(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: _kRowHPad,
                                              vertical: 8,
                                            ),
                                            itemCount: reversedTasks.length,
                                            separatorBuilder:
                                                (_, __) => const Divider(
                                                  height: 1,
                                                  thickness: 1,
                                                  color: _T.slate100,
                                                ),
                                            itemBuilder: (_, i) {
                                              final t = reversedTasks[i];
                                              final p =
                                                  widget.projects
                                                      .cast<Project?>()
                                                      .firstWhere(
                                                        (pr) =>
                                                            pr!.id ==
                                                            t.projectId
                                                                .toString(),
                                                        orElse: () => null,
                                                      ) ??
                                                  widget.projects.firstOrNull;

                                              Member? m;
                                              try {
                                                m = members.firstWhere(
                                                  (mem) => t.assignees.contains(
                                                    mem.id,
                                                  ),
                                                );
                                              } catch (_) {
                                                m = null;
                                              }

                                              return _TaskRow(
                                                taskId: t.id,
                                                project: p,
                                                assignee: m,
                                                effectiveVisible: effective,
                                                isDetailOpen:
                                                    widget.isDetailOpen,
                                                isSelected:
                                                    widget.selectedTaskId ==
                                                    t.id,
                                                onTap:
                                                    () => widget.onTaskSelected(
                                                      t.id,
                                                      t.projectId,
                                                    ),
                                              );
                                            },
                                          ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
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
        return;
      case TaskChangeType.updated:
        return;
      case TaskChangeType.deleted:
        return;
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
      default:
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
// HEADER ROW — renders column labels + resize handles
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderRow extends StatelessWidget {
  final Set<String> effectiveVisible;
  final VoidCallback? onResizeEnd;
  final bool isDetailOpen;
  final double constraintsMaxWidth; // Add this line

  const _HeaderRow({
    required this.effectiveVisible,
    this.onResizeEnd,
    required this.isDetailOpen,
    required this.constraintsMaxWidth, // Add this line
  });

  @override
  Widget build(BuildContext context) {
    final notifier = _WidthScope.of(context);
    final allCols = [..._kCols, _kBillingCol];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kRowHPad, vertical: 8),
      child: AnimatedBuilder(
        animation: notifier,
        builder: (context, _) {
          return Row(children: _buildHeaderCells(context, notifier, allCols));
        },
      ),
    );
  }

  List<Widget> _buildHeaderCells(
    BuildContext context,
    _ColumnWidthNotifier notifier,
    List<_ColDef> allCols,
  ) {
    final result = <Widget>[];
    final visibleCols =
        allCols.where((c) {
          if (c.id == 'billing') return true;
          return effectiveVisible.contains(c.id);
        }).toList();

    // Start with the initial padding offset
    double accumulatedLeft = _kRowHPad;

    for (int i = 0; i < visibleCols.length; i++) {
      final col = visibleCols[i];
      final w = notifier.widthOf(col.id);
      if (w < 1) continue;

      result.add(
        SizedBox(
          width: w,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
            child: Text(
              col.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: _T.slate400,
              ),
            ),
          ),
        ),
      );

      // Max width equals total screen space minus everything up to this column
      final maxAllowedWidth = constraintsMaxWidth - accumulatedLeft;

      accumulatedLeft += w;

      if (!isDetailOpen && i < visibleCols.length - 1) {
        result.add(
          _ResizeHandle(
            colId: col.id,
            notifier: notifier,
            onResizeEnd: onResizeEnd,
            maxAllowedWidth: maxAllowedWidth, // Pass calculation here
          ),
        );
        accumulatedLeft += _kResizeHandleWidth;
      }
    }

    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESIZE HANDLE
// ─────────────────────────────────────────────────────────────────────────────
class _ResizeHandle extends StatefulWidget {
  final String colId;
  final _ColumnWidthNotifier notifier;
  final VoidCallback? onResizeEnd;
  final double maxAllowedWidth; // Add this line

  const _ResizeHandle({
    required this.colId,
    required this.notifier,
    this.onResizeEnd,
    required this.maxAllowedWidth, // Add this line
  });

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _dragging = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (details) {
          // Pass maxAllowedWidth to the resize trigger
          widget.notifier.resize(
            widget.colId,
            details.delta.dx,
            maxAllowedWidth: widget.maxAllowedWidth,
          );
        },
        onHorizontalDragEnd: (_) {
          setState(() => _dragging = false);
          widget.onResizeEnd?.call();
        },
        child: SizedBox(
          width: _kResizeHandleWidth,
          height: 20,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: _dragging ? 2 : (_hovering ? 1.5 : 1),
              height: _dragging ? 20 : 12,
              decoration: BoxDecoration(
                color:
                    _dragging
                        ? _T.blue
                        : (_hovering ? _T.slate400 : _T.slate200),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLUMN ROW — shared by header and task rows
// Reads widths from _WidthScope. No animation controller needed — the
// notifier drives rebuilds, and AnimatedContainer handles smooth transitions.
// ─────────────────────────────────────────────────────────────────────────────
typedef _CellBuilder = Widget Function(_ColDef col);

class _ColRow extends StatelessWidget {
  final Set<String> effectiveVisible;
  final _CellBuilder builder;
  final bool includeBilling;
  final bool isDetailOpen;

  const _ColRow({
    super.key,
    required this.effectiveVisible,
    required this.builder,
    required this.isDetailOpen,
    this.includeBilling = true,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = _WidthScope.of(context);
    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        return Row(children: _buildCells(notifier));
      },
    );
  }

  List<Widget> _buildCells(_ColumnWidthNotifier notifier) {
    final result = <Widget>[];
    for (final col in _kCols) {
      final w = notifier.widthOf(col.id);
      final isVisible = effectiveVisible.contains(col.id);
      if (!isVisible && w < 1) continue;

      result.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: isVisible ? w : 0,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child:
              isVisible
                  ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
                    child: builder(col),
                  )
                  : const SizedBox.shrink(),
        ),
      );

      // Spacer for the resize handle width — keeps cells aligned with header
      if (col.id != _kBillingCol.id && !isDetailOpen) {
        result.add(const SizedBox(width: _kResizeHandleWidth));
      }
    }

    if (includeBilling) {
      final bw = notifier.widthOf(_kBillingCol.id);
      result.add(
        SizedBox(
          width: bw,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
            child: builder(_kBillingCol),
          ),
        ),
      );
    }

    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT HEADER
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
          _ViewToggle(
            current: viewMode,
            onChange: onViewModeChanged,
            selectedProjectId: activeProject?.id,
          ),
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
    if (status == ConnectionStatus.connected) return const SizedBox.shrink();

    Color color;
    IconData icon;
    String tooltip;

    switch (status) {
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        color = _T.amber;
        icon = Icons.cloud_sync;
        tooltip = 'Connecting...';
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
      default:
        color = _T.slate400;
        icon = Icons.cloud_off;
        tooltip = 'Offline';
    }

    return Tooltip(
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
              'Offline',
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
// VIEW TOGGLE
// ─────────────────────────────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final _ViewMode current;
  final ValueChanged<_ViewMode> onChange;
  final String? selectedProjectId;

  const _ViewToggle({
    required this.current,
    required this.onChange,
    required this.selectedProjectId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (kDebugMode && selectedProjectId != null)
          _ToggleTab(
            icon: Icons.timeline_outlined,
            label: 'Overview',
            isActive: current == _ViewMode.overview,
            onTap: () => onChange(_ViewMode.overview),
          ),
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
    final Color bg =
        widget.isActive ? _T.slate100 : (_hovered ? _T.slate100 : Colors.white);
    final Color iconColor =
        widget.isActive ? _T.blue : (_hovered ? _T.slate500 : _T.slate400);
    final Color textColor =
        widget.isActive ? _T.ink2 : (_hovered ? _T.ink3 : _T.slate500);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: iconColor),
              const SizedBox(width: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 120),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOOLBAR
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
      height: 40,
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _kRowHPad),
      child: Row(
        children: [
          if (singleProject)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(
                'Project column hidden while filtered',
                style: TextStyle(fontSize: 11, color: _T.slate400),
              ),
            ),
          const Spacer(),
          if (isDetailOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _T.slate100,
                borderRadius: BorderRadius.circular(_T.r),
                border: Border.all(color: _T.slate200),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_sidebar_outlined,
                    size: 13,
                    color: _T.slate400,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Showing core columns',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: _T.slate400,
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
    duration: const Duration(milliseconds: 190),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ac,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.05),
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
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? _overlay?.markNeedsBuild() : null,
      );
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
              offset: const Offset(0, 6),
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
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _open ? _T.slate100 : (hasCustom ? _T.blue50 : _T.white),
              border: Border.all(
                color:
                    _open
                        ? _T.slate300
                        : (hasCustom ? _T.blue.withOpacity(0.3) : _T.slate200),
              ),
              borderRadius: BorderRadius.circular(_T.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_column_outlined,
                  size: 14,
                  color: _open || hasCustom ? _T.blue : _T.slate400,
                ),
                const SizedBox(width: 6),
                Text(
                  'Columns',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _open || hasCustom ? _T.blue : _T.ink3,
                  ),
                ),
                if (optionalOnCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: hasCustom ? _T.blue : _T.slate200,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$optionalOnCount',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: hasCustom ? Colors.white : _T.slate500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 190),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: _T.slate400,
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
        width: 300,
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rLg),
          border: Border.all(color: _T.slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.slate100)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _T.blue50,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _T.blue.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.view_column_outlined,
                      size: 14,
                      color: _T.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Columns',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _T.ink,
                          ),
                        ),
                        Text(
                          'Customise what you see in the list',
                          style: TextStyle(fontSize: 10.5, color: _T.slate400),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _T.slate100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: _T.slate400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Always visible'),
                    const SizedBox(height: 8),
                    ...mandatoryCols.map((c) => _LockedColRow(col: c)),
                    _LockedColRow(
                      col: _kBillingCol,
                      trailingHint: 'Always last',
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: _T.slate100),
                    const SizedBox(height: 14),
                    _SectionLabel('Auto-managed'),
                    const SizedBox(height: 8),
                    _AutoColRow(
                      col: projectCol,
                      label:
                          singleProject
                              ? 'Hidden — project filter active'
                              : 'Visible — all projects shown',
                      active: !singleProject,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: _T.slate100),
                    const SizedBox(height: 14),
                    _SectionLabel('Optional columns'),
                    const SizedBox(height: 8),
                    ...optionalCols.map(
                      (c) => _ToggleColRow(
                        col: c,
                        enabled: visibleOptional.contains(c.id),
                        onTap: () => onToggle(c.id),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _T.slate100)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.restart_alt_rounded,
                    size: 13,
                    color: isDefault ? _T.slate300 : _T.slate400,
                  ),
                  const SizedBox(width: 6),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDefault ? _T.slate300 : _T.slate500,
                          decoration:
                              isDefault
                                  ? TextDecoration.none
                                  : TextDecoration.underline,
                          decorationColor: _T.slate400,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${optionalCols.where((c) => visibleOptional.contains(c.id)).length}/${optionalCols.length} optional',
                    style: const TextStyle(fontSize: 11, color: _T.slate400),
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
    padding: const EdgeInsets.only(bottom: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: active ? _T.blue50 : _T.slate50,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(
          color: active ? _T.blue.withOpacity(0.2) : _T.slate200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: active ? _T.blue.withOpacity(0.1) : _T.slate100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              col.icon,
              size: 13,
              color: active ? _T.blue : _T.slate400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  col.pickerLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? _T.ink : _T.ink3,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10.5, color: _T.slate400),
                ),
              ],
            ),
          ),
          Icon(
            active ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 13,
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
    padding: const EdgeInsets.only(bottom: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _T.slate50,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(col.icon, size: 13, color: _T.slate400),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              col.pickerLabel,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _T.ink3,
              ),
            ),
          ),
          if (trailingHint != null) ...[
            Text(
              trailingHint!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _T.slate400,
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.lock_outline_rounded, size: 12, color: _T.slate300),
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
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.enabled
                    ? _T.blue.withOpacity(0.05)
                    : (_hovering ? _T.slate50 : Colors.white),
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color:
                  widget.enabled
                      ? _T.blue.withOpacity(0.2)
                      : (_hovering ? _T.slate200 : Colors.white),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color:
                      widget.enabled ? _T.blue.withOpacity(0.1) : _T.slate100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  widget.col.icon,
                  size: 13,
                  color: widget.enabled ? _T.blue : _T.slate400,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.col.pickerLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: widget.enabled ? _T.ink : _T.ink3,
                      ),
                    ),
                    Text(
                      widget.col.description,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _T.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: _T.slate400,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK ROW
// ─────────────────────────────────────────────────────────────────────────────
class _TaskRow extends ConsumerStatefulWidget {
  final int taskId;
  final Project? project;
  final Member? assignee;
  final Set<String> effectiveVisible;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDetailOpen;

  const _TaskRow({
    required this.taskId,
    required this.project,
    required this.assignee,
    required this.effectiveVisible,
    required this.isSelected,
    required this.onTap,
    required this.isDetailOpen,
  });

  @override
  ConsumerState<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<_TaskRow> {
  bool _hovered = false;

  static const _completeBg = Color(0xFFF0FDF4);
  static const _completeMuted = Color.fromARGB(255, 31, 220, 129);
  static const _completeText = Color(0xFF166534);

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(taskByIdProviderSimple(widget.taskId))!;
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

    final Color rowColor =
        isCompleted
            ? (_hovered ? const Color(0xFFDCFCE7) : _completeBg)
            : widget.isSelected
            ? _T.blue50
            : _hovered
            ? _T.slate50
            : _T.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: rowColor,
          borderRadius: BorderRadius.circular(isCompleted ? 3 : _T.r),
          border:
              isCompleted
                  ? Border(left: BorderSide(color: _completeMuted, width: 2.75))
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_T.r),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(_T.r),
            child: Padding(
              padding: EdgeInsets.only(
                top: 11,
                bottom: 11,
                left: isCompleted ? 0 : 3,
              ),
              child: _ColRow(
                effectiveVisible: widget.effectiveVisible,
                isDetailOpen: widget.isDetailOpen,
                builder:
                    (col) => Opacity(
                      opacity: isCompleted ? 0.6 : 1.0,
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
            ? base.copyWith(color: _completeText.withOpacity(0.55))
            : base;

    return switch (col.id) {
      'task' => Row(
        children: [
          Expanded(
            child: Text(
              t.name,
              overflow: TextOverflow.ellipsis,
              style: completedBody(
                TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? _T.blue : _T.ink,
                ),
              ),
            ),
          ),
        ],
      ),

      'project' =>
        p != null
            ? Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color:
                        isCompleted ? _completeMuted.withOpacity(0.5) : p.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.name,
                    overflow: TextOverflow.ellipsis,
                    style: completedBody(
                      const TextStyle(fontSize: 12.5, color: _T.slate500),
                    ),
                  ),
                ),
              ],
            )
            : const Text('—', style: TextStyle(color: _T.slate300)),

      'ref' =>
        t.ref != null && t.ref!.isNotEmpty
            ? Text(
              t.ref!,
              overflow: TextOverflow.ellipsis,
              style: completedBody(
                const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _T.ink3,
                  fontFamily: 'monospace',
                ),
              ),
            )
            : const Text(
              '—',
              style: TextStyle(fontSize: 13, color: _T.slate300),
            ),

      'stage' =>
        isCompleted ? const _CompletedStagePill() : StagePill(stageInfo: s),

      'date' => Text(
        date,
        overflow: TextOverflow.ellipsis,
        style: completedBody(
          const TextStyle(fontSize: 12.5, color: _T.slate500),
        ),
      ),

      'priority' =>
        isCompleted
            ? Opacity(
              opacity: 0.45,
              child: SelectionPill(
                currentValue: t.priority,
                values: [
                  (TaskPriority.normal, _T.slate500, _T.slate100),
                  (TaskPriority.high, _T.amber, _T.amber50),
                  (TaskPriority.urgent, _T.red, _T.red50),
                ],
              ),
            )
            : SelectionPill(
              currentValue: t.priority,
              values: [
                (TaskPriority.normal, _T.slate500, _T.slate100),
                (TaskPriority.high, _T.amber, _T.amber50),
                (TaskPriority.urgent, _T.red, _T.red50),
              ],
            ),

      'size' =>
        t.size != null && !t.size!.contains("null")
            ? Text(
              t.size!,
              overflow: TextOverflow.ellipsis,
              style: completedBody(
                const TextStyle(fontSize: 12.5, color: _T.ink3),
              ),
            )
            : const Text(
              '—',
              style: TextStyle(fontSize: 13, color: _T.slate300),
            ),

      'qty' =>
        t.quantity != null
            ? Text(
              '${t.quantity}',
              overflow: TextOverflow.ellipsis,
              style: completedBody(
                const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _T.ink3,
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
                    size: 22,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    m.name,
                    overflow: TextOverflow.ellipsis,
                    style: completedBody(
                      const TextStyle(fontSize: 12.5, color: _T.slate500),
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

      // if (t.lastMessageId != null) ...[
      //       _MessageIndicator(
      //         count: t.unreadCount > 0 ? t.unreadCount : t.messageCount,
      //         dimmed: isCompleted,
      //         unread: t.unreadCount > 0,
      //       ),
      //       const SizedBox(width: 2),
      //     ],
      _ => const SizedBox.shrink(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE INDICATOR
// ─────────────────────────────────────────────────────────────────────────────
class _MessageIndicator extends StatelessWidget {
  final int count;
  final bool dimmed;
  final bool unread;

  const _MessageIndicator({
    required this.count,
    this.dimmed = false,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    final color = unread ? _T.blue : _T.ink3;
    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: Tooltip(
        message: '$count ${count == 1 ? 'message' : 'messages'}',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unread
                  ? Icons.mark_chat_unread
                  : Icons.chat_bubble_outline_rounded,
              size: 11,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) => const Text(
    'Completed',
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: Color(0xFF166534),
    ),
  );
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

    final String label = switch (status!) {
      BillingStatus.pending => '-',
      BillingStatus.invoiced => 'Invoiced',
      BillingStatus.foc => 'FOC',
      BillingStatus.cancelled => 'Cancelled',
      BillingStatus.quoteGiven => 'Quote',
    };

    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          overflow: TextOverflow.ellipsis,
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _T.slate100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            size: 24,
            color: _T.slate400,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No tasks yet',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _T.ink3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tasks you create will appear here',
          style: TextStyle(fontSize: 13, color: _T.slate400),
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
