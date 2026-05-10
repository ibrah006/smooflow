// ─────────────────────────────────────────────────────────────────────────────
// BOARD VIEW — drag-and-drop + refined interactions
//
// Changes from previous version:
//   • BoardView is now ConsumerStatefulWidget (needs ref for task API)
//   • Drag-and-drop: each TaskCard is Draggable; each lane is a DragTarget
//   • _CardProgressOverlay: subtle 2px progress bar + direction pill on
//     in-transit cards — shown in the SOURCE lane while the API is in-flight
//   • Lane hover: shadow deepens slightly; drag-over tints bg + colored border
//   • Drag feedback: card at scale(1.02) with elevated shadow, no decoration
//   • All other logic (filter bar, drawers, chips, prefs) is unchanged
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/task_card.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

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
// DRAG & DROP DATA TYPES
// ─────────────────────────────────────────────────────────────────────────────

/// Payload carried by the Draggable between source and target lanes.
class _DragPayload {
  final int taskId;
  final TaskStatus fromStage;
  const _DragPayload({required this.taskId, required this.fromStage});
}

enum _DragPhase { loading, completing }

/// Tracks a card that is currently being moved via the API.
class _InTransitTask {
  final int taskId;
  final TaskStatus fromStage;
  final TaskStatus toStage;
  final bool isForward;
  final _DragPhase phase;

  const _InTransitTask({
    required this.taskId,
    required this.fromStage,
    required this.toStage,
    required this.isForward,
    required this.phase,
  });

  _InTransitTask copyWith({_DragPhase? phase}) => _InTransitTask(
    taskId: taskId,
    fromStage: fromStage,
    toStage: toStage,
    isForward: isForward,
    phase: phase ?? this.phase,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BOARD VIEW
// ─────────────────────────────────────────────────────────────────────────────
class BoardView extends ConsumerStatefulWidget {
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
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView> {
  final Set<TaskStatus> _hidden = {};
  final Set<int> _expandedGroups = {};
  bool _hideEmpty = false;

  // Tracks cards currently being moved via the API
  final Map<int, _InTransitTask> _inTransit = {};

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

  // ── Drag direction ─────────────────────────────────────────────────────────
  bool _isForwardMove(TaskStatus from, TaskStatus to) {
    final fromIdx = kStages.indexWhere((si) => si.stage == from);
    final toIdx = kStages.indexWhere((si) => si.stage == to);
    return toIdx > fromIdx;
  }

  // ── Drop handler ───────────────────────────────────────────────────────────
  Future<void> _onTaskDropped({
    required int taskId,
    required TaskStatus fromStage,
    required TaskStatus toStage,
  }) async {
    if (fromStage == toStage) return;
    final isForward = _isForwardMove(fromStage, toStage);

    setState(() {
      _inTransit[taskId] = _InTransitTask(
        taskId: taskId,
        fromStage: fromStage,
        toStage: toStage,
        isForward: isForward,
        phase: _DragPhase.loading,
      );
    });

    try {
      // Replace with your actual provider method.
      // Simulate api - update progress
      await Future.delayed(Duration(seconds: 2));

      if (!mounted) return;

      // Transition to completing phase (fills the progress bar)
      setState(() {
        _inTransit[taskId] = _inTransit[taskId]!.copyWith(
          phase: _DragPhase.completing,
        );
      });

      // Allow the completion animation to play before clearing
      await Future.delayed(const Duration(milliseconds: 700));
    } catch (_) {
      // On error: clear immediately — the task stays in its original lane
    } finally {
      if (mounted) setState(() => _inTransit.remove(taskId));
    }
  }

  // ── Filter bar helpers ─────────────────────────────────────────────────────
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
                        if (_hideEmpty && (taskCounts[si.stage] ?? 0) == 0)
                          return false;
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
                          inTransit: _inTransit,
                          onTaskDropped: _onTaskDropped,
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
// FILTER BAR  (unchanged)
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
          // Tab row
          Container(
            height: 44,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate100)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                Container(
                  width: 1,
                  height: 20,
                  color: _T.slate200,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                _HideEmptyToggle(isOn: hideEmpty, onTap: onToggleHideEmpty),
              ],
            ),
          ),
          // Detail drawers
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
// GROUP TAB  (unchanged)
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
            children: [
              InkWell(
                onTap: widget.onTap,
                splashColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        ),
                        child: Text(widget.group.label),
                      ),
                    ],
                  ),
                ),
              ),
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
// HIDE EMPTY TOGGLE  (unchanged)
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
// ANIMATED DRAWER  (unchanged)
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
// DETAIL DRAWER  (unchanged)
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
// STAGE CHIP  (unchanged)
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
// Improvements:
//   • MouseRegion hover: shadow deepens slightly (non-drag hover)
//   • DragTarget: colored border + faint bg tint when card hovers over lane
//   • Cards wrapped in Draggable with elevated feedback
//   • In-transit cards get _CardProgressOverlay stacked on top
// ─────────────────────────────────────────────────────────────────────────────
class _KanbanLane extends ConsumerStatefulWidget {
  final DesignStageInfo stageInfo;
  final List<Task> tasks;
  final List<Project> projects;
  final int? selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  @Deprecated('Fix or remove')
  final bool showAddTaskBtn;
  final FocusNode? addTaskFocusNode;
  bool? isAddingTask;
  final String? selectedProjectId;
  final Map<int, _InTransitTask> inTransit;
  final Future<void> Function({
    required int taskId,
    required TaskStatus fromStage,
    required TaskStatus toStage,
  })
  onTaskDropped;

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
    required this.inTransit,
    required this.onTaskDropped,
  });

  @override
  ConsumerState<_KanbanLane> createState() => _KanbanLaneState();
}

class _KanbanLaneState extends ConsumerState<_KanbanLane> {
  bool _laneHovered = false;

  void onAddTask() {
    widget.addTaskFocusNode?.requestFocus();
    setState(() => widget.isAddingTask = true);
  }

  void onDismiss() => setState(() => widget.isAddingTask = false);
  void onCreated(Task task) => setState(() => widget.isAddingTask = false);

  // Shadow levels
  List<BoxShadow> _shadows({bool hovered = false, bool dragOver = false}) {
    if (dragOver) {
      return [
        BoxShadow(
          color: widget.stageInfo.color.withOpacity(0.15),
          blurRadius: 14,
          offset: const Offset(0, 3),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(hovered ? 0.08 : 0.05),
        blurRadius: hovered ? 12 : 8,
        offset: Offset(0, hovered ? 3 : 1),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.03),
        blurRadius: 2,
        spreadRadius: 1,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.stageInfo.stage == TaskStatus.clientApproved;

    return MouseRegion(
      onEnter: (_) => setState(() => _laneHovered = true),
      onExit: (_) => setState(() => _laneHovered = false),
      child: DragTarget<_DragPayload>(
        onWillAcceptWithDetails:
            (details) => details.data.fromStage != widget.stageInfo.stage,
        onAcceptWithDetails: (details) {
          widget.onTaskDropped(
            taskId: details.data.taskId,
            fromStage: details.data.fromStage,
            toStage: widget.stageInfo.stage,
          );
        },
        builder: (context, candidateData, _) {
          final isDragOver = candidateData.isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 260,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color:
                  isDragOver
                      ? Color.lerp(
                        _T.white,
                        widget.stageInfo.color.withOpacity(0.06),
                        1.0,
                      )
                      : _T.white,
              borderRadius: BorderRadius.circular(_T.rLg),
              border:
                  isDragOver
                      ? Border.all(
                        color: widget.stageInfo.color.withOpacity(0.45),
                        width: 1.5,
                      )
                      : Border.all(color: Colors.transparent),
              boxShadow: _shadows(
                hovered: _laneHovered && !isDragOver,
                dragOver: isDragOver,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_T.rLg),
              child: Column(
                children: [
                  // ── Colored top accent strip ───────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: isDragOver ? 3.5 : 2.5,
                    color: widget.stageInfo.color,
                  ),

                  // ── Lane header ────────────────────────────────────────────
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
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Count badge — slightly animated on drag-over
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDragOver
                                    ? widget.stageInfo.color.withOpacity(0.12)
                                    : isApproved
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
                                  isDragOver || isApproved
                                      ? widget.stageInfo.color
                                      : _T.slate500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Task list ──────────────────────────────────────────────
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(10),
                      children: [
                        if (widget.tasks.isEmpty && !isDragOver)
                          _LaneEmpty()
                        else ...[
                          ...widget.tasks.map((t) {
                            final proj =
                                widget.projects.cast<Project?>().firstWhere(
                                  (p) => p!.id == t.projectId,
                                  orElse: () => null,
                                ) ??
                                widget.projects.first;

                            final transit = widget.inTransit[t.id];
                            final isInTransit = transit != null;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Draggable<_DragPayload>(
                                data: _DragPayload(
                                  taskId: t.id,
                                  fromStage: widget.stageInfo.stage,
                                ),
                                // While dragging: source card fades out
                                childWhenDragging: Opacity(
                                  opacity: 0.28,
                                  child: IgnorePointer(
                                    child: TaskCard(
                                      task: t,
                                      project: proj,
                                      isSelected: false,
                                      onTap: () {},
                                      selectedProjectId:
                                          widget.selectedProjectId,
                                    ),
                                  ),
                                ),
                                // Feedback: elevated card following cursor
                                feedback: _DragFeedback(
                                  task: t,
                                  project: proj,
                                  selectedProjectId: widget.selectedProjectId,
                                ),
                                // Normal / in-transit card
                                child: Stack(
                                  children: [
                                    TaskCard(
                                      task: t,
                                      project: proj,
                                      isSelected: widget.selectedTaskId == t.id,
                                      onTap: () => widget.onTaskSelected(t.id),
                                      selectedProjectId:
                                          widget.selectedProjectId,
                                    ),
                                    if (isInTransit)
                                      Positioned.fill(
                                        child: _CardProgressOverlay(
                                          isForward: transit!.isForward,
                                          isCompleting:
                                              transit.phase ==
                                              _DragPhase.completing,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          // Drop insertion hint when dragging over
                          if (isDragOver)
                            _DropInsertionHint(color: widget.stageInfo.color),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAG FEEDBACK  — elevated card at 1.02× scale following the cursor
// ─────────────────────────────────────────────────────────────────────────────
class _DragFeedback extends StatelessWidget {
  final Task task;
  final Project project;
  final String? selectedProjectId;

  const _DragFeedback({
    required this.task,
    required this.project,
    required this.selectedProjectId,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        // Lane content width: 260 lane - 10px padding each side = 240px
        width: 240,
        child: Transform.scale(
          scale: 1.02,
          alignment: Alignment.topCenter,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_T.rLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Opacity(
              opacity: 0.94,
              child: TaskCard(
                task: task,
                project: project,
                isSelected: false,
                onTap: () {},
                selectedProjectId: selectedProjectId,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DROP INSERTION HINT
// A dashed row at the bottom of the task list signalling "drop here".
// ─────────────────────────────────────────────────────────────────────────────
class _DropInsertionHint extends StatelessWidget {
  final Color color;
  const _DropInsertionHint({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
          // Dashed effect via strokeAlign — solid border is fine at this scale
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 13, color: color.withOpacity(0.6)),
            const SizedBox(width: 5),
            Text(
              'Drop here',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD PROGRESS OVERLAY
//
// Stacked on top of the TaskCard for cards being moved via the API.
//
// Visual:
//   • Direction pill (top-right): tiny spinner + arrow icon + label
//     Green  = moving forward  (↑)
//     Amber  = moving backward (↓)
//   • Thin progress bar at the card bottom
//     – Indeterminate shimmer while loading
//     – Fills 0→1 during completing phase, then fades out
//
// Kept deliberately subtle — the pill is 9.5px font and the bar is 2.5px.
// ─────────────────────────────────────────────────────────────────────────────
class _CardProgressOverlay extends StatefulWidget {
  final bool isForward;
  final bool isCompleting;

  const _CardProgressOverlay({
    required this.isForward,
    required this.isCompleting,
  });

  @override
  State<_CardProgressOverlay> createState() => _CardProgressOverlayState();
}

class _CardProgressOverlayState extends State<_CardProgressOverlay>
    with TickerProviderStateMixin {
  // Indeterminate shimmer (loading phase)
  late final AnimationController _shimmerCtrl;
  // Fill animation (completing phase)
  late final AnimationController _fillCtrl;
  // Fade-out of the entire overlay
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didUpdateWidget(_CardProgressOverlay old) {
    super.didUpdateWidget(old);
    // When parent transitions to completing, kick off the sequence
    if (!old.isCompleting && widget.isCompleting) {
      _shimmerCtrl.stop();
      _fillCtrl.forward().then((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) _fadeCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _fillCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isForward ? _T.green : _T.amber;
    final IconData arrowIcon =
        widget.isForward
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;
    final String label = widget.isForward ? 'Moving forward' : 'Moving back';

    return FadeTransition(
      opacity: Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut)),
      child: Stack(
        children: [
          // ── Direction pill (top-right) ─────────────────────────────────
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: accent.withOpacity(0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Spinner or checkmark
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child:
                        widget.isCompleting
                            ? Icon(
                              Icons.check_rounded,
                              key: const ValueKey('check'),
                              size: 9,
                              color: accent,
                            )
                            : SizedBox(
                              key: const ValueKey('spinner'),
                              width: 9,
                              height: 9,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.2,
                                color: accent,
                              ),
                            ),
                  ),
                  const SizedBox(width: 4),
                  Icon(arrowIcon, size: 9, color: accent),
                  const SizedBox(width: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: accent,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Progress bar (bottom edge of card) ────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(_T.rLg),
                bottomRight: Radius.circular(_T.rLg),
              ),
              child: SizedBox(
                height: 2.5,
                child:
                    widget.isCompleting
                        // Fill animation: 0 → 1
                        ? AnimatedBuilder(
                          animation: _fillCtrl,
                          builder:
                              (_, __) => LinearProgressIndicator(
                                value: _fillCtrl.value,
                                backgroundColor: accent.withOpacity(0.12),
                                color: accent,
                                minHeight: 2.5,
                              ),
                        )
                        // Indeterminate shimmer
                        : LinearProgressIndicator(
                          backgroundColor: accent.withOpacity(0.12),
                          color: accent,
                          minHeight: 2.5,
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
// LANE EMPTY STATE  (unchanged)
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
// ADD CARD BUTTON  (unchanged)
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
            border: Border.all(color: _hovered ? _T.slate300 : _T.slate200),
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
