// ─────────────────────────────────────────────────────────────────────────────
// task_list_view.dart
//
// Changes:
//   • Project column is hidden when a single project is selected (filter active).
//   • A header bar at the top shows the active project name (or "All Projects").
//   • List / Board toggle tabs live in this header bar — sidebar no longer
//     switches between these two views.
//   • BoardView is embedded as a sub-view when the Board tab is active.
//   • All previous animated column / column-picker behaviour is preserved.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/board_view.dart';
import 'package:smooflow/screens/desktop/components/priority_pill.dart';
import 'package:smooflow/screens/desktop/components/stage_pill.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';
import 'package:smooflow/enums/billing_status.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue      = Color(0xFF2563EB);
  static const blue50    = Color(0xFFEFF6FF);
  static const green     = Color(0xFF10B981);
  static const amber     = Color(0xFFF59E0B);
  static const red       = Color(0xFFEF4444);
  static const purple    = Color(0xFF8B5CF6);
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
  static const r         = 8.0;
  static const rLg       = 12.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT
// ─────────────────────────────────────────────────────────────────────────────
const double _kRowHPad   = 16.0;
const double _kCellHPad  = 4.0;
const _kColAnimDuration  = Duration(milliseconds: 260);

// ─────────────────────────────────────────────────────────────────────────────
// VIEW MODE
// ─────────────────────────────────────────────────────────────────────────────
enum _ViewMode { list, board }

// ─────────────────────────────────────────────────────────────────────────────
// COLUMN DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────────
class _ColDef {
  final String   id;
  final String   label;
  final String   pickerLabel;
  final String   description;
  final IconData icon;
  final bool     mandatory;
  final bool     defaultOn;
  final int      flex;

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
    id: 'date', label: 'DATE', pickerLabel: 'Date Created',
    description: 'Date the task was created',
    icon: Icons.calendar_today_outlined,
    mandatory: true, defaultOn: true, flex: 1,
  ),
  _ColDef(
    id: 'project', label: 'PROJECT', pickerLabel: 'Project',
    description: 'Colour-coded project name',
    icon: Icons.folder_outlined,
    mandatory: false, defaultOn: true, flex: 2,
  ),
  _ColDef(
    id: 'task', label: 'TASK', pickerLabel: 'Task Name',
    description: 'Task name',
    icon: Icons.drive_file_rename_outline_rounded,
    mandatory: true, defaultOn: true, flex: 3,
  ),
  _ColDef(
    id: 'ref', label: 'REF', pickerLabel: 'Reference',
    description: 'Client reference or PO number',
    icon: Icons.tag_rounded,
    mandatory: true, defaultOn: true, flex: 3,
  ),
  _ColDef(
    id: 'stage', label: 'STAGE', pickerLabel: 'Stage',
    description: 'Current pipeline stage pill',
    icon: Icons.view_kanban_outlined,
    mandatory: true, defaultOn: true, flex: 2,
  ),
  _ColDef(
    id: 'priority', label: 'PRIORITY', pickerLabel: 'Priority',
    description: 'Urgent / High / Normal priority pill',
    icon: Icons.flag_outlined,
    mandatory: false, defaultOn: true, flex: 1,
  ),
  _ColDef(
    id: 'size', label: 'SIZE', pickerLabel: 'Size',
    description: 'Print dimensions (W × H cm)',
    icon: Icons.straighten_outlined,
    mandatory: false, defaultOn: false, flex: 2,
  ),
  _ColDef(
    id: 'qty', label: 'QTY', pickerLabel: 'Quantity',
    description: 'Number of printed pieces',
    icon: Icons.inventory_2_outlined,
    mandatory: false, defaultOn: false, flex: 2,
  ),
];

const _kBillingCol = _ColDef(
  id: 'billing', label: 'BILLING', pickerLabel: 'Billing Status',
  description: 'Invoice and payment status',
  icon: Icons.receipt_long_outlined,
  mandatory: true, defaultOn: true, flex: 1,
);

Set<String> get _kDefaultOptionalOn => _kCols
    .where((c) => !c.mandatory && c.defaultOn)
    .map((c) => c.id)
    .toSet();

Set<String> get _kMandatoryIds => _kCols
    .where((c) => c.mandatory)
    .map((c) => c.id)
    .toSet();

const _kPrefsKey     = 'smooflow.task_list.visible_optional_cols';
const _kViewModeKey  = 'smooflow.task_list.view_mode';

// ─────────────────────────────────────────────────────────────────────────────
// TASK LIST VIEW
// ─────────────────────────────────────────────────────────────────────────────
class TaskListView extends ConsumerStatefulWidget {
  final List<Project>     projects;
  final String?           selectedProjectId;   // null = "All Projects"
  final int?              selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  final bool              isDetailOpen;

  // Board view pass-through props
  final VoidCallback?     onAddTask;
  final FocusNode?        addTaskFocusNode;
  final bool              isAddingTask;

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
  Set<String>  _visibleOptional = {};
  _ViewMode    _viewMode        = _ViewMode.list;

  // ── Derived: are we in single-project mode? ────────────────────────────────
  bool get _singleProject => widget.selectedProjectId != null;

  /// When the detail panel is open only 'date' and 'task' are shown so the
  /// list columns don't compete with the panel for space. The full column
  /// state is restored the moment the panel closes — nothing is mutated,
  /// this is purely derived from widget.isDetailOpen.
  static const _kDetailCols = {'date', 'task'};

  Set<String> get _effectiveVisible {
    final base = widget.isDetailOpen
        ? _kDetailCols
        : {..._kMandatoryIds, ..._visibleOptional};

    if (_singleProject) {
      // Strip 'project' from whatever is showing
      return base.difference({'project'});
    }
    return base;
  }

  Project? get _activeProject => widget.selectedProjectId == null
      ? null
      : widget.projects.cast<Project?>().firstWhere(
            (p) => p!.id == widget.selectedProjectId,
            orElse: () => null,
          );

  // ── Persistence ────────────────────────────────────────────────────────────
  @override
  void `initState`() {
    super.initState();
    _visibleOptional = Set.from(_kDefaultOptionalOn);

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(taskListProvider.notifier).loadTasks();
    // });
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Column prefs
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<String>();
      if (mounted) setState(() => _visibleOptional = Set.from(list));
    } else {
      await _saveColPrefs();
    }

    // View mode pref
    final vm = prefs.getString(_kViewModeKey);
    if (vm != null && mounted) {
      setState(() => _viewMode = vm == 'board' ? _ViewMode.board : _ViewMode.list);
    }
  }

  Future<void> _saveColPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(_visibleOptional.toList()));
  }

  Future<void> _saveViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kViewModeKey, _viewMode == _ViewMode.board ? 'board' : 'list');
  }

  void _toggleColumn(String id) {
    setState(() => _visibleOptional.contains(id)
        ? _visibleOptional.remove(id)
        : _visibleOptional.add(id));
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

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final members   = ref.watch(memberNotifierProvider).members;
    final taskState = ref.watch(taskListProvider);
    final tasks     = taskState.tasks.reversed.toList();
    final effective = _effectiveVisible;

    return Container(
      color: _T.slate50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Project header + view mode tabs ──────────────────────────────
          _ProjectHeader(
            activeProject:   _activeProject,
            viewMode:        _viewMode,
            onViewModeChanged: _setViewMode,
          ),

          // ── Board sub-view ───────────────────────────────────────────────
          if (_viewMode == _ViewMode.board)
            Expanded(
              child: BoardView(
                tasks:               taskState.tasks,
                projects:            widget.projects,
                selectedTaskId:      widget.selectedTaskId,
                onTaskSelected:      widget.onTaskSelected,
                onAddTask:           widget.onAddTask ?? () {},
                addTaskFocusNode:    widget.addTaskFocusNode ?? FocusNode(),
                isAddingTask:        widget.isAddingTask,
                selectedProjectId:   widget.selectedProjectId,
              ),
            )
          else ...[
            // ── Toolbar (column picker) ─────────────────────────────────
            _Toolbar(
              visibleOptional:  _visibleOptional,
              isDetailOpen:     widget.isDetailOpen,
              singleProject:    _singleProject,
              onToggle:         _toggleColumn,
              onReset:          _resetToDefaults,
            ),

            // ── Column header row ────────────────────────────────────────
            Container(
              color: _T.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(_kRowHPad, 8, _kRowHPad, 8),
                    child: _AnimatedColRow(
                      effectiveVisible:  effective,
                      pinnedTrailingCol: _kBillingCol,
                      builder: (col, animFraction) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
                        child: Opacity(
                          opacity: animFraction,
                          child: Text(
                            col.label,
                            style: const TextStyle(
                              fontSize:      10.5,
                              fontWeight:    FontWeight.w700,
                              letterSpacing: 0.7,
                              color:         _T.slate400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: _T.slate200),
                ],
              ),
            ),

            // ── Data rows ──────────────────────────────────────────────
            Expanded(
              child: tasks.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _kRowHPad,
                        vertical:   8,
                      ),
                      itemCount:        tasks.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, thickness: 1, color: _T.slate100),
                      itemBuilder: (_, i) {
                        final t = tasks[i];
                        final p = widget.projects
                                .cast<Project?>()
                                .firstWhere(
                                  (pr) => pr!.id == t.projectId,
                                  orElse: () => null,
                                ) ??
                            widget.projects.firstOrNull;

                        Member? m;
                        try {
                          m = members.firstWhere(
                              (mem) => t.assignees.contains(mem.id));
                        } catch (_) {
                          m = null;
                        }

                        return _TaskRow(
                          task:              t,
                          project:           p,
                          assignee:          m,
                          effectiveVisible:  effective,
                          isSelected:        widget.selectedTaskId == t.id,
                          onTap:             () => widget.onTaskSelected(t.id),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT HEADER
//
// Shows the active project name (or "All Projects") with its colour dot, plus
// the List / Board view-mode toggle tabs on the trailing edge.
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectHeader extends StatelessWidget {
  final Project?                   activeProject;
  final _ViewMode                  viewMode;
  final ValueChanged<_ViewMode>    onViewModeChanged;

  const _ProjectHeader({
    required this.activeProject,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isFiltered = activeProject != null;

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color:  _T.white,
        border: Border(bottom: BorderSide(color: _T.slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _kRowHPad),
      child: Row(
        children: [
          // ── Project indicator ─────────────────────────────────────────
          if (isFiltered) ...[
            Container(
              width:  9,
              height: 9,
              decoration: BoxDecoration(
                color:  activeProject!.color,
                shape:  BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              activeProject!.name,
              style: const TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color:      _T.ink,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color:        _T.slate100,
                borderRadius: BorderRadius.circular(99),
                border:       Border.all(color: _T.slate200),
              ),
              child: const Text(
                'Filtered',
                style: TextStyle(
                  fontSize:   10,
                  fontWeight: FontWeight.w600,
                  color:      _T.slate500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ] else ...[
            const Icon(Icons.folder_open_outlined, size: 15, color: _T.slate400),
            const SizedBox(width: 8),
            const Text(
              'All Projects',
              style: TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color:      _T.ink,
                letterSpacing: -0.2,
              ),
            ),
          ],

          const Spacer(),

          // ── View mode toggle ──────────────────────────────────────────
          _ViewToggle(
            current:  viewMode,
            onChange: onViewModeChanged,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW TOGGLE  (List / Board pill tabs)
// ─────────────────────────────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final _ViewMode             current;
  final ValueChanged<_ViewMode> onChange;

  const _ViewToggle({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color:        _T.slate100,
        borderRadius: BorderRadius.circular(_T.r),
        border:       Border.all(color: _T.slate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleTab(
            icon:      Icons.list_alt_outlined,
            label:     'List',
            isActive:  current == _ViewMode.list,
            isFirst:   true,
            onTap:     () => onChange(_ViewMode.list),
          ),
          _ToggleTab(
            icon:      Icons.view_kanban_outlined,
            label:     'Board',
            isActive:  current == _ViewMode.board,
            isFirst:   false,
            onTap:     () => onChange(_ViewMode.board),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatefulWidget {
  final IconData     icon;
  final String       label;
  final bool         isActive;
  final bool         isFirst;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isFirst,
    required this.onTap,
  });

  @override
  State<_ToggleTab> createState() => _ToggleTabState();
}

class _ToggleTabState extends State<_ToggleTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.isFirst
        ? const BorderRadius.horizontal(left: Radius.circular(7))
        : const BorderRadius.horizontal(right: Radius.circular(7));

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isActive
                  ? _T.white
                  : (_hovered ? _T.slate50 : Colors.transparent),
            borderRadius: radius,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: widget.isActive
                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
                  : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                widget.icon,
                size:  13,
                color: widget.isActive ? _T.blue : _T.slate400,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize:   11.5,
                  fontWeight: FontWeight.w600,
                  color:      widget.isActive ? _T.ink : _T.slate500,
                ),
              ),
            ]),
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
  final Set<String>     effectiveVisible;
  final _ColCellBuilder builder;
  final _ColDef?        pinnedTrailingCol;

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
  Map<String, double> _prevWidths   = {};
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
    final visibleCols = _kCols.where((c) => widget.effectiveVisible.contains(c.id)).toList();
    final totalFlex   = visibleCols.fold<int>(0, (s, c) => s + c.flex) + p.flex;
    return totalFlex > 0 ? (p.flex / totalFlex) * availWidth : 0;
  }

  Map<String, double> _computeTargets(double availWidth) {
    final animAvail   = availWidth - _pinnedWidth(availWidth);
    final visibleCols = _kCols.where((c) => widget.effectiveVisible.contains(c.id)).toList();
    final totalFlex   = visibleCols.fold<int>(0, (s, c) => s + c.flex);
    final result      = <String, double>{};
    for (final col in _kCols) {
      result[col.id] = (widget.effectiveVisible.contains(col.id) && totalFlex > 0)
          ? (col.flex / totalFlex) * animAvail
          : 0;
    }
    return result;
  }

  void _startTransition(double availWidth) {
    final newTargets = _computeTargets(availWidth);
    final changed    = newTargets.entries.any(
      (e) => (e.value - (_targetWidths[e.key] ?? 0)).abs() > 0.5,
    );
    if (!changed && availWidth == _lastAvailableWidth) return;
    _prevWidths         = _currentWidths(availWidth);
    _targetWidths       = newTargets;
    _lastAvailableWidth = availWidth;
    _ac.forward(from: 0);
  }

  Map<String, double> _currentWidths(double availWidth) {
    if (_targetWidths.isEmpty) return _computeTargets(availWidth);
    final t = _ac.value;
    return {
      for (final col in _kCols)
        col.id: _lerpD(
          _prevWidths[col.id]  ?? _targetWidths[col.id] ?? 0,
          _targetWidths[col.id] ?? 0,
          t,
        ),
    };
  }

  static double _lerpD(double a, double b, double t) => a + (b - a) * t;

  @override
  void didUpdateWidget(_AnimatedColRow old) {
    super.didUpdateWidget(old);
    if (old.effectiveVisible != widget.effectiveVisible && _lastAvailableWidth > 0) {
      _startTransition(_lastAvailableWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final avail = constraints.maxWidth;
        if (_lastAvailableWidth == 0) {
          _targetWidths       = _computeTargets(avail);
          _prevWidths         = Map.from(_targetWidths);
          _lastAvailableWidth = avail;
        } else if ((avail - _lastAvailableWidth).abs() > 1) {
          _targetWidths       = _computeTargets(avail);
          _prevWidths         = Map.from(_targetWidths);
          _lastAvailableWidth = avail;
        }

        final widths  = _currentWidths(avail);
        final pinnedW = _pinnedWidth(avail);
        final pinned  = widget.pinnedTrailingCol;

        return Row(
          children: [
            ..._kCols.map((col) {
              final w       = widths[col.id] ?? 0;
              final visible = widget.effectiveVisible.contains(col.id);
              final opacity = visible
                  ? Curves.easeOut.transform(_ac.isAnimating ? _ac.value : 1.0)
                  : Curves.easeIn.transform(_ac.isAnimating ? (1 - _ac.value) : 0.0);
              return SizedBox(
                width: w,
                child: w < 1 ? const SizedBox.shrink()
                    : widget.builder(col, opacity.clamp(0.0, 1.0)),
              );
            }),
            if (pinned != null)
              SizedBox(
                width: pinnedW,
                child: widget.builder(pinned, 1.0),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOOLBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final Set<String>           visibleOptional;
  final bool                  isDetailOpen;
  final bool                  singleProject;
  final void Function(String) onToggle;
  final VoidCallback          onReset;

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
        color:  _T.white,
        border: Border(bottom: BorderSide(color: _T.slate100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _kRowHPad),
      child: Row(
        children: [
          // Task count hint when filtered
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
                color:        _T.slate100,
                borderRadius: BorderRadius.circular(_T.r),
                border:       Border.all(color: _T.slate200),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.view_sidebar_outlined, size: 13, color: _T.slate400),
                SizedBox(width: 6),
                Text(
                  'Showing core columns',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: _T.slate400),
                ),
              ]),
            )
          else
            _ColumnPickerButton(
              visibleOptional: visibleOptional,
              singleProject:   singleProject,
              onToggle:        onToggle,
              onReset:         onReset,
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
  final Set<String>           visibleOptional;
  final bool                  singleProject;
  final void Function(String) onToggle;
  final VoidCallback          onReset;

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
    vsync: this, duration: const Duration(milliseconds: 190),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ac, curve: Curves.easeOut, reverseCurve: Curves.easeIn,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.05), end: Offset.zero,
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
    builder: (_) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap:    _close,
            child:    const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link:             _layerLink,
          showWhenUnlinked: false,
          targetAnchor:     Alignment.bottomRight,
          followerAnchor:   Alignment.topRight,
          offset:           const Offset(0, 6),
          child: AnimatedBuilder(
            animation: _ac,
            builder: (_, child) => FadeTransition(
              opacity: _fade,
              child:   SlideTransition(position: _slide, child: child),
            ),
            child: _ColumnPickerPanel(
              visibleOptional: _overlayVisible,
              singleProject:   widget.singleProject,
              onToggle:        widget.onToggle,
              onReset:         widget.onReset,
              onClose:         _close,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final optionalOnCount = widget.visibleOptional.length;
    final hasCustom       = !_setsEqual(widget.visibleOptional, _kDefaultOptionalOn);

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
                color: _open ? _T.slate300
                    : (hasCustom ? _T.blue.withOpacity(0.3) : _T.slate200),
              ),
              borderRadius: BorderRadius.circular(_T.r),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.view_column_outlined, size: 14,
                  color: _open || hasCustom ? _T.blue : _T.slate400),
              const SizedBox(width: 6),
              Text('Columns', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: _open || hasCustom ? _T.blue : _T.ink3,
              )),
              if (optionalOnCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color:        hasCustom ? _T.blue : _T.slate200,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$optionalOnCount', style: TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w800,
                    color: hasCustom ? Colors.white : _T.slate500,
                  )),
                ),
              ],
              const SizedBox(width: 4),
              AnimatedRotation(
                turns:    _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 190),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14, color: _T.slate400),
              ),
            ]),
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
  final Set<String>           visibleOptional;
  final bool                  singleProject;
  final void Function(String) onToggle;
  final VoidCallback          onReset;
  final VoidCallback          onClose;

  const _ColumnPickerPanel({
    required this.visibleOptional,
    required this.singleProject,
    required this.onToggle,
    required this.onReset,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // When in single-project mode, project col is always hidden — exclude it
    // from the "Always visible" section since it doesn't appear anyway.
    final mandatoryCols = _kCols
        .where((c) => c.mandatory)
        .toList();
    final optionalCols  = _kCols
        .where((c) => !c.mandatory && c.id != 'project')
        .toList();

    // Project col shown as a special "auto" row
    final projectCol = _kCols.firstWhere((c) => c.id == 'project');

    final isDefault  = _setsEqual(visibleOptional, _kDefaultOptionalOn);

    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(_T.rLg),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          color:        _T.white,
          borderRadius: BorderRadius.circular(_T.rLg),
          border:       Border.all(color: _T.slate200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4,  offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.slate100)),
              ),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color:        _T.blue50,
                    borderRadius: BorderRadius.circular(7),
                    border:       Border.all(color: _T.blue.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.view_column_outlined, size: 14, color: _T.blue),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Manage Columns', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _T.ink)),
                    Text('Customise what you see in the list', style: TextStyle(fontSize: 10.5, color: _T.slate400)),
                  ]),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: _T.slate100, borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.close_rounded, size: 13, color: _T.slate400),
                  ),
                ),
              ]),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionLabel('Always visible'),
                  const SizedBox(height: 8),
                  ...mandatoryCols.map((c) => _LockedColRow(col: c)),
                  _LockedColRow(col: _kBillingCol, trailingHint: 'Always last'),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: _T.slate100),
                  const SizedBox(height: 14),

                  // Project column — special: auto-managed by filter
                  _SectionLabel('Auto-managed'),
                  const SizedBox(height: 8),
                  _AutoColRow(
                    col:   projectCol,
                    label: singleProject
                        ? 'Hidden — project filter active'
                        : 'Visible — all projects shown',
                    active: !singleProject,
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: _T.slate100),
                  const SizedBox(height: 14),

                  _SectionLabel('Optional columns'),
                  const SizedBox(height: 8),
                  ...optionalCols.map((c) => _ToggleColRow(
                    col:     c,
                    enabled: visibleOptional.contains(c.id),
                    onTap:   () => onToggle(c.id),
                  )),
                  const SizedBox(height: 4),
                ]),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _T.slate100)),
              ),
              child: Row(children: [
                Icon(Icons.restart_alt_rounded, size: 13,
                    color: isDefault ? _T.slate300 : _T.slate400),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: isDefault ? null : onReset,
                  child: MouseRegion(
                    cursor: isDefault ? SystemMouseCursors.basic : SystemMouseCursors.click,
                    child: Text('Reset to defaults', style: TextStyle(
                      fontSize:        12,
                      fontWeight:      FontWeight.w600,
                      color:           isDefault ? _T.slate300 : _T.slate500,
                      decoration:      isDefault ? TextDecoration.none : TextDecoration.underline,
                      decorationColor: _T.slate400,
                    )),
                  ),
                ),
                const Spacer(),
                Text(
                  '${optionalCols.where((c) => visibleOptional.contains(c.id)).length}/${optionalCols.length} optional',
                  style: const TextStyle(fontSize: 11, color: _T.slate400),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTO-MANAGED COLUMN ROW  (project column — controlled by filter)
// ─────────────────────────────────────────────────────────────────────────────
class _AutoColRow extends StatelessWidget {
  final _ColDef col;
  final String  label;
  final bool    active;

  const _AutoColRow({required this.col, required this.label, required this.active});

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
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: active ? _T.blue.withOpacity(0.1) : _T.slate100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(col.icon, size: 13, color: active ? _T.blue : _T.slate400),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(col.pickerLabel,
                style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: active ? _T.ink : _T.ink3,
                )),
            Text(label,
                style: const TextStyle(fontSize: 10.5, color: _T.slate400)),
          ]),
        ),
        Icon(
          active ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 13,
          color: active ? _T.blue : _T.slate300,
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCKED COLUMN ROW
// ─────────────────────────────────────────────────────────────────────────────
class _LockedColRow extends StatelessWidget {
  final _ColDef  col;
  final String?  trailingHint;
  const _LockedColRow({required this.col, this.trailingHint});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _T.slate50, borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(color: _T.slate200),
      ),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: _T.slate100, borderRadius: BorderRadius.circular(6)),
          child: Icon(col.icon, size: 13, color: _T.slate400),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(col.pickerLabel,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _T.ink3))),
        if (trailingHint != null) ...[
          Text(trailingHint!, style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500, color: _T.slate400,
          )),
          const SizedBox(width: 6),
        ],
        const Icon(Icons.lock_outline_rounded, size: 12, color: _T.slate300),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE COLUMN ROW
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleColRow extends StatefulWidget {
  final _ColDef      col;
  final bool         enabled;
  final VoidCallback onTap;
  const _ToggleColRow({required this.col, required this.enabled, required this.onTap});

  @override
  State<_ToggleColRow> createState() => _ToggleColRowState();
}

class _ToggleColRowState extends State<_ToggleColRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: widget.enabled
                ? _T.blue.withOpacity(0.05)
                : (_hovering ? _T.slate50 : Colors.transparent),
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: widget.enabled ? _T.blue.withOpacity(0.2)
                  : (_hovering ? _T.slate200 : Colors.transparent),
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(_T.r)),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: widget.enabled ? _T.blue.withOpacity(0.1) : _T.slate100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(widget.col.icon, size: 13,
                    color: widget.enabled ? _T.blue : _T.slate400),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.col.pickerLabel, style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: widget.enabled ? _T.ink : _T.ink3,
                  )),
                  Text(widget.col.description,
                      style: const TextStyle(fontSize: 10.5, color: _T.slate400)),
                ]),
              ),
              const SizedBox(width: 8),
              _MiniSwitch(value: widget.enabled, onChanged: (_) => widget.onTap()),
            ]),
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
      value:                 value,
      onChanged:             onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeColor:           _T.blue,
      inactiveThumbColor:    _T.slate300,
      inactiveTrackColor:    _T.slate200,
      trackOutlineColor:     WidgetStateProperty.all(Colors.transparent),
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white : _T.slate300),
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
      fontSize: 9.5, fontWeight: FontWeight.w700,
      letterSpacing: 0.8, color: _T.slate400,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK ROW
// ─────────────────────────────────────────────────────────────────────────────
class _TaskRow extends StatefulWidget {
  final Task          task;
  final Project?      project;
  final Member?       assignee;
  final Set<String>   effectiveVisible;
  final bool          isSelected;
  final VoidCallback  onTap;

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

  @override
  Widget build(BuildContext context) {
    final t   = widget.task;
    final p   = widget.project;
    final m   = widget.assignee;
    final now = DateTime.now();
    final s   = stageInfo(t.status);
    final d   = t.createdAt;

    final dateFormatted = fmtDate(d);
    final dateParts     = dateFormatted.split(' ');
    final dateDisplay   = d.year == now.year && dateParts.length > 2
        ? dateParts.take(dateParts.length - 1).join(' ')
        : dateFormatted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Material(
        color: widget.isSelected ? _T.blue50 : (_hovered ? _T.slate50 : _T.white),
        borderRadius: BorderRadius.circular(_T.r),
        child: InkWell(
          onTap:        widget.onTap,
          borderRadius: BorderRadius.circular(_T.r),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: _AnimatedColRow(
              effectiveVisible:  widget.effectiveVisible,
              pinnedTrailingCol: _kBillingCol,
              builder: (col, opacity) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
                child: Opacity(
                  opacity: opacity,
                  child: _cellFor(col, t, p, m, s, dateDisplay),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cellFor(_ColDef col, Task t, Project? p, Member? m, dynamic s, String date) {
    return switch (col.id) {
      'task' => Text(t.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.ink)),

      'project' => p != null
          ? Row(children: [
              Container(width: 7, height: 7,
                  decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: _T.slate500))),
            ])
          : const Text('—', style: TextStyle(color: _T.slate300)),

      'ref' => t.ref != null && t.ref!.isNotEmpty
          ? Text(t.ref!, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: _T.ink3, fontFamily: 'monospace'))
          : const Text('—', style: TextStyle(fontSize: 13, color: _T.slate300)),

      'stage'    => StagePill(stageInfo: s),
      'date'     => Text(date, style: const TextStyle(fontSize: 12.5, color: _T.slate500)),
      'priority' => PriorityPill(priority: t.priority),

      'size' => t.size != null && !t.size!.contains("null")
          ? RichText(text: TextSpan(
              style: const TextStyle(fontSize: 12.5, color: _T.ink3),
              children: [
                TextSpan(text: t.size!.split(' ')[0]),
                TextSpan(
                  text: t.size!.split(' ').length > 1 ? t.size!.split(' ')[1] : '',
                  style: const TextStyle(fontSize: 11, color: _T.slate400),
                ),
              ],
            ))
          : const Text('—', style: TextStyle(fontSize: 13, color: _T.slate300)),

      'qty' => t.quantity != null
          ? Text('${t.quantity}', style: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w600, color: _T.ink3))
          : const Text('—', style: TextStyle(fontSize: 13, color: _T.slate300)),

      'assignee' => m != null
          ? Row(children: [
              AvatarWidget(initials: m.initials, color: m.color, size: 22),
              const SizedBox(width: 7),
              Expanded(child: Text(m.name, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: _T.slate500))),
            ])
          : const Text('—', style: TextStyle(fontSize: 13, color: _T.slate300)),

      'billing' => _BillingStatusCell(status: t.billingStatus),

      _ => const SizedBox.shrink(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILLING STATUS CELL
// ─────────────────────────────────────────────────────────────────────────────
class _BillingStatusCell extends StatelessWidget {
  final BillingStatus? status;
  const _BillingStatusCell({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const Text('—', style: TextStyle(fontSize: 13, color: _T.slate300));
    }

    final (String label, Color fg, Color bg) = switch (status!) {
      BillingStatus.pending    => ('-',          _T.amber,     const Color(0xFFFEF3C7)),
      BillingStatus.invoiced   => ('Invoiced',   _T.blue,      _T.blue50),
      BillingStatus.foc        => ('FOC',        _T.green,     const Color(0xFFECFDF5)),
      BillingStatus.cancelled  => ('Cancelled',  _T.red,       const Color(0xFFFEE2E2)),
      BillingStatus.quoteGiven => ('Quote',      _T.slate400,  _T.slate100),
    };

    return Text(label, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black,
    ));
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
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: _T.slate100, borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.assignment_outlined, size: 24, color: _T.slate400),
        ),
        const SizedBox(height: 16),
        const Text('No tasks yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _T.ink3)),
        const SizedBox(height: 6),
        const Text('Tasks you create will appear here',
            style: TextStyle(fontSize: 13, color: _T.slate400)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
bool _setsEqual(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);