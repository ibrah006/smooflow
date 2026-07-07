// ─────────────────────────────────────────────────────────────────────────────
// task_list_view.dart
//
// Latest implementation of the task list view notes:
//
// Task list view with RESIZABLE columns — now backed by the `material_table_view`
// package instead of a hand-rolled InheritedNotifier + ListView.
//
// Architecture change from the notifier-based version:
//   • Column widths now live in a plain `Map<String, double>` on the State
//     object (`_widths`), persisted the same way as before (SharedPreferences).
//   • The table itself (header + virtualized rows + horizontal/vertical
//     scrolling) is rendered by `TableView.builder` from material_table_view.
//   • Columns are represented to the package as a flat `List<TableColumn>`.
//     Because the package only understands "columns", the concepts that used
//     to be separate widgets (leading/trailing row padding, the resize-handle
//     gap between two data columns) are modelled as extra zero-content
//     "slot" columns (`_ColSlot`) at the same indices as `columns`, so header
//     and row cell builders can look up "what is at column index N" from one
//     shared list.
//   • Resizing is intentionally NOT done via the package's
//     TableColumnControlHandlesPopupRoute. Instead we keep the original,
//     simple drag-to-resize `_ResizeHandle` widget and just mutate `_widths`
//     in `setState`. TableView.builder is fully declarative, so handing it a
//     new `columns` list with an updated width on every frame of the drag is
//     all that's needed — this avoids the package's popup-route API (which
//     is oriented around an in-place "grab handle, resize or reorder" popup)
//     while giving us the exact same drag feel as before.
//   • IMPORTANT visual trade-off: material_table_view only allows
//     Opacity / ClipRRect / non-transparent Material inside row widgets when
//     NO column is frozen/sticky ("compositing restrictions", see package
//     docs). The original design relies on Opacity (completed-row dimming)
//     and rounded/clipped row backgrounds, so — to keep the look pixel
//     identical — the billing column is a normal scrolling column here, NOT
//     pinned via `freezePriority`/`sticky`. If you'd rather have billing
//     pinned to the trailing edge like the old comment mentions, you can set
//     `sticky: true, freezePriority: 1` on it, but you'll then need to drop
//     the Opacity/rounded-corner tricks in `_TaskRow` (swap Opacity for
//     color.withOpacity(...), and remove the ClipRRect/border-radius on the
//     row container) to stay within the package's compositing rules.
//   • All other behaviour (board view, connection indicator, column picker,
//     notifications, completed-row styling, toolbar) is unchanged.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_table_view/material_table_view.dart';
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

  // Row hover styling
  static const hoverBg = Color.fromARGB(255, 250, 250, 251);
  static const hoverBorder = Color.fromARGB(255, 189, 197, 207);

  // Priority colors (highest → lowest)
  static const priorityUrgent = Color(0xFFFF878A);
  static const priorityHigh = Color(0xFFFEA06A);
  static const priorityNormal = Color(0xFFF7BD51);

  // Column divider
  static const colDivider = Color(0xFFEDF0F3);

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
// PRIORITY HELPERS
// ─────────────────────────────────────────────────────────────────────────────
Color _priorityColor(TaskPriority p) => switch (p) {
  TaskPriority.urgent => _T.priorityUrgent,
  TaskPriority.high => _T.priorityHigh,
  TaskPriority.normal => _T.priorityNormal,
  _ => _T.slate400,
};

String _priorityLabel(TaskPriority p) => switch (p) {
  TaskPriority.urgent => 'Urgent',
  TaskPriority.high => 'High',
  TaskPriority.normal => 'Normal',
  _ => p.name,
};

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const double _kRowHPad = 16.0;
const double _kCellHPad = 8.0;
const double _kResizeHandleWidth = 8.0;
const double _kMinColWidth = 48.0;
const double _kMaxColWidth = 480.0;
const double _kRowHeight = 46.0;
const double _kHeaderHeight = 36.0;

const kNotificationDuration = Duration(seconds: 3);

abstract class _TableItem {}

class _SectionHeaderItem extends _TableItem {
  final TaskStatus status;
  final bool isExpanded;
  final int taskCount;

  _SectionHeaderItem(this.status, this.isExpanded, this.taskCount);
}

class _TaskRowItem extends _TableItem {
  final Task task;

  _TaskRowItem(this.task);
}

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

  /// Per-column minimum drag-resize width. Falls back to `_kMinColWidth`
  /// when not overridden — most columns are fine with that global floor,
  /// but a few (task name, project) need a larger floor to stay legible,
  /// and a few (qty) can safely go narrower.
  final double minWidth;

  const _ColDef({
    required this.id,
    required this.label,
    required this.pickerLabel,
    required this.description,
    required this.icon,
    required this.mandatory,
    required this.defaultOn,
    required this.defaultWidth,
    this.minWidth = _kMinColWidth,
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
    minWidth: 72,
  ),
  _ColDef(
    id: 'project',
    label: 'PROJECT',
    pickerLabel: 'Project',
    description: 'Colour-coded project name',
    icon: Icons.folder_outlined,
    mandatory: false,
    defaultOn: true,
    defaultWidth: 180,
    minWidth: 135,
  ),
  _ColDef(
    id: 'task',
    label: 'TASK',
    pickerLabel: 'Task Name',
    description: 'Task name',
    icon: Icons.drive_file_rename_outline_rounded,
    mandatory: true,
    defaultOn: true,
    defaultWidth: 290,
    minWidth: 255,
  ),
  _ColDef(
    id: 'ref',
    label: 'REF',
    pickerLabel: 'Reference',
    description: 'Client reference or PO number',
    icon: Icons.tag_rounded,
    mandatory: false,
    defaultOn: true,
    defaultWidth: 150,
    minWidth: 140,
  ),
  _ColDef(
    id: 'priority',
    label: 'PRIORITY',
    pickerLabel: 'Priority',
    description: 'Urgent / High / Normal priority pill',
    icon: Icons.flag_outlined,
    mandatory: false,
    defaultOn: true,
    defaultWidth: 110,
    minWidth: 98,
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
    minWidth: 72,
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
    minWidth: 40,
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
  minWidth: 100,
);

/// Looks up minWidth for any column id, including billing.
double _minWidthFor(String colId) =>
    [..._kCols, _kBillingCol].firstWhere((c) => c.id == colId).minWidth;

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
// COLUMN SLOTS
//
// material_table_view only knows about a flat `List<TableColumn>`. We keep a
// parallel `List<_ColSlot>` (same length, same order) so header/row cell
// builders know what to draw at a given column index: a real data column, a
// resize-handle gap between two data columns, or the fixed edge padding that
// used to be the ListView/Padding horizontal inset.
// ─────────────────────────────────────────────────────────────────────────────
enum _SlotType { column, resizeGap, edgePadding }

class _ColSlot {
  final _SlotType type;
  final String? colId;

  const _ColSlot.column(this.colId) : type = _SlotType.column;
  const _ColSlot.resizeGap(this.colId) : type = _SlotType.resizeGap;
  const _ColSlot.edgePadding() : type = _SlotType.edgePadding, colId = null;
}

class _BuiltColumns {
  final List<TableColumn> columns;
  final List<_ColSlot> slots;
  const _BuiltColumns(this.columns, this.slots);
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

  /// Current pixel widths per column id. Hidden optional columns simply
  /// don't appear in `_effectiveVisible`, so they're skipped when building
  /// the `columns` list — no need for a width-of-zero convention any more.
  Map<String, double> _widths = _defaultWidthMap();

  bool get _singleProject => widget.selectedProjectId != null;

  int? lastNotifiedTaskId;
  DateTime? lastNotificationTime;

  Set<String> get _effectiveVisible {
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
    _widths = _defaultWidthMap();
    _loadPrefs();
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
      _widths = {..._widths, ...map};
      // Guard against stale/saved widths that predate a column's current
      // minimum (e.g. min was raised in a later app version).
      for (final id in _widths.keys.toList()) {
        // Deprecated - no longer using this.
        if (id == 'stage') continue;

        final min = _minWidthFor(id);
        if (_widths[id]! < min) _widths[id] = min;
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _saveColPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(_visibleOptional.toList()));
  }

  Future<void> _saveWidths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kColWidthsKey, jsonEncode(_widths));
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
      } else {
        _visibleOptional.add(id);
        // Make sure a freshly-shown column has a sane, in-bounds width.
        _widths.putIfAbsent(id, () {
          final col = _kCols.firstWhere((c) => c.id == id);
          return col.defaultWidth < col.minWidth
              ? col.minWidth
              : col.defaultWidth;
        });
      }
    });
    _saveColPrefs();
    _saveWidths();
  }

  void _resetToDefaults() {
    setState(() {
      _visibleOptional = Set.from(_kDefaultOptionalOn);
      _widths = _defaultWidthMap();
    });
    _saveColPrefs();
    _saveWidths();
  }

  void _setViewMode(_ViewMode mode) {
    if (_viewMode == mode) return;
    setState(() => _viewMode = mode);
    _saveViewMode();
  }

  void _resizeColumn(String id, double delta) {
    setState(() {
      final w = (_widths[id] ?? 100) + delta;
      _widths[id] = w.clamp(_minWidthFor(id), _kMaxColWidth);
    });
  }

  void _loadTasks() {
    final filters = <String, dynamic>{};
    if (widget.selectedProjectId != null) {
      filters['projectId'] = widget.selectedProjectId;
    }
    ref.read(taskNotifierProvider.notifier).loadTasks(filters: filters);
  }

  /// Builds the flat column list (+ parallel slot list) that
  /// `TableView.builder` and our cell builders share.
  _BuiltColumns _buildColumns(Set<String> effective) {
    final columns = <TableColumn>[];
    final slots = <_ColSlot>[];

    // Leading edge padding (used to be the ListView/Padding horizontal inset).
    columns.add(const TableColumn(width: _kRowHPad));
    slots.add(const _ColSlot.edgePadding());

    final visibleCols = _kCols.where((c) => effective.contains(c.id)).toList();
    for (var i = 0; i < visibleCols.length; i++) {
      final c = visibleCols[i];
      columns.add(TableColumn(width: _widths[c.id] ?? c.defaultWidth));
      slots.add(_ColSlot.column(c.id));

      if (!widget.isDetailOpen) {
        columns.add(const TableColumn(width: _kResizeHandleWidth));
        slots.add(_ColSlot.resizeGap(c.id));
      }
    }

    // Billing column — always visible, always last data column.
    columns.add(
      TableColumn(width: _widths[_kBillingCol.id] ?? _kBillingCol.defaultWidth),
    );
    slots.add(_ColSlot.column(_kBillingCol.id));

    // Trailing edge padding.
    columns.add(const TableColumn(width: _kRowHPad));
    slots.add(const _ColSlot.edgePadding());

    return _BuiltColumns(columns, slots);
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

    final Project? selectedProject =
        widget.selectedProjectId != null
            ? ref.read(projectByIdProvider(widget.selectedProjectId!))
            : null;

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
          else if (_viewMode == _ViewMode.overview)
            Expanded(
              child: DesktopProjectOverviewScreen(
                selectedProjectId: widget.selectedProjectId,
                project: selectedProject,
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
                      : _TaskTable(
                        effective: effective,
                        tasks: reversedTasks,
                        projects: widget.projects,
                        members: members,
                        isDetailOpen: widget.isDetailOpen,
                        selectedTaskId: widget.selectedTaskId,
                        onTaskSelected: widget.onTaskSelected,
                        buildColumns: _buildColumns,
                        onResizeColumn: _resizeColumn,
                        onResizeEnd: _saveWidths,
                        onAddTask:
                            widget.onAddTask, // Added forwarding reference
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
// TASK TABLE — wraps material_table_view's TableView.builder
// ─────────────────────────────────────────────────────────────────────────────
class _TaskTable extends ConsumerStatefulWidget {
  final Set<String> effective;
  final List<Task> tasks;
  final List<Project> projects;
  final List<Member> members;
  final bool isDetailOpen;
  final int? selectedTaskId;
  final Function(int taskId, String detailPanelProjectId) onTaskSelected;
  final _BuiltColumns Function(Set<String> effective) buildColumns;
  final void Function(String colId, double delta) onResizeColumn;
  final VoidCallback onResizeEnd;
  final VoidCallback? onAddTask;

  const _TaskTable({
    required this.effective,
    required this.tasks,
    required this.projects,
    required this.members,
    required this.isDetailOpen,
    required this.selectedTaskId,
    required this.onTaskSelected,
    required this.buildColumns,
    required this.onResizeColumn,
    required this.onResizeEnd,
    this.onAddTask,
  });

  @override
  ConsumerState<_TaskTable> createState() => _TaskTableState();
}

class _TaskTableState extends ConsumerState<_TaskTable> {
  final Set<TaskStatus> _collapsedStatuses = {};

  @override
  Widget build(BuildContext context) {
    final built = widget.buildColumns(widget.effective);
    final columns = built.columns;
    final slots = built.slots;

    // Dynamically segregate tasks into sections based on task status
    final List<_TableItem> tableItems = [];
    for (final status in TaskStatus.values) {
      final statusTasks =
          widget.tasks.where((t) => t.status == status).toList();
      final isCollapsed = _collapsedStatuses.contains(status);

      tableItems.add(
        _SectionHeaderItem(status, !isCollapsed, statusTasks.length),
      );

      if (!isCollapsed) {
        for (final task in statusTasks) {
          tableItems.add(_TaskRowItem(task));
        }
      }
    }

    return Container(
      color: _T.white,
      child: TableView.builder(
        columns: columns,
        rowCount: tableItems.length,
        rowHeight: _kRowHeight,
        headerHeight: _kHeaderHeight,
        headerBuilder:
            (context, contentBuilder) => Column(
              children: [
                SizedBox(
                  height: _kHeaderHeight - 1,
                  child: contentBuilder(
                    context,
                    (context, column) => _headerCell(
                      slots,
                      column,
                      widget.isDetailOpen,
                      widget.onResizeColumn,
                      widget.onResizeEnd,
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: _T.slate200),
              ],
            ),
        rowBuilder: (context, row, contentBuilder) {
          final item = tableItems[row];

          // Render Section Header Item
          if (item is _SectionHeaderItem) {
            return _StatusSectionHeader(
              status: item.status,
              isExpanded: item.isExpanded,
              taskCount: item.taskCount,
              onToggle: () {
                setState(() {
                  if (_collapsedStatuses.contains(item.status)) {
                    _collapsedStatuses.remove(item.status);
                  } else {
                    _collapsedStatuses.add(item.status);
                  }
                });
              },
              onAddTask: widget.onAddTask,
            );
          }

          // Render Normal Task Row Item
          final t = (item as _TaskRowItem).task;
          final p =
              widget.projects.cast<Project?>().firstWhere(
                (pr) => pr!.id == t.projectId.toString(),
                orElse: () => null,
              ) ??
              widget.projects.firstOrNull;

          Member? m;
          try {
            m = widget.members.firstWhere(
              (mem) => t.assignees.contains(mem.id),
            );
          } catch (_) {
            m = null;
          }

          return _TaskRow(
            key: ValueKey(t.id),
            taskId: t.id,
            project: p,
            assignee: m,
            slots: slots,
            isSelected: widget.selectedTaskId == t.id,
            onTap: () => widget.onTaskSelected(t.id, t.projectId),
            contentBuilder: contentBuilder,
          );
        },
      ),
    );
  }
}

Widget _headerCell(
  List<_ColSlot> slots,
  int column,
  bool isDetailOpen,
  void Function(String colId, double delta) onResizeColumn,
  VoidCallback onResizeEnd,
) {
  final slot = slots[column];

  switch (slot.type) {
    case _SlotType.edgePadding:
      return const SizedBox.shrink();

    case _SlotType.resizeGap:
      if (isDetailOpen) return const SizedBox.shrink();
      return _ResizeHandle(
        colId: slot.colId!,
        onResize: onResizeColumn,
        onResizeEnd: onResizeEnd,
      );

    case _SlotType.column:
      final col = [
        ..._kCols,
        _kBillingCol,
      ].firstWhere((c) => c.id == slot.colId);
      return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: _T.colDivider, width: 1)),
        ),
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
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESIZE HANDLE — plain drag handle, mutates parent state directly.
// ─────────────────────────────────────────────────────────────────────────────
class _ResizeHandle extends StatefulWidget {
  final String colId;
  final void Function(String colId, double delta) onResize;
  final VoidCallback onResizeEnd;

  const _ResizeHandle({
    required this.colId,
    required this.onResize,
    required this.onResizeEnd,
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
        onHorizontalDragUpdate:
            (details) => widget.onResize(widget.colId, details.delta.dx),
        onHorizontalDragEnd: (_) {
          setState(() => _dragging = false);
          widget.onResizeEnd();
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
// PRIORITY DROPDOWN CELL
//
// Replaces the old SelectionPill-based priority cell. Shows the current
// priority as a small colored pill; on hover a chevron appears on the far
// right of the cell. Tapping anywhere in the cell opens a dropdown menu
// (anchored under the cell) to change the priority.
// ─────────────────────────────────────────────────────────────────────────────
class _PriorityDropdownCell extends ConsumerStatefulWidget {
  final int taskId;
  final TaskPriority priority;
  final bool dimmed;

  const _PriorityDropdownCell({
    required this.taskId,
    required this.priority,
    this.dimmed = false,
  });

  @override
  ConsumerState<_PriorityDropdownCell> createState() =>
      _PriorityDropdownCellState();
}

class _PriorityDropdownCellState extends ConsumerState<_PriorityDropdownCell> {
  bool _hovering = false;
  final GlobalKey _anchorKey = GlobalKey();

  static const _options = [
    TaskPriority.urgent,
    TaskPriority.high,
    TaskPriority.normal,
  ];

  Future<void> _openMenu() async {
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final topLeft = renderObject.localToGlobal(
      Offset(0, renderObject.size.height + 4),
      ancestor: overlay,
    );
    final bottomRight = renderObject.localToGlobal(
      Offset(renderObject.size.width + 8, renderObject.size.height + 4),
      ancestor: overlay,
    );

    final selected = await showMenu<TaskPriority>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        overlay.size.width - bottomRight.dx,
        0,
      ),
      color: _T.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_T.r),
        side: const BorderSide(color: _T.slate200),
      ),
      constraints: const BoxConstraints(minWidth: 140),
      items:
          _options.map((p) {
            final active = p == widget.priority;
            final color = _priorityColor(p);
            return PopupMenuItem<TaskPriority>(
              value: p,
              height: 40,
              child: Row(
                children: [
                  // Updated to mirror the main cell's color-dominant block appearance
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      _priorityLabel(p),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color:
                            Colors
                                .black54, // Matches cell's signature dark text contrast
                      ),
                    ),
                  ),
                  Spacer(),
                  // An alignment-preserving structural layout block for selection feedback
                  Opacity(
                    opacity: active ? 1.0 : 0.0,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: _T.blue,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );

    if (selected != null && selected != widget.priority) {
      // NOTE: adjust this call to match your actual task-update API.
      // ref
      //     .read(taskNotifierProvider.notifier)
      //     .updateTaskPriority(widget.taskId, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(widget.priority);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        key: _anchorKey,
        behavior: HitTestBehavior.opaque,
        onTap: _openMenu,
        child: Opacity(
          opacity: widget.dimmed ? 0.45 : 1.0,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: color),
                ),
                child: Text(
                  _priorityLabel(widget.priority),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
              Spacer(),
              if (_hovering)
                const Padding(
                  key: ValueKey('chevron'),
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: Colors.black54,
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
// Billing DROPDOWN CELL
//
// Replaces the old SelectionPill-based priority cell. Shows the current
// priority as a small colored pill; on hover a chevron appears on the far
// right of the cell. Tapping anywhere in the cell opens a dropdown menu
// (anchored under the cell) to change the priority.
// ─────────────────────────────────────────────────────────────────────────────
class _BillingDropdownCell extends ConsumerStatefulWidget {
  final int taskId;
  final BillingStatus billing;
  final bool dimmed;

  const _BillingDropdownCell({
    required this.taskId,
    required this.billing,
    this.dimmed = false,
  });

  @override
  ConsumerState<_BillingDropdownCell> createState() =>
      _BillingDropdownCellState();
}

class _BillingDropdownCellState extends ConsumerState<_BillingDropdownCell> {
  bool _hovering = false;
  final GlobalKey _anchorKey = GlobalKey();

  static const _options = [
    BillingStatus.cancelled,
    BillingStatus.foc,
    BillingStatus.invoiced,
    BillingStatus.quoteGiven,
  ];

  Future<void> _openMenu() async {
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final topLeft = renderObject.localToGlobal(
      Offset(0, renderObject.size.height + 4),
      ancestor: overlay,
    );
    final bottomRight = renderObject.localToGlobal(
      Offset(renderObject.size.width + 8, renderObject.size.height + 4),
      ancestor: overlay,
    );

    final selected = await showMenu<BillingStatus>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        overlay.size.width - bottomRight.dx,
        0,
      ),
      color: _T.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_T.r),
        side: const BorderSide(color: _T.slate200),
      ),
      constraints: const BoxConstraints(minWidth: 140),
      items: [
        PopupMenuItem<BillingStatus>(
          value: BillingStatus.pending,
          height: 40,
          child: Row(
            children: [
              SizedBox(width: 5),
              const Text(
                '—',
                style: TextStyle(fontSize: 15, color: _T.slate300),
              ),
              // Updated to mirror the main cell's color-dominant block appearance
              Spacer(),
              // An alignment-preserving structural layout block for selection feedback
              Opacity(
                opacity: widget.billing == BillingStatus.pending ? 1.0 : 0.0,
                child: const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Icon(Icons.check_rounded, size: 15, color: _T.blue),
                ),
              ),
            ],
          ),
        ),
        ..._options.map((b) {
          final active = b == widget.billing;
          final color = b.color;
          return PopupMenuItem<BillingStatus>(
            value: b,
            height: 40,
            child: Row(
              children: [
                // Updated to mirror the main cell's color-dominant block appearance
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    b.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color:
                          Colors
                              .black54, // Matches cell's signature dark text contrast
                    ),
                  ),
                ),
                Spacer(),
                // An alignment-preserving structural layout block for selection feedback
                Opacity(
                  opacity: active ? 1.0 : 0.0,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(Icons.check_rounded, size: 15, color: _T.blue),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );

    if (selected != null && selected != widget.billing) {
      // NOTE: adjust this call to match your actual task-update API.
      // ref
      //     .read(taskNotifierProvider.notifier)
      //     .updateTaskPriority(widget.taskId, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.billing.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        key: _anchorKey,
        behavior: HitTestBehavior.opaque,
        onTap: _openMenu,
        child: Opacity(
          opacity: widget.dimmed ? 0.45 : 1.0,
          child: Row(
            children: [
              if (widget.billing == BillingStatus.pending)
                const Text(
                  '—',
                  style: TextStyle(fontSize: 12, color: _T.slate300),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    widget.billing.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.billing.textColor,
                    ),
                  ),
                ),
              Spacer(),
              if (_hovering)
                Padding(
                  key: ValueKey('chevron'),
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: widget.billing.textColor,
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
// TASK ROW
//
// Now receives the `contentBuilder` handed to us by TableView.builder's
// rowBuilder, instead of doing its own column layout via _ColRow.
// ─────────────────────────────────────────────────────────────────────────────
class _TaskRow extends ConsumerStatefulWidget {
  final int taskId;
  final Project? project;
  final Member? assignee;
  final List<_ColSlot> slots;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget Function(
    BuildContext context,
    Widget Function(BuildContext context, int column) cellBuilder,
  )
  contentBuilder;

  const _TaskRow({
    super.key,
    required this.taskId,
    required this.project,
    required this.assignee,
    required this.slots,
    required this.isSelected,
    required this.onTap,
    required this.contentBuilder,
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
            ? _T.hoverBg
            : _T.white;

    final bool showHoverBorder = _hovered && !isCompleted && !widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          decoration: BoxDecoration(
            color: rowColor,
            border: Border(
              top:
                  showHoverBorder
                      ? const BorderSide(color: _T.hoverBorder, width: .85)
                      : BorderSide.none,
              bottom: BorderSide(
                color: showHoverBorder ? _T.hoverBorder : _T.slate100,
                width: showHoverBorder ? .85 : .85,
              ),
              left:
                  isCompleted
                      ? const BorderSide(color: _completeMuted, width: 2.75)
                      : BorderSide.none,
            ),
          ),
          child: widget.contentBuilder(
            context,
            (context, column) => _cellFor(
              widget.slots[column],
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
    );
  }

  Widget _cellFor(
    _ColSlot slot,
    Task t,
    Project? p,
    Member? m,
    dynamic s,
    String date, {
    required bool isCompleted,
  }) {
    if (slot.type == _SlotType.edgePadding ||
        slot.type == _SlotType.resizeGap) {
      return const SizedBox.shrink();
    }

    final colId = slot.colId!;

    // NOTE: because a frozen/sticky column is NOT used here, Opacity is safe
    // to use inside row cells. If you later pin the billing column via
    // `sticky: true, freezePriority: ...`, replace these Opacity wrappers
    // with `color.withOpacity(...)` on the relevant text/icon colors instead.
    TextStyle completedBody(TextStyle base) =>
        isCompleted
            ? base.copyWith(color: _completeText.withOpacity(0.55))
            : base;

    final content = switch (colId) {
      'task' => Row(
        children: [
          Flexible(
            child: Text(
              t.name,
              overflow: TextOverflow.ellipsis,
              style: completedBody(
                TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _T.ink,
                ),
              ),
            ),
          ),
          if (t.messageCount > 0) ...[
            const SizedBox(width: 6),
            Opacity(
              opacity: isCompleted ? 0.6 : 1.0,
              child: _MessageIndicator(count: t.messageCount, unread: false),
            ),
          ],
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

      'priority' => _PriorityDropdownCell(
        taskId: t.id,
        priority: t.priority,
        dimmed: isCompleted,
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

      'billing' => _BillingDropdownCell(
        taskId: t.id,
        billing: t.billingStatus,
        dimmed: isCompleted,
      ),

      // _BillingStatusCell(
      //   status: t.billingStatus,
      //   dimmed: isCompleted,
      // ),
      _ => const SizedBox.shrink(),
    };

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
      width: double.infinity,
      height: _kRowHeight,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: _T.colDivider, width: 1)),
      ),
      child: Opacity(opacity: isCompleted ? 0.6 : 1.0, child: content),
    );
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
    final color = unread ? _T.blue : _T.slate400;
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
              size: 12,
              color: color,
            ),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
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

class _StatusSectionHeader extends StatefulWidget {
  final TaskStatus status;
  final bool isExpanded;
  final int taskCount;
  final VoidCallback onToggle;
  final VoidCallback? onAddTask;

  const _StatusSectionHeader({
    required this.status,
    required this.isExpanded,
    required this.taskCount,
    required this.onToggle,
    this.onAddTask,
  });

  @override
  State<_StatusSectionHeader> createState() => _StatusSectionHeaderState();
}

class _StatusSectionHeaderState extends State<_StatusSectionHeader> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Generate clean human-readable name from enum value
    // final name = widget.status.name;
    final statusLabel = widget.status.displayName;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: _kRowHeight,
        decoration: const BoxDecoration(
          color: _T.slate100,
          border: Border(
            bottom: BorderSide(color: _T.slate200, width: 1),
            top: BorderSide(color: _T.slate200, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: _kRowHPad),
        child: Row(
          children: [
            // Collapse / Expand interactive chevron button
            GestureDetector(
              onTap: widget.onToggle,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: AnimatedRotation(
                    turns: widget.isExpanded ? 0.0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: _T.slate600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Section Status Title
            Text(
              statusLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _T.ink2,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 8),
            // Dynamic task counter pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: _T.slate200,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${widget.taskCount}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _T.slate500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Add action icon button appearing on hover
            AnimatedOpacity(
              opacity: _isHovered && widget.onAddTask != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: GestureDetector(
                onTap: _isHovered ? widget.onAddTask : null,
                child: MouseRegion(
                  cursor:
                      _isHovered
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _T.white,
                      shape: BoxShape.circle,
                      boxShadow: [_T.shadowSm],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: _T.blue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
bool _setsEqual(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
