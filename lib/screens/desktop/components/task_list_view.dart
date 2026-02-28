// ─────────────────────────────────────────────────────────────────────────────
// task_list_view.dart
//
// Changes from previous version:
//   • Table takes full available width — no right-padding reserved for button.
//   • _ColumnPickerButton lives in a toolbar row ABOVE the column headers.
//   • New `isDetailOpen` prop: when true, table animates to mandatory-only
//     columns (because the detail panel steals horizontal space). When false,
//     the user's saved optional columns animate back in.
//   • Column show/hide is animated: each column's width and opacity transition
//     smoothly using AnimatedContainer so the table reflows without jumping.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/priority_pill.dart';
import 'package:smooflow/screens/desktop/components/stage_pill.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

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
const double _kRowHPad   = 16.0;  // uniform left/right padding on every row
const double _kCellHPad  = 4.0;   // inner padding on each cell / header cell

// Duration for column appear/disappear animation
const _kColAnimDuration = Duration(milliseconds: 260);

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
    id: 'task', label: 'TASK', pickerLabel: 'Task Name',
    description: 'Task name',
    icon: Icons.drive_file_rename_outline_rounded,
    mandatory: true, defaultOn: true, flex: 4,
  ),
  _ColDef(
    id: 'project', label: 'PROJECT', pickerLabel: 'Project',
    description: 'Colour-coded project name',
    icon: Icons.folder_outlined,
    mandatory: true, defaultOn: true, flex: 2,
  ),
  _ColDef(
    id: 'ref', label: 'REF', pickerLabel: 'Reference',
    description: 'Client reference or PO number',
    icon: Icons.tag_rounded,
    mandatory: true, defaultOn: true, flex: 2,
  ),
  _ColDef(
    id: 'stage', label: 'STAGE', pickerLabel: 'Stage',
    description: 'Current pipeline stage pill',
    icon: Icons.view_kanban_outlined,
    mandatory: true, defaultOn: true, flex: 2,
  ),
  _ColDef(
    id: 'date', label: 'DATE', pickerLabel: 'Date Created',
    description: 'Date the task was created',
    icon: Icons.calendar_today_outlined,
    mandatory: true, defaultOn: true, flex: 1,
  ),
  _ColDef(
    id: 'priority', label: 'PRIORITY', pickerLabel: 'Priority',
    description: 'Urgent / High / Normal priority pill',
    icon: Icons.flag_outlined,
    mandatory: false, defaultOn: true, flex: 2,
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
  _ColDef(
    id: 'assignee', label: 'ASSIGNEE', pickerLabel: 'Assignee',
    description: 'Assigned team member',
    icon: Icons.person_outline_rounded,
    mandatory: false, defaultOn: false, flex: 2,
  ),
];

Set<String> get _kDefaultOptionalOn => _kCols
    .where((c) => !c.mandatory && c.defaultOn)
    .map((c) => c.id)
    .toSet();

Set<String> get _kMandatoryIds => _kCols
    .where((c) => c.mandatory)
    .map((c) => c.id)
    .toSet();

const _kPrefsKey = 'smooflow.task_list.visible_optional_cols';

// ─────────────────────────────────────────────────────────────────────────────
// TASK LIST VIEW
// ─────────────────────────────────────────────────────────────────────────────
class TaskListView extends ConsumerStatefulWidget {
  final List<Task>        tasks;
  final List<Project>     projects;
  final int?              selectedTaskId;
  final ValueChanged<int> onTaskSelected;

  /// When true the detail panel is open — animate to mandatory columns only.
  /// When false (panel closed) — animate back to the user's saved columns.
  final bool              isDetailOpen;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.projects,
    required this.selectedTaskId,
    required this.onTaskSelected,
    this.isDetailOpen = false,
  });

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> {
  /// Columns the user has explicitly enabled (optional only).
  Set<String> _visibleOptional = {};

  /// The "effective" visible set — when detail panel is open, collapses to
  /// mandatory only. Otherwise uses the user's saved optional set.
  Set<String> get _effectiveVisible {
    if (widget.isDetailOpen) return _kMandatoryIds;
    return {..._kMandatoryIds, ..._visibleOptional};
  }

  @override
  void initState() {
    super.initState();
    _visibleOptional = Set.from(_kDefaultOptionalOn);
    _loadPrefs();
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kPrefsKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<String>();
      if (mounted) setState(() => _visibleOptional = Set.from(list));
    } else {
      await _savePrefs();
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(_visibleOptional.toList()));
  }

  void _toggleColumn(String id) {
    setState(() => _visibleOptional.contains(id)
        ? _visibleOptional.remove(id)
        : _visibleOptional.add(id));
    _savePrefs();
  }

  void _resetToDefaults() {
    setState(() => _visibleOptional = Set.from(_kDefaultOptionalOn));
    _savePrefs();
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final members   = ref.watch(memberNotifierProvider).members;
    final tasks     = widget.tasks.reversed.toList();
    // Pass full _kCols list — each column decides its own visibility/width.
    final effective = _effectiveVisible;

    return Container(
      color: _T.slate50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Toolbar (Columns button lives here, above the table) ──────────
          _Toolbar(
            visibleOptional: _visibleOptional,
            isDetailOpen:    widget.isDetailOpen,
            onToggle:        _toggleColumn,
            onReset:         _resetToDefaults,
          ),

          // ── Column header row ─────────────────────────────────────────────
          Container(
            color: _T.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(_kRowHPad, 8, _kRowHPad, 8),
                  child: _AnimatedColRow(
                    effectiveVisible: effective,
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

          // ── Data rows ─────────────────────────────────────────────────────
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
                        task:            t,
                        project:         p,
                        assignee:        m,
                        effectiveVisible: effective,
                        isSelected:      widget.selectedTaskId == t.id,
                        onTap:           () => widget.onTaskSelected(t.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED COLUMN ROW
//
// Renders ALL _kCols in a single Row. Each column is wrapped in an
// AnimatedContainer that transitions its width between its natural flex-based
// size (visible) and 0 (hidden). Opacity fades in parallel.
//
// Because Flutter's Row with Expanded children doesn't support animating
// flex, we use a LayoutBuilder to measure available width and allocate
// pixel widths manually, then animate with AnimatedContainer.
//
// Visible columns share the available width proportionally to their flex.
// Hidden columns animate from their last pixel size down to 0.
// ─────────────────────────────────────────────────────────────────────────────
typedef _ColCellBuilder = Widget Function(_ColDef col, double opacityFraction);

class _AnimatedColRow extends StatefulWidget {
  final Set<String>    effectiveVisible;
  final _ColCellBuilder builder;

  const _AnimatedColRow({
    required this.effectiveVisible,
    required this.builder,
  });

  @override
  State<_AnimatedColRow> createState() => _AnimatedColRowState();
}

class _AnimatedColRowState extends State<_AnimatedColRow>
    with SingleTickerProviderStateMixin {

  late AnimationController _ac;
  // Per-column target widths (0 = hidden, >0 = visible).
  // Stored so we can lerp from previous to new target on each transition.
  Map<String, double> _prevWidths  = {};
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

  Map<String, double> _computeTargets(double availWidth) {
    final visibleCols = _kCols.where((c) => widget.effectiveVisible.contains(c.id)).toList();
    final totalFlex   = visibleCols.fold<int>(0, (s, c) => s + c.flex);
    final result      = <String, double>{};
    for (final col in _kCols) {
      if (widget.effectiveVisible.contains(col.id)) {
        result[col.id] = totalFlex > 0 ? (col.flex / totalFlex) * availWidth : 0;
      } else {
        result[col.id] = 0;
      }
    }
    return result;
  }

  void _startTransition(double availWidth) {
    final newTargets = _computeTargets(availWidth);
    // Only animate if something actually changed
    bool changed = newTargets.entries.any(
      (e) => (e.value - (_targetWidths[e.key] ?? 0)).abs() > 0.5,
    );
    if (!changed && availWidth == _lastAvailableWidth) return;

    _prevWidths      = _currentWidths(availWidth);
    _targetWidths    = newTargets;
    _lastAvailableWidth = availWidth;
    _ac.forward(from: 0);
  }

  // Interpolated widths at the current animation value
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
    if (old.effectiveVisible != widget.effectiveVisible && _lastAvailableWidth > 0) {
      _startTransition(_lastAvailableWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final avail = constraints.maxWidth;
        // On first layout or available width change, recompute without animation
        if (_lastAvailableWidth == 0) {
          _targetWidths       = _computeTargets(avail);
          _prevWidths         = Map.from(_targetWidths);
          _lastAvailableWidth = avail;
        } else if ((avail - _lastAvailableWidth).abs() > 1) {
          // Window resize — snap immediately, no animation
          _targetWidths       = _computeTargets(avail);
          _prevWidths         = Map.from(_targetWidths);
          _lastAvailableWidth = avail;
        }

        final widths = _currentWidths(avail);

        return Row(
          children: _kCols.map((col) {
            final w       = widths[col.id] ?? 0;
            final visible = widget.effectiveVisible.contains(col.id);
            // Opacity: lerp from 0→1 (appear) or 1→0 (disappear) with the same timing
            final opacity = visible
                ? Curves.easeOut.transform(_ac.isAnimating ? _ac.value : 1.0)
                : Curves.easeIn.transform(_ac.isAnimating ? (1 - _ac.value) : 0.0);

            return SizedBox(
              width: w,
              child: w < 1
                  ? const SizedBox.shrink()
                  : widget.builder(col, opacity.clamp(0.0, 1.0)),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOOLBAR
//
// A slim bar above the column headers that holds the Columns picker button
// (and can host future controls like search/filter on the left).
// When isDetailOpen, the button is disabled and shows a subtle "panel open"
// hint so the user knows why their optional columns have collapsed.
// ─────────────────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final Set<String>           visibleOptional;
  final bool                  isDetailOpen;
  final void Function(String) onToggle;
  final VoidCallback          onReset;

  const _Toolbar({
    required this.visibleOptional,
    required this.isDetailOpen,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color:  _T.white,
        border: Border(bottom: BorderSide(color: _T.slate100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: _kRowHPad),
      child: Row(
        children: [
          // Left side — placeholder for future search/filter controls
          const Spacer(),

          // Detail-open hint — replaces the button when panel is active
          if (isDetailOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  style: TextStyle(
                    fontSize:   11.5,
                    fontWeight: FontWeight.w500,
                    color:      _T.slate400,
                  ),
                ),
              ]),
            )
          else
            _ColumnPickerButton(
              visibleOptional: visibleOptional,
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
  final void Function(String) onToggle;
  final VoidCallback          onReset;

  const _ColumnPickerButton({
    required this.visibleOptional,
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
    vsync:    this,
    duration: const Duration(milliseconds: 190),
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
          link:           _layerLink,
          showWhenUnlinked: false,
          targetAnchor:   Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset:         const Offset(0, 6),
          child: AnimatedBuilder(
            animation: _ac,
            builder: (_, child) => FadeTransition(
              opacity: _fade,
              child:   SlideTransition(position: _slide, child: child),
            ),
            child: _ColumnPickerPanel(
              visibleOptional: _overlayVisible,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
  final void Function(String) onToggle;
  final VoidCallback          onReset;
  final VoidCallback          onClose;

  const _ColumnPickerPanel({
    required this.visibleOptional,
    required this.onToggle,
    required this.onReset,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final mandatoryCols = _kCols.where((c) => c.mandatory).toList();
    final optionalCols  = _kCols.where((c) => !c.mandatory).toList();
    final isDefault     = _setsEqual(visibleOptional, _kDefaultOptionalOn);

    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(_T.rLg),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 480),
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
// LOCKED COLUMN ROW
// ─────────────────────────────────────────────────────────────────────────────
class _LockedColRow extends StatelessWidget {
  final _ColDef col;
  const _LockedColRow({required this.col});

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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              effectiveVisible: widget.effectiveVisible,
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
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _T.slate100, borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _T.slate200),
              ),
              child: Text(t.ref!, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _T.ink3, fontFamily: 'monospace')),
            )
          : const Text('—', style: TextStyle(fontSize: 13, color: _T.slate300)),

      'stage'    => StagePill(stageInfo: s),

      'date'     => Text(date,
          style: const TextStyle(fontSize: 12.5, color: _T.slate500)),

      'priority' => PriorityPill(priority: t.priority),

      'size' => t.size != null
          ? RichText(text: TextSpan(
              style: const TextStyle(fontSize: 12.5, color: _T.ink3),
              children: [
                TextSpan(text: t.size!.split(" ")[0]),
                if (t.size!.split(" ").length > 1)
                  TextSpan(text: t.size!.split(" ")[1], style: TextStyle(fontSize: 11, color: _T.slate400)),
                // const TextSpan(text: ' cm', style: TextStyle(fontSize: 11, color: _T.slate400)),
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

      _ => const SizedBox.shrink(),
    };
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