// ─────────────────────────────────────────────────────────────────────────────
// BOARD VIEW — Modern Corporate Redesign
//
// Design language: Linear / Asana / Notion — refined enterprise.
// - Filter bar: pill-on-active tabs, no underlines, clean surface
// - Lanes: shadow-elevated panels, colored top accent strip, no border
// - Cards rendered by TaskCard (unchanged)
// - _T color tokens untouched
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/desktop/components/task_card.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — unchanged from original
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
  static const topbarH = 52.0;
  static const detailW = 400.0;

  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE GROUPS
// ─────────────────────────────────────────────────────────────────────────────
class _StageGroup {
  final String label;
  final Color color;
  final List<TaskStatus> statuses;
  const _StageGroup(this.label, this.color, this.statuses);
}

const _kGroups = <_StageGroup>[
  _StageGroup('Design', Color(0xFF8B5CF6), [
    TaskStatus.pending,
    TaskStatus.designing,
    TaskStatus.waitingApproval,
    TaskStatus.clientApproved,
    TaskStatus.revision,
  ]),
  _StageGroup('Production', Color(0xFF2563EB), [
    TaskStatus.waitingPrinting,
    TaskStatus.printing,
    TaskStatus.printingCompleted,
    TaskStatus.finishing,
    TaskStatus.productionCompleted,
  ]),
  _StageGroup('Delivery', Color(0xFF0EA5E9), [
    TaskStatus.waitingDelivery,
    TaskStatus.delivery,
    TaskStatus.delivered,
  ]),
  _StageGroup('Installation', Color(0xFF10B981), [
    TaskStatus.waitingInstallation,
    TaskStatus.installing,
    TaskStatus.completed,
  ]),
  _StageGroup('Other', Color(0xFF94A3B8), [
    TaskStatus.blocked,
    TaskStatus.paused,
  ]),
];

// ─────────────────────────────────────────────────────────────────────────────
// BOARD VIEW
// ─────────────────────────────────────────────────────────────────────────────
class BoardView extends StatefulWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final int? selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  final VoidCallback onAddTask;
  final FocusNode addTaskFocusNode;
  final bool isAddingTask;
  final String? selectedProjectId;

  const BoardView({
    super.key,
    required this.tasks,
    required this.projects,
    required this.selectedTaskId,
    required this.onTaskSelected,
    required this.onAddTask,
    required this.addTaskFocusNode,
    required this.isAddingTask,
    required this.selectedProjectId,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  final Set<TaskStatus> _hidden = {};
  final Set<int> _expandedGroups = {};
  bool _hideEmpty = false;

  static const _kHideEmptyKey = 'board_view_hide_empty';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kHideEmptyKey) ?? false;
    if (saved != _hideEmpty) setState(() => _hideEmpty = saved);
  }

  Future<void> _saveHideEmpty(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHideEmptyKey, value);
  }

  bool _groupFullyOn(int gi) =>
      _kGroups[gi].statuses.every((s) => !_hidden.contains(s));

  bool _groupPartial(int gi) {
    final g = _kGroups[gi];
    return g.statuses.any((s) => !_hidden.contains(s)) &&
        g.statuses.any((s) => _hidden.contains(s));
  }

  void _toggleGroup(int gi) => setState(() {
    final g = _kGroups[gi];
    _groupFullyOn(gi)
        ? _hidden.addAll(g.statuses)
        : _hidden.removeAll(g.statuses);
  });

  void _toggleStage(TaskStatus s) =>
      setState(() => _hidden.contains(s) ? _hidden.remove(s) : _hidden.add(s));

  void _toggleExpand(int gi) => setState(
    () =>
        _expandedGroups.contains(gi)
            ? _expandedGroups.remove(gi)
            : _expandedGroups.add(gi),
  );

  void _toggleHideEmpty() {
    final next = !_hideEmpty;
    setState(() => _hideEmpty = next);
    _saveHideEmpty(next);
  }

  @override
  Widget build(BuildContext context) {
    final Map<TaskStatus, int> taskCounts = {
      for (final si in kStages)
        si.stage: widget.tasks.where((t) => t.status == si.stage).length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Filter bar ───────────────────────────────────────────────────────
        _FilterBar(
          groups: _kGroups,
          groupFullyOn: _groupFullyOn,
          groupPartial: _groupPartial,
          expandedGroups: _expandedGroups,
          hidden: _hidden,
          hideEmpty: _hideEmpty,
          onToggleGroup: _toggleGroup,
          onToggleStage: _toggleStage,
          onToggleExpand: _toggleExpand,
          onToggleHideEmpty: _toggleHideEmpty,
        ),

        // ── Lane scroll ──────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: _T.slate50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              children:
                  kStages
                      .where((si) {
                        if (_hidden.contains(si.stage)) return false;
                        if (_hideEmpty) {
                          final count = taskCounts[si.stage] ?? 0;
                          if (count == 0) return false;
                        }
                        return true;
                      })
                      .map((si) {
                        final stageTasks =
                            widget.tasks
                                .where((t) => t.status == si.stage)
                                .toList();
                        final isFirst = kStages.indexOf(si) == 0;
                        return _KanbanLane(
                          stageInfo: si,
                          tasks: stageTasks,
                          projects: widget.projects,
                          selectedTaskId: widget.selectedTaskId,
                          onTaskSelected: widget.onTaskSelected,
                          showAddTaskBtn: si.label == 'Initialized',
                          addTaskFocusNode:
                              isFirst ? widget.addTaskFocusNode : null,
                          isAddingTask: isFirst ? widget.isAddingTask : null,
                          selectedProjectId: widget.selectedProjectId,
                        );
                      })
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER BAR
//
// Modern pill-style tab controls. Active group = filled slate100 pill.
// No underlines. Group color appears only in the drawer's left rule.
// Right side: "With tasks" toggle styled identically to group pills.
//
// Structure:
//   ┌──────────────────────────────────────────────────────┬──────────────┐
//   │  [Design ∨]  [Production ∨]  [Delivery ∨]  …        │ [With tasks] │
//   └──────────────────────────────────────────────────────┴──────────────┘
//   ┌ group-color left rule ───────────────────────────────────────────────┐
//   │  ☑ Pending  ☑ Designing  ☐ Waiting Approval  ☑ …       [Done]       │
//   └──────────────────────────────────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final List<_StageGroup> groups;
  final bool Function(int) groupFullyOn;
  final bool Function(int) groupPartial;
  final Set<int> expandedGroups;
  final Set<TaskStatus> hidden;
  final bool hideEmpty;
  final ValueChanged<int> onToggleGroup;
  final ValueChanged<TaskStatus> onToggleStage;
  final ValueChanged<int> onToggleExpand;
  final VoidCallback onToggleHideEmpty;

  const _FilterBar({
    required this.groups,
    required this.groupFullyOn,
    required this.groupPartial,
    required this.expandedGroups,
    required this.hidden,
    required this.hideEmpty,
    required this.onToggleGroup,
    required this.onToggleStage,
    required this.onToggleExpand,
    required this.onToggleHideEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tab row ────────────────────────────────────────────────────────
          Container(
            height: 44,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate100, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Group tabs
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        groups.length,
                        (gi) => Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: _GroupTab(
                            group: groups[gi],
                            isOn: groupFullyOn(gi),
                            isPartial: groupPartial(gi),
                            isExpanded: expandedGroups.contains(gi),
                            onTap: () => onToggleGroup(gi),
                            onExpand: () => onToggleExpand(gi),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 20,
                  color: _T.slate200,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),

                // "With tasks" toggle — same pill style as group tabs
                _HideEmptyToggle(isOn: hideEmpty, onTap: onToggleHideEmpty),
              ],
            ),
          ),

          // ── Detail drawers ─────────────────────────────────────────────────
          for (int gi = 0; gi < groups.length; gi++)
            _AnimatedDrawer(
              visible: expandedGroups.contains(gi),
              child: _DetailDrawer(
                group: groups[gi],
                hidden: hidden,
                onToggle: onToggleStage,
                onCollapse: () => onToggleExpand(gi),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GROUP TAB — pill style
//
// Off:     transparent bg, slate500 text
// Partial: slate100 bg, ink3 text, faint colored left-dot
// On:      slate100 bg, ink2 text, bold
// Chevron: always visible when on/partial, fades in on hover otherwise
// ─────────────────────────────────────────────────────────────────────────────
class _GroupTab extends StatefulWidget {
  final _StageGroup group;
  final bool isOn;
  final bool isPartial;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onExpand;

  const _GroupTab({
    required this.group,
    required this.isOn,
    required this.isPartial,
    required this.isExpanded,
    required this.onTap,
    required this.onExpand,
  });

  @override
  State<_GroupTab> createState() => _GroupTabState();
}

class _GroupTabState extends State<_GroupTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isOn || widget.isPartial;
    final Color bg = active || _hovered ? _T.slate100 : Colors.transparent;
    final Color fg = active ? _T.ink2 : (_hovered ? _T.ink3 : _T.slate500);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Label tap target
              GestureDetector(
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Colored dot — visible when active
                      AnimatedOpacity(
                        opacity: active ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 140),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.group.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 120),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          color: fg,
                          letterSpacing: 0.0,
                        ),
                        child: Text(widget.group.label),
                      ),
                    ],
                  ),
                ),
              ),

              // Chevron — expand drawer
              AnimatedOpacity(
                opacity: (active || _hovered) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 120),
                child: GestureDetector(
                  onTap: widget.onExpand,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
                    child: AnimatedRotation(
                      turns: widget.isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: active ? _T.slate400 : _T.slate300,
                      ),
                    ),
                  ),
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
// HIDE EMPTY TOGGLE — matches group tab pill style exactly
// ─────────────────────────────────────────────────────────────────────────────
class _HideEmptyToggle extends StatefulWidget {
  final bool isOn;
  final VoidCallback onTap;
  const _HideEmptyToggle({required this.isOn, required this.onTap});

  @override
  State<_HideEmptyToggle> createState() => _HideEmptyToggleState();
}

class _HideEmptyToggleState extends State<_HideEmptyToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isOn || _hovered ? _T.slate100 : Colors.transparent;
    final Color fg = widget.isOn ? _T.ink2 : (_hovered ? _T.ink3 : _T.slate500);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  opacity: widget.isOn ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 140),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_rounded, size: 11, color: _T.ink3),
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 120),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isOn ? FontWeight.w600 : FontWeight.w400,
                    color: fg,
                  ),
                  child: const Text('With tasks'),
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
// ANIMATED DRAWER WRAPPER — unchanged logic, same timing
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedDrawer extends StatefulWidget {
  final bool visible;
  final Widget child;
  const _AnimatedDrawer({required this.visible, required this.child});

  @override
  State<_AnimatedDrawer> createState() => _AnimatedDrawerState();
}

class _AnimatedDrawerState extends State<_AnimatedDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    if (widget.visible) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedDrawer old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      if (widget.visible) {
        _ctrl.duration = const Duration(milliseconds: 200);
        _ctrl.forward();
      } else {
        _ctrl.duration = const Duration(milliseconds: 130);
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: widget.visible || _ctrl.isAnimating ? null : 0,
        child: FadeTransition(opacity: _fade, child: widget.child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL DRAWER
//
// Redesign: no top/bottom borders. Only left rule (group color) + a very
// subtle slate50 background separates it from the filter row above.
// Stage items are compact chips rather than full-height rows.
// ─────────────────────────────────────────────────────────────────────────────
class _DetailDrawer extends StatelessWidget {
  final _StageGroup group;
  final Set<TaskStatus> hidden;
  final ValueChanged<TaskStatus> onToggle;
  final VoidCallback onCollapse;

  const _DetailDrawer({
    required this.group,
    required this.hidden,
    required this.onToggle,
    required this.onCollapse,
  });

  static String _label(TaskStatus s) => switch (s) {
    TaskStatus.pending => 'Pending',
    TaskStatus.designing => 'Designing',
    TaskStatus.waitingApproval => 'Waiting Approval',
    TaskStatus.clientApproved => 'Client Approved',
    TaskStatus.revision => 'Revision',
    TaskStatus.waitingPrinting => 'Waiting Printing',
    TaskStatus.printing => 'Printing',
    TaskStatus.printingCompleted => 'Print Done',
    TaskStatus.finishing => 'Finishing',
    TaskStatus.productionCompleted => 'Production Done',
    TaskStatus.waitingDelivery => 'Waiting Delivery',
    TaskStatus.delivery => 'Delivery',
    TaskStatus.delivered => 'Delivered',
    TaskStatus.waitingInstallation => 'Waiting Install',
    TaskStatus.installing => 'Installing',
    TaskStatus.completed => 'Completed',
    TaskStatus.blocked => 'Blocked',
    TaskStatus.paused => 'Paused',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.slate50,
        border: Border(
          top: const BorderSide(color: _T.slate100),
          left: BorderSide(color: group.color, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children:
                    group.statuses
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _StageChip(
                              label: _label(s),
                              isVisible: !hidden.contains(s),
                              onTap: () => onToggle(s),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),

          // Done button
          GestureDetector(
            onTap: onCollapse,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _T.white,
                  border: Border.all(color: _T.slate200),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _T.slate500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE CHIP — compact chip inside the detail drawer
//
// Visible:  white bg, ink2 text, checkmark icon, slate200 border
// Hidden:   transparent bg, slate400 text, empty-box icon, no border
// ─────────────────────────────────────────────────────────────────────────────
class _StageChip extends StatefulWidget {
  final String label;
  final bool isVisible;
  final VoidCallback onTap;

  const _StageChip({
    required this.label,
    required this.isVisible,
    required this.onTap,
  });

  @override
  State<_StageChip> createState() => _StageChipState();
}

class _StageChipState extends State<_StageChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bg =
        widget.isVisible
            ? (_hovered ? _T.slate100 : _T.white)
            : (_hovered ? _T.slate100 : Colors.transparent);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: widget.isVisible ? _T.slate200 : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 110),
                  child: Icon(
                    widget.isVisible
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    key: ValueKey(widget.isVisible),
                    size: 13,
                    color: widget.isVisible ? _T.ink3 : _T.slate300,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 110),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        widget.isVisible ? FontWeight.w500 : FontWeight.w400,
                    color: widget.isVisible ? _T.ink2 : _T.slate400,
                  ),
                  child: Text(widget.label),
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
// KANBAN LANE
//
// Redesign highlights:
//   • No border — replaced by a soft shadow for panel elevation
//   • 2px colored top accent strip (full width, group color)
//   • Header: cleaner spacing, count badge uses colored text on neutral bg
//   • Empty state: ultra-minimal ghost
//   • Add task: dashed ghost row at the bottom
// ─────────────────────────────────────────────────────────────────────────────
class _KanbanLane extends ConsumerStatefulWidget {
  final DesignStageInfo stageInfo;
  final List<Task> tasks;
  final List<Project> projects;
  final int? selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  @Deprecated("Either fix the existing bug on this or remove it completely")
  final bool showAddTaskBtn;
  final FocusNode? addTaskFocusNode;
  bool? isAddingTask;
  String? selectedProjectId;

  _KanbanLane({
    required this.stageInfo,
    required this.tasks,
    required this.projects,
    required this.selectedTaskId,
    required this.onTaskSelected,
    required this.showAddTaskBtn,
    required this.addTaskFocusNode,
    required this.isAddingTask,
    required this.selectedProjectId,
  });

  @override
  ConsumerState<_KanbanLane> createState() => _KanbanLaneState();
}

class _KanbanLaneState extends ConsumerState<_KanbanLane> {
  void onAddTask() {
    widget.addTaskFocusNode?.requestFocus();
    setState(() => widget.isAddingTask = true);
  }

  void onDismiss() => setState(() => widget.isAddingTask = false);
  void onCreated(Task task) => setState(() => widget.isAddingTask = false);

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.stageInfo.stage == TaskStatus.clientApproved;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 0),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_T.rLg),
        child: Column(
          children: [
            // ── Colored top accent strip ─────────────────────────────────────
            Container(height: 2.5, color: widget.stageInfo.color),

            // ── Lane header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.slate100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (isApproved) ...[
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 11,
                            color: widget.stageInfo.color,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            widget.stageInfo.label,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _T.ink,
                              letterSpacing: 0.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Task count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isApproved
                              ? widget.stageInfo.color.withOpacity(0.10)
                              : _T.slate100,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${widget.tasks.length}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color:
                            isApproved ? widget.stageInfo.color : _T.slate500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Task list ────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  if (widget.tasks.isEmpty)
                    _LaneEmpty()
                  else
                    ...widget.tasks.map((t) {
                      final proj =
                          widget.projects.cast<Project?>().firstWhere(
                            (p) => p!.id == t.projectId,
                            orElse: () => null,
                          ) ??
                          widget.projects.first;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: TaskCard(
                          task: t,
                          project: proj,
                          isSelected: widget.selectedTaskId == t.id,
                          onTap: () => widget.onTaskSelected(t.id),
                          selectedProjectId: widget.selectedProjectId,
                        ),
                      );
                    }),
                ],
              ),
            ),

            // ── Add task ─────────────────────────────────────────────────────
            // if (widget.showAddTaskBtn)
            //   widget.isAddingTask == true
            //       ? Focus(
            //           focusNode: widget.addTaskFocusNode,
            //           autofocus: true,
            //           child: TaskCard.add(
            //             onCreated:         onCreated,
            //             onDismiss:         onDismiss,
            //             projects:          ref.watch(projectNotifierProvider),
            //             selectedProjectId: widget.selectedProjectId,
            //           ),
            //         )
            //       : Padding(
            //           padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            //           child: _AddCardButton(onTap: onAddTask),
            //         ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LANE EMPTY STATE — very minimal ghost
// ─────────────────────────────────────────────────────────────────────────────
class _LaneEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        Icon(Icons.inbox_outlined, size: 20, color: _T.slate300),
        SizedBox(height: 6),
        Text(
          'No tasks',
          style: TextStyle(
            fontSize: 11.5,
            color: _T.slate300,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD CARD BUTTON — ghost dashed style
// ─────────────────────────────────────────────────────────────────────────────
class _AddCardButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddCardButton({required this.onTap});

  @override
  State<_AddCardButton> createState() => _AddCardButtonState();
}

class _AddCardButtonState extends State<_AddCardButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _hovered ? _T.slate50 : Colors.transparent,
            border: Border.all(
              color: _hovered ? _T.slate300 : _T.slate200,
              // A "dashed" feel through slightly thinner stroke and color
            ),
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_T.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 13,
                  color: _hovered ? _T.slate500 : _T.slate400,
                ),
                const SizedBox(width: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 120),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _hovered ? _T.slate500 : _T.slate400,
                  ),
                  child: const Text('Add task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
