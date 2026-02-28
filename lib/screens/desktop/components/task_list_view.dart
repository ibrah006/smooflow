// ─────────────────────────────────────────────────────────────────────────────
// task_list_view.dart
//
// Advanced task list view with user-controlled column visibility.
//
// COLUMN SYSTEM
// ─────────────
//   Mandatory (always visible, cannot be hidden):
//     task, project, stage, date, ref
//
//   Optional (user-controlled, persisted to SharedPreferences):
//     priority   — default ON  (was always visible before)
//     assignee   — default OFF
//     description— default OFF
//     size       — default OFF (W × H from the new task spec)
//     qty        — default OFF
//
// PERSISTENCE
// ───────────
//   Key: 'smooflow.task_list.visible_optional_cols'
//   Value: JSON-encoded List<String> of enabled optional column IDs.
//   Loaded asynchronously in initState — table renders immediately with
//   defaults, updates once prefs are read (no loading spinner shown).
//
// COLUMN PICKER UI
// ────────────────
//   A "Columns" button in the top-right of the table header bar.
//   Opens a 300 px wide overlay panel anchored directly below the button
//   (CompositedTransformTarget + CompositedTransformFollower, same pattern
//   as user_menu_chip.dart).  Tap-outside dismisses.
//
//   Panel sections:
//     • "Always visible" — locked mandatory columns (lock icon, no toggle)
//     • "Optional columns" — toggle rows with icon + label + description
//     • "Reset to defaults" text button at the bottom
//
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
  static const sidebarW  = 220.0;
  static const topbarH   = 52.0;
  static const detailW   = 400.0;
  static const r         = 8.0;
  static const rLg       = 12.0;
  static const rXl       = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// COLUMN DEFINITIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Typed column descriptor. `flex` is the Expanded flex weight.
class _ColDef {
  final String   id;
  final String   label;        // header label shown in the table
  final String   pickerLabel;  // label shown in the picker panel
  final String   description;  // one-liner shown in the picker
  final IconData icon;
  final bool     mandatory;    // mandatory = cannot be hidden
  final bool     defaultOn;    // optional columns: visible by default?
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

/// Ordered master list — the order here is the order they appear in the table.
const _kCols = [
  _ColDef(
    id: 'task', label: 'TASK', pickerLabel: 'Task Name',
    description: 'Task name and inline description',
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
    mandatory: false, defaultOn: false, flex: 1,
  ),
  _ColDef(
    id: 'assignee', label: 'ASSIGNEE', pickerLabel: 'Assignee',
    description: 'Assigned team member',
    icon: Icons.person_outline_rounded,
    mandatory: false, defaultOn: false, flex: 2,
  ),
  _ColDef(
    id: 'description', label: 'DESCRIPTION', pickerLabel: 'Description',
    description: 'Task description (truncated)',
    icon: Icons.notes_rounded,
    mandatory: false, defaultOn: false, flex: 3,
  ),
];

/// IDs of optional columns that are ON by default.
Set<String> get _kDefaultOptionalOn => _kCols
    .where((c) => !c.mandatory && c.defaultOn)
    .map((c) => c.id)
    .toSet();

/// SharedPreferences key.
const _kPrefsKey = 'smooflow.task_list.visible_optional_cols';

// ─────────────────────────────────────────────────────────────────────────────
// TASK LIST VIEW
// ─────────────────────────────────────────────────────────────────────────────
class TaskListView extends ConsumerStatefulWidget {
  final List<Task>        tasks;
  final List<Project>     projects;
  final int?              selectedTaskId;
  final ValueChanged<int> onTaskSelected;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.projects,
    required this.selectedTaskId,
    required this.onTaskSelected,
  });

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> {
  /// Which optional column IDs are currently visible.
  Set<String> _visibleOptional = {};

  /// Combined: mandatory IDs ∪ visible optional IDs.
  Set<String> get _visible => {
    ..._kCols.where((c) => c.mandatory).map((c) => c.id),
    ..._visibleOptional,
  };

  /// Ordered visible columns.
  List<_ColDef> get _visibleCols =>
      _kCols.where((c) => _visible.contains(c.id)).toList();

  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _visibleOptional = Set.from(_kDefaultOptionalOn);
    _loadPrefs();
  }

  // ── SharedPreferences ───────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kPrefsKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<String>();
      if (mounted) {
        setState(() {
          _visibleOptional = Set.from(list);
          _prefsLoaded     = true;
        });
      }
    } else {
      // First launch — write defaults so they exist for next session.
      if (mounted) setState(() => _prefsLoaded = true);
      await _savePrefs();
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(_visibleOptional.toList()));
  }

  void _toggleColumn(String id) {
    setState(() {
      _visibleOptional.contains(id)
          ? _visibleOptional.remove(id)
          : _visibleOptional.add(id);
    });
    _savePrefs();
  }

  void _resetToDefaults() {
    setState(() => _visibleOptional = Set.from(_kDefaultOptionalOn));
    _savePrefs();
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final members  = ref.watch(memberNotifierProvider).members;
    final tasks    = widget.tasks.reversed.toList();
    final cols     = _visibleCols;

    // Count of optional columns the user has enabled
    final optionalOnCount = _visibleOptional.length;

    return Container(
      color: _T.slate50,
      child: Column(
        children: [

          // ── Table header bar ─────────────────────────────────────────
          _HeaderBar(
            cols:             cols,
            optionalOnCount:  optionalOnCount,
            visibleOptional:  _visibleOptional,
            onToggle:         _toggleColumn,
            onReset:          _resetToDefaults,
          ),

          const Divider(height: 1, thickness: 1, color: _T.slate200),

          // ── Rows ─────────────────────────────────────────────────────
          Expanded(
            child: tasks.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
                        cols:            cols,
                        isSelected:      widget.selectedTaskId == t.id,
                        isLast:          i == tasks.length - 1,
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
// HEADER BAR — column headers + "Columns" picker button
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderBar extends StatelessWidget {
  final List<_ColDef> cols;
  final int           optionalOnCount;
  final Set<String>   visibleOptional;
  final void Function(String) onToggle;
  final VoidCallback  onReset;

  const _HeaderBar({
    required this.cols,
    required this.optionalOnCount,
    required this.visibleOptional,
    required this.onToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.white,
      padding: const EdgeInsets.only(left: 16, right: 12, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ── Dynamic column headers ─────────────────────────────────
          Expanded(
            child: Row(
              children: cols.map((c) => Expanded(
                flex: c.flex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    c.label,
                    style: const TextStyle(
                      fontSize:      10.5,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 0.7,
                      color:         _T.slate400,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),

          const SizedBox(width: 8),

          // ── Columns picker button ──────────────────────────────────
          _ColumnPickerButton(
            optionalOnCount: optionalOnCount,
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
//
// CompositedTransformTarget on the button, CompositedTransformFollower on the
// panel — same pattern as user_menu_chip.dart.
// ─────────────────────────────────────────────────────────────────────────────
class _ColumnPickerButton extends StatefulWidget {
  final int           optionalOnCount;
  final Set<String>   visibleOptional;
  final void Function(String) onToggle;
  final VoidCallback  onReset;

  const _ColumnPickerButton({
    required this.optionalOnCount,
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

  late final AnimationController _ac = AnimationController(
    vsync:    this,
    duration: const Duration(milliseconds: 190),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent:       _ac,
    curve:        Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.05),
    end:   Offset.zero,
  ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _removeOverlay();
    _ac.dispose();
    super.dispose();
  }

  void _toggle() => _open ? _close() : _show();

  void _show() {
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

  // Rebuild overlay when parent passes new state (toggle from inside panel).
  @override
  void didUpdateWidget(_ColumnPickerButton old) {
    super.didUpdateWidget(old);
    if (_open) {
      // Mark overlay dirty so it rebuilds with fresh visibleOptional state.
      _overlay?.markNeedsBuild();
    }
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Full-screen tap-away dismisser
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap:    _close,
              child:    const SizedBox.expand(),
            ),
          ),
          // Panel anchored below the button, aligned to the right edge
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
                visibleOptional: widget.visibleOptional,
                onToggle:        (id) {
                  widget.onToggle(id);
                  _overlay?.markNeedsBuild();
                },
                onReset: () {
                  widget.onReset();
                  _overlay?.markNeedsBuild();
                },
                onClose: _close,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // How many optional cols are on beyond the default set?
    final customCount = widget.optionalOnCount - _kDefaultOptionalOn.length;
    final hasCustom   = widget.visibleOptional != _kDefaultOptionalOn;

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
              color: _open
                  ? _T.slate100
                  : (hasCustom ? _T.blue50 : _T.white),
              border: Border.all(
                color: _open
                    ? _T.slate300
                    : (hasCustom
                        ? _T.blue.withOpacity(0.3)
                        : _T.slate200),
              ),
              borderRadius: BorderRadius.circular(_T.r),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                Icons.view_column_outlined,
                size:  14,
                color: _open || hasCustom ? _T.blue : _T.slate400,
              ),
              const SizedBox(width: 6),
              Text(
                'Columns',
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color: _open || hasCustom ? _T.blue : _T.ink3,
                ),
              ),
              // Badge: number of optional columns enabled
              if (widget.optionalOnCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color:        hasCustom ? _T.blue : _T.slate200,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${widget.optionalOnCount}',
                    style: TextStyle(
                      fontSize:   9.5,
                      fontWeight: FontWeight.w800,
                      color: hasCustom ? Colors.white : _T.slate500,
                    ),
                  ),
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
  final Set<String>          visibleOptional;
  final void Function(String) onToggle;
  final VoidCallback         onReset;
  final VoidCallback         onClose;

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
    final isDefault     = visibleOptional
        .difference(_kDefaultOptionalOn)
        .isEmpty &&
        _kDefaultOptionalOn.difference(visibleOptional).isEmpty;

    return Material(
      color:       Colors.transparent,
      borderRadius: BorderRadius.circular(_T.rLg),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rLg),
          border: Border.all(color: _T.slate200),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset:     const Offset(0, 6),
            ),
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset:     const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Header ───────────────────────────────────────────────
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
                  child: const Icon(Icons.view_column_outlined,
                      size: 14, color: _T.blue),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manage Columns',
                          style: TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                            color:      _T.ink,
                          )),
                      Text('Customise what you see in the list',
                          style: TextStyle(
                            fontSize:   10.5,
                            color:      _T.slate400,
                            fontWeight: FontWeight.w400,
                          )),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color:        _T.slate100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: _T.slate400),
                  ),
                ),
              ]),
            ),

            // ── Scrollable body ───────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Always visible section
                    _SectionLabel('Always visible'),
                    const SizedBox(height: 8),
                    ...mandatoryCols.map((c) => _LockedColRow(col: c)),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: _T.slate100),
                    const SizedBox(height: 14),

                    // Optional section
                    _SectionLabel('Optional columns'),
                    const SizedBox(height: 8),
                    ...optionalCols.map((c) => _ToggleColRow(
                      col:     c,
                      enabled: visibleOptional.contains(c.id),
                      onTap:   () => onToggle(c.id),
                    )),

                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // ── Footer: reset ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _T.slate100)),
              ),
              child: Row(children: [
                Icon(
                  Icons.restart_alt_rounded,
                  size:  13,
                  color: isDefault ? _T.slate300 : _T.slate400,
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: isDefault ? null : onReset,
                  child: Text(
                    'Reset to defaults',
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color: isDefault ? _T.slate300 : _T.slate500,
                      decoration: isDefault
                          ? TextDecoration.none
                          : TextDecoration.underline,
                      decorationColor: _T.slate400,
                    ),
                  ),
                ),
                const Spacer(),
                // Live count of optional columns enabled
                Text(
                  '${optionalCols.where((c) => visibleOptional.contains(c.id)).length}/${optionalCols.length} optional',
                  style: const TextStyle(
                    fontSize: 11,
                    color:    _T.slate400,
                  ),
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
// LOCKED COLUMN ROW (mandatory — shows lock icon instead of toggle)
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
        color:        _T.slate50,
        borderRadius: BorderRadius.circular(_T.r),
        border:       Border.all(color: _T.slate200),
      ),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color:        _T.slate100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(col.icon, size: 13, color: _T.slate400),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(col.pickerLabel,
              style: const TextStyle(
                fontSize:   12.5,
                fontWeight: FontWeight.w600,
                color:      _T.ink3,
              )),
        ),
        const Icon(Icons.lock_outline_rounded, size: 12, color: _T.slate300),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE COLUMN ROW (optional — switch + description)
// ─────────────────────────────────────────────────────────────────────────────
class _ToggleColRow extends StatefulWidget {
  final _ColDef  col;
  final bool     enabled;
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
                color: widget.enabled
                    ? _T.blue.withOpacity(0.2)
                    : (_hovering ? _T.slate200 : Colors.transparent),
              ),
            ),
            child: Row(children: [
              // Icon container — coloured when enabled
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? _T.blue.withOpacity(0.1)
                      : _T.slate100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  widget.col.icon,
                  size:  13,
                  color: widget.enabled ? _T.blue : _T.slate400,
                ),
              ),
              const SizedBox(width: 10),

              // Label + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.col.pickerLabel,
                        style: TextStyle(
                          fontSize:   12.5,
                          fontWeight: FontWeight.w600,
                          color: widget.enabled ? _T.ink : _T.ink3,
                        )),
                    Text(widget.col.description,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color:    _T.slate400,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Switch
              _MiniSwitch(value: widget.enabled, onChanged: (_) => widget.onTap()),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI SWITCH — small, on-brand version of the system Switch
// ─────────────────────────────────────────────────────────────────────────────
class _MiniSwitch extends StatelessWidget {
  final bool                 value;
  final ValueChanged<bool>?  onChanged;
  const _MiniSwitch({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 22,
    child: Switch(
      value:         value,
      onChanged:     onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeColor:   _T.blue,
      inactiveThumbColor:  _T.slate300,
      inactiveTrackColor:  _T.slate200,
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return _T.slate300;
      }),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL (inside picker)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize:      9.5,
      fontWeight:    FontWeight.w700,
      letterSpacing: 0.8,
      color:         _T.slate400,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK ROW
// ─────────────────────────────────────────────────────────────────────────────
class _TaskRow extends StatefulWidget {
  final Task      task;
  final Project?  project;
  final Member?   assignee;
  final List<_ColDef> cols;
  final bool      isSelected, isLast;
  final VoidCallback  onTap;

  const _TaskRow({
    required this.task, required this.project, required this.assignee,
    required this.cols, required this.isSelected, required this.isLast,
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
    // Drop the year if same year, i.e. "12 Jan 2025" → "12 Jan"
    final dateDisplay = d.year == now.year && dateParts.length > 2
        ? dateParts.take(dateParts.length - 1).join(' ')
        : dateFormatted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Material(
        color: widget.isSelected
            ? _T.blue50
            : (_hovered ? _T.slate50 : _T.white),
        borderRadius: BorderRadius.circular(_T.r),
        child: InkWell(
          onTap:        widget.onTap,
          borderRadius: BorderRadius.circular(_T.r),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: widget.cols.map((c) {
                return Expanded(
                  flex: c.flex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _cellFor(c, t, p, m, s, dateDisplay),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Cell builder — one method per column ────────────────────────────────────
  Widget _cellFor(
    _ColDef    col,
    Task       t,
    Project?   p,
    Member?    m,
    dynamic    s,    // DesignStageInfo / StageInfo
    String     date,
  ) {
    return switch (col.id) {
      'task' => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.name,
                style: const TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      _T.ink,
                )),
          ],
        ),

      'project' => p != null
          ? Row(children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                    color: p.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(p.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color:    _T.slate500,
                    )),
              ),
            ])
          : const Text('—', style: TextStyle(color: _T.slate300)),

      'ref' => t.ref != null && t.ref!.isNotEmpty
          ? Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:        _T.slate100,
                  borderRadius: BorderRadius.circular(4),
                  border:       Border.all(color: _T.slate200),
                ),
                child: Text(
                  t.ref!,
                  style: const TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      _T.ink3,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ])
          : const Text('—',
              style: TextStyle(fontSize: 13, color: _T.slate300)),

      'stage' => StagePill(stageInfo: s),

      'date' => Text(
          date,
          style: const TextStyle(
            fontSize:   12.5,
            fontWeight: FontWeight.w400,
            color:      _T.slate500,
          ),
        ),

      'priority' => PriorityPill(priority: t.priority),

      'size' => (t.size != null)
          ? RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, color: _T.ink3),
                children: [
                  TextSpan(
                    text: t.size,
                  ),
                  const TextSpan(
                    text:  ' cm',
                    style: TextStyle(fontSize: 11, color: _T.slate400),
                  ),
                ],
              ),
            )
          : const Text('—',
              style: TextStyle(fontSize: 13, color: _T.slate300)),

      'qty' => t.quantity != null
          ? Text(
              '${t.quantity}',
              style: const TextStyle(
                fontSize:   12.5,
                fontWeight: FontWeight.w600,
                color:      _T.ink3,
              ),
            )
          : const Text('—',
              style: TextStyle(fontSize: 13, color: _T.slate300)),

      'assignee' => m != null
          ? Row(children: [
              AvatarWidget(
                  initials: m.initials, color: m.color, size: 22),
              const SizedBox(width: 7),
              Expanded(
                child: Text(m.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color:    _T.slate500,
                    )),
              ),
            ])
          : const Text('—',
              style: TextStyle(fontSize: 13, color: _T.slate300)),

      'description' => (t.description != null && t.description!.isNotEmpty)
          ? Text(
              t.description!.length > 60
                  ? '${t.description!.substring(0, 60)}…'
                  : t.description!,
              style: const TextStyle(fontSize: 11.5, color: _T.slate400),
              overflow: TextOverflow.ellipsis,
            )
          : const Text('—',
              style: TextStyle(fontSize: 13, color: _T.slate300)),

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
            color:        _T.slate100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.assignment_outlined,
              size: 24, color: _T.slate400),
        ),
        const SizedBox(height: 16),
        const Text('No tasks yet',
            style: TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w600,
              color:      _T.ink3,
            )),
        const SizedBox(height: 6),
        const Text('Tasks you create will appear here',
            style: TextStyle(fontSize: 13, color: _T.slate400)),
      ],
    ),
  );
}