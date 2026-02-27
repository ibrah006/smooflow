// ─────────────────────────────────────────────────────────────────────────────
// BOARD VIEW
//
// Lane visibility is controlled by a filter bar above the board.
// Each pill in the filter bar corresponds to a stage group. Tapping a pill
// toggles all lanes in that group on/off. A chevron on each pill expands a
// detail chip row for fine-grained per-lane control.
//
// No hover, no collapse, no expand — the board is always fully rendered.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/desktop/components/task_card.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (identical to your _T class in design_dashboard.dart)
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

  static const sidebarW = 220.0;
  static const topbarH  = 52.0;
  static const detailW  = 400.0;

  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE GROUPS
//
// 5 phase groups. Toggling a group pill shows/hides all its lanes at once.
// The most common action (hide a whole phase) costs exactly 1 tap.
// ─────────────────────────────────────────────────────────────────────────────
class _StageGroup {
  final String           label;
  final Color            color;
  final List<TaskStatus> statuses;
  const _StageGroup(this.label, this.color, this.statuses);
}

const _kGroups = <_StageGroup>[
  _StageGroup('Design',       Color(0xFF8B5CF6), [
    TaskStatus.pending,
    TaskStatus.designing,
    TaskStatus.waitingApproval,
    TaskStatus.clientApproved,
    TaskStatus.revision,
  ]),
  _StageGroup('Production',   Color(0xFF2563EB), [
    TaskStatus.waitingPrinting,
    TaskStatus.printing,
    TaskStatus.printingCompleted,
    TaskStatus.finishing,
    TaskStatus.productionCompleted,
  ]),
  _StageGroup('Delivery',     Color(0xFF0EA5E9), [
    TaskStatus.waitingDelivery,
    TaskStatus.delivery,
    TaskStatus.delivered,
  ]),
  _StageGroup('Installation', Color(0xFF10B981), [
    TaskStatus.waitingInstallation,
    TaskStatus.installing,
    TaskStatus.completed,
  ]),
  _StageGroup('Other',        Color(0xFF94A3B8), [
    TaskStatus.blocked,
    TaskStatus.paused,
  ]),
];

// ─────────────────────────────────────────────────────────────────────────────
// BOARD VIEW
// ─────────────────────────────────────────────────────────────────────────────
class BoardView extends StatefulWidget {
  final List<Task>        tasks;
  final List<Project>     projects;
  final int?              selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  final VoidCallback      onAddTask;
  final FocusNode         addTaskFocusNode;
  final bool              isAddingTask;
  final String?           selectedProjectId;

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
  // Statuses whose lanes are currently hidden. Empty = all visible (default).
  final Set<TaskStatus> _hidden = {};

  // Which group indices have their detail chip row open.
  final Set<int> _expandedGroups = {};

  // hide lanes that have zero tasks
  bool _hideEmpty = false;

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _groupFullyOn(int gi) =>
      _kGroups[gi].statuses.every((s) => !_hidden.contains(s));

  bool _groupPartial(int gi) {
    final g = _kGroups[gi];
    return g.statuses.any((s) => !_hidden.contains(s)) &&
           g.statuses.any((s) =>  _hidden.contains(s));
  }

  void _toggleGroup(int gi) => setState(() {
    final g = _kGroups[gi];
    _groupFullyOn(gi)
        ? _hidden.addAll(g.statuses)
        : _hidden.removeAll(g.statuses);
  });

  void _toggleStage(TaskStatus s) => setState(() =>
      _hidden.contains(s) ? _hidden.remove(s) : _hidden.add(s));

  void _toggleExpand(int gi) => setState(() =>
      _expandedGroups.contains(gi)
          ? _expandedGroups.remove(gi)
          : _expandedGroups.add(gi));

  @override
  Widget build(BuildContext context) {
    // Build the task-count map once so the filter bar can display it
    final Map<TaskStatus, int> taskCounts = {
      for (final si in kStages)
        si.stage: widget.tasks.where((t) => t.status == si.stage).length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // ── Filter bar ───────────────────────────────────────────────────────
        _FilterBar(
          groups:          _kGroups,
          groupFullyOn:    _groupFullyOn,
          groupPartial:    _groupPartial,
          expandedGroups:  _expandedGroups,
          hidden:          _hidden,
          hideEmpty:       _hideEmpty,
          onToggleGroup:   _toggleGroup,
          onToggleStage:   _toggleStage,
          onToggleExpand:  _toggleExpand,
          onToggleHideEmpty: () => setState(() => _hideEmpty = !_hideEmpty),
        ),

        // ── Lane scroll ──────────────────────────────────────────────────────
        Expanded(
          child: Container(
            // color: _T.slate50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              children: kStages
                  .where((si) {
                    // Stage-group visibility filter
                    if (_hidden.contains(si.stage)) return false;
                    // Hide-empty filter
                    if (_hideEmpty) {
                      final count = taskCounts[si.stage] ?? 0;
                      if (count == 0) return false;
                    }
                    return true;
                  })
                  .map((si) {
                    final stageTasks = widget.tasks
                        .where((t) => t.status == si.stage)
                        .toList();

                    // Original: hide pending lane when empty (unless hideEmpty
                    // already handled it above)
                    if (si.stage == TaskStatus.pending && stageTasks.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final isFirst = kStages.indexOf(si) == 0;

                    return _KanbanLane(
                      stageInfo:         si,
                      tasks:             stageTasks,
                      projects:          widget.projects,
                      selectedTaskId:    widget.selectedTaskId,
                      onTaskSelected:    widget.onTaskSelected,
                      showAddTaskBtn:    si.label == 'Initialized',
                      addTaskFocusNode:  isFirst ? widget.addTaskFocusNode : null,
                      isAddingTask:      isFirst ? widget.isAddingTask : null,
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
// Corporate design principles:
//   • White surface, slate200 bottom rule — no tinting
//   • "STAGES" label: uppercase, tracked, muted — signals control surface
//   • Group controls are tab-style text buttons, not coloured pills
//   • Active state = ink text + 2 px bottom underline (tab metaphor)
//   • Colour appears ONLY in the 3 px left rule of the detail drawer
//   • Detail drawer: checkbox-style rows, ink/slate only — no colour fills
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// FILTER BAR
//
// Corporate toolbar — flat, typographic, no coloured fills anywhere.
//
// Structure:
//   ┌─────────────────────────────────────────────────────────────┐
//   │  STAGES │ [Design ∨]  [Production ∨]  [Delivery ∨]  …      │  ← 40px
//   ├─────────────────────────────────────────────────────────────┤
//   │  Design │ ☑ Pending  ☑ Designing  ☐ Waiting…  Done         │  ← 36px
//   └─────────────────────────────────────────────────────────────┘
//
// Active tab:   ink2 text + 2px solid bottom border in ink2.
// Partial tab:  ink3 text + 1.5px slate400 bottom border.
// Off tab:      slate400 text, no border. Chevron visible on hover.
//
// Detail drawer: white bg, 3px left rule in group colour (sole colour use).
// Stage items: checkbox-style ☑/☐ rows. No fills, ink/slate only.
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// FILTER BAR
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final List<_StageGroup>        groups;
  final bool Function(int)       groupFullyOn;
  final bool Function(int)       groupPartial;
  final Set<int>                 expandedGroups;
  final Set<TaskStatus>          hidden;
  final bool                     hideEmpty;
  final ValueChanged<int>        onToggleGroup;
  final ValueChanged<TaskStatus> onToggleStage;
  final ValueChanged<int>        onToggleExpand;
  final VoidCallback             onToggleHideEmpty;

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
            height: 40,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate200)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // "STAGES" prefix
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: _T.slate200)),
                  ),
                  child: const Text(
                    'STAGES',
                    style: TextStyle(
                      fontSize:      9.5,
                      fontWeight:    FontWeight.w700,
                      color:         _T.slate400,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),

                // Group tabs — scrollable
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(groups.length, (gi) =>
                        _GroupTab(
                          group:      groups[gi],
                          isOn:       groupFullyOn(gi),
                          isPartial:  groupPartial(gi),
                          isExpanded: expandedGroups.contains(gi),
                          onTap:      () => onToggleGroup(gi),
                          onExpand:   () => onToggleExpand(gi),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── "With tasks" toggle ──────────────────────────────────────
                // Right-anchored. A vertical divider separates it from the tabs.
                // When on: ink2 text + filled indicator dot.
                // When off: slate400 text — recedes exactly like an inactive tab.
                Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: _T.slate200)),
                  ),
                  child: _HideEmptyToggle(
                    isOn:  hideEmpty,
                    onTap: onToggleHideEmpty,
                  ),
                ),

              ],
            ),
          ),

          // ── Detail drawers ─────────────────────────────────────────────────
          // Each drawer is individually animated with AnimatedSize (height) +
          // AnimatedOpacity (fade). They animate independently so opening one
          // doesn't affect another.
          for (int gi = 0; gi < groups.length; gi++)
            _AnimatedDrawer(
              visible: expandedGroups.contains(gi),
              child: _DetailDrawer(
                group:      groups[gi],
                hidden:     hidden,
                onToggle:   onToggleStage,
                onCollapse: () => onToggleExpand(gi),
              ),
            ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HIDE EMPTY TOGGLE
//
// Lives at the right end of the tab row. Styled as a tab-like control so it
// reads as part of the same toolbar, not a foreign widget.
//
// States:
//   Off → slate400 text, no indicator — blends with inactive tabs.
//   On  → ink2 text, small filled dot to the left of the label, 2px ink2
//         bottom border — identical active-tab language.
//
// Label reads "With tasks" — positive framing. The user is choosing what they
// want to see, not what to hide.
// ─────────────────────────────────────────────────────────────────────────────
class _HideEmptyToggle extends StatefulWidget {
  final bool         isOn;
  final VoidCallback onTap;

  const _HideEmptyToggle({required this.isOn, required this.onTap});

  @override
  State<_HideEmptyToggle> createState() => _HideEmptyToggleState();
}

class _HideEmptyToggleState extends State<_HideEmptyToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color fg = widget.isOn
        ? (_hovered ? _T.ink : _T.ink2)
        : (_hovered ? _T.ink3 : _T.slate400);

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _hovered ? _T.slate50 : Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            // 2px bottom border mirrors active-tab language
            decoration: BoxDecoration(
              
              border: Border(
                bottom: widget.isOn
                    ? const BorderSide(color: _T.ink2, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Small filled dot — appears only when on
                AnimatedOpacity(
                  opacity:  widget.isOn ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: 5, height: 5,
                      decoration: const BoxDecoration(
                        color: _T.ink2,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 130),
                  style: TextStyle(
                    fontSize:   11.5,
                    fontWeight: widget.isOn ? FontWeight.w600 : FontWeight.w400,
                    color:      fg,
                    letterSpacing: 0.1,
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
// ANIMATED DRAWER WRAPPER
//
// Wraps each _DetailDrawer. Uses:
//   • AnimatedSize  — smoothly grows/shrinks the height (clipBehavior clips
//                     content during the transition so nothing overflows).
//   • AnimatedOpacity — fades content in (200ms) and out (120ms, faster so
//                     the collapse feels snappy rather than sluggish).
//
// The asymmetric timing (faster out than in) is a standard motion principle:
// exit transitions should be quicker so they don't block the user's next action.
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedDrawer extends StatefulWidget {
  final bool    visible;
  final Widget  child;

  const _AnimatedDrawer({required this.visible, required this.child});

  @override
  State<_AnimatedDrawer> createState() => _AnimatedDrawerState();
}

class _AnimatedDrawerState extends State<_AnimatedDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 200), // open
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    if (widget.visible) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedDrawer old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      if (widget.visible) {
        // Open: forward at full duration
        _ctrl.duration = const Duration(milliseconds: 200);
        _ctrl.forward();
      } else {
        // Close: reverse faster — snappy exit
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
      duration:      const Duration(milliseconds: 200),
      curve:         Curves.easeOutCubic,
      clipBehavior:  Clip.hardEdge,
      alignment:     Alignment.topCenter,
      child: SizedBox(
        // SizedBox drives AnimatedSize: visible → natural height, hidden → 0.
        height: widget.visible || _ctrl.isAnimating ? null : 0,
        child: FadeTransition(
          opacity: _fade,
          child:   widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GROUP TAB
// ─────────────────────────────────────────────────────────────────────────────
class _GroupTab extends StatefulWidget {
  final _StageGroup  group;
  final bool         isOn;
  final bool         isPartial;
  final bool         isExpanded;
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
    final bool  active     = widget.isOn || widget.isPartial;
    final Color labelColor = active
        ? (_hovered ? _T.ink : _T.ink2)
        : (_hovered ? _T.ink3 : _T.slate400);

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Container(
        color: _hovered ? _T.slate50 : Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          decoration: BoxDecoration(
            border: Border(
              bottom: widget.isOn
                  ? const BorderSide(color: _T.ink2, width: 2)
                  : widget.isPartial
                      ? BorderSide(color: _T.slate400, width: 1.5)
                      : BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisSize:       MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              GestureDetector(
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 4, 0),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 130),
                    style: TextStyle(
                      fontSize:      11.5,
                      fontWeight:    widget.isOn
                          ? FontWeight.w600
                          : widget.isPartial
                              ? FontWeight.w500
                              : FontWeight.w400,
                      color:         labelColor,
                      letterSpacing: 0.1,
                    ),
                    child: Text(widget.group.label),
                  ),
                ),
              ),

              AnimatedOpacity(
                opacity:  (active || _hovered) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 130),
                child: GestureDetector(
                  onTap:    widget.onExpand,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 12, 0),
                    child: AnimatedRotation(
                      turns:    widget.isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size:  13,
                        color: active ? _T.slate500 : _T.slate300,
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
// DETAIL DRAWER
// ─────────────────────────────────────────────────────────────────────────────
class _DetailDrawer extends StatelessWidget {
  final _StageGroup              group;
  final Set<TaskStatus>          hidden;
  final ValueChanged<TaskStatus> onToggle;
  final VoidCallback             onCollapse;

  const _DetailDrawer({
    required this.group,
    required this.hidden,
    required this.onToggle,
    required this.onCollapse,
  });

  static String _label(TaskStatus s) => switch (s) {
    TaskStatus.pending             => 'Pending',
    TaskStatus.designing           => 'Designing',
    TaskStatus.waitingApproval     => 'Waiting Approval',
    TaskStatus.clientApproved      => 'Client Approved',
    TaskStatus.revision            => 'Revision',
    TaskStatus.waitingPrinting     => 'Waiting Printing',
    TaskStatus.printing            => 'Printing',
    TaskStatus.printingCompleted   => 'Print Done',
    TaskStatus.finishing           => 'Finishing',
    TaskStatus.productionCompleted => 'Production Done',
    TaskStatus.waitingDelivery     => 'Waiting Delivery',
    TaskStatus.delivery            => 'Delivery',
    TaskStatus.delivered           => 'Delivered',
    TaskStatus.waitingInstallation => 'Waiting Install',
    TaskStatus.installing          => 'Installing',
    TaskStatus.completed           => 'Completed',
    TaskStatus.blocked             => 'Blocked',
    TaskStatus.paused              => 'Paused',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        border: Border(
          top:    const BorderSide(color: _T.slate200),
          bottom: const BorderSide(color: _T.slate200),
          left:   BorderSide(color: group.color, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                children: group.statuses.map((s) =>
                  _StageToggleRow(
                    label:     _label(s),
                    isVisible: !hidden.contains(s),
                    onTap:     () => onToggle(s),
                  ),
                ).toList(),
              ),
            ),
          ),

          GestureDetector(
            onTap: onCollapse,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      _T.slate500,
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
// STAGE TOGGLE ROW
// ─────────────────────────────────────────────────────────────────────────────
class _StageToggleRow extends StatefulWidget {
  final String       label;
  final bool         isVisible;
  final VoidCallback onTap;

  const _StageToggleRow({
    required this.label,
    required this.isVisible,
    required this.onTap,
  });

  @override
  State<_StageToggleRow> createState() => _StageToggleRowState();
}

class _StageToggleRowState extends State<_StageToggleRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _hovered ? _T.slate50 : Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            margin:   const EdgeInsets.only(right: 2),
            padding:  const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
            decoration: const BoxDecoration(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 120),
                  child: Icon(
                    widget.isVisible
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    key:   ValueKey(widget.isVisible),
                    size:  14,
                    color: widget.isVisible ? _T.ink3 : _T.slate300,
                  ),
                ),
                const SizedBox(width: 7),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 110),
                  style: TextStyle(
                    fontSize:   11.5,
                    fontWeight: widget.isVisible ? FontWeight.w500 : FontWeight.w400,
                    color:      widget.isVisible ? _T.ink2 : _T.slate400,
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
// KANBAN LANE — original, unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _KanbanLane extends ConsumerStatefulWidget {
  final DesignStageInfo   stageInfo;
  final List<Task>        tasks;
  final List<Project>     projects;
  final int?              selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  final bool              showAddTaskBtn;
  final FocusNode?        addTaskFocusNode;
  bool?                   isAddingTask;
  String?                 selectedProjectId;

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

  void onDismiss()           => setState(() => widget.isAddingTask = false);
  void onCreated(Task task)  => setState(() => widget.isAddingTask = false);

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.stageInfo.stage == TaskStatus.clientApproved;

    return Container(
      width:  258,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color:        _T.white,
        border:       Border.all(color: _T.slate200),
        borderRadius: BorderRadius.circular(_T.rLg),
      ),
      child: Column(
        children: [

          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 3, height: 16,
                  decoration: BoxDecoration(
                    color:        widget.stageInfo.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.stageInfo.label,
                    style: const TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color:      _T.ink,
                    ),
                  ),
                ),
                if (isApproved) ...[
                  Icon(Icons.lock_outline, size: 12, color: widget.stageInfo.color),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color:        isApproved ? widget.stageInfo.bg : _T.slate100,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${widget.tasks.length}',
                    style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w700,
                      color: isApproved ? widget.stageInfo.color : _T.slate500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                if (widget.tasks.isEmpty)
                  _LaneEmpty()
                else
                  ...widget.tasks.map((t) {
                    final proj = widget.projects
                        .cast<Project?>()
                        .firstWhere(
                          (p) => p!.id == t.projectId,
                          orElse: () => null,
                        ) ??
                        widget.projects.first;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskCard(
                        task:              t,
                        project:           proj,
                        isSelected:        widget.selectedTaskId == t.id,
                        onTap:             () => widget.onTaskSelected(t.id),
                        selectedProjectId: widget.selectedProjectId,
                      ),
                    );
                  }),
              ],
            ),
          ),

          if (widget.showAddTaskBtn)
            widget.isAddingTask == true
                ? Focus(
                    focusNode: widget.addTaskFocusNode,
                    autofocus: true,
                    child: TaskCard.add(
                      onCreated:         onCreated,
                      onDismiss:         onDismiss,
                      projects:          ref.watch(projectNotifierProvider),
                      selectedProjectId: widget.selectedProjectId,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: _AddCardButton(onTap: onAddTask),
                  ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LANE EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// ADD CARD BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _AddCardButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(_T.r),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(_T.r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border:       Border.all(color: _T.slate200, width: 1.5),
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 13, color: _T.slate400),
              SizedBox(width: 6),
              Text(
                'Add task',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: _T.slate400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}