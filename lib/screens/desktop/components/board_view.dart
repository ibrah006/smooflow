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
          onToggleGroup:   _toggleGroup,
          onToggleStage:   _toggleStage,
          onToggleExpand:  _toggleExpand,
        ),

        // ── Lane scroll ──────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: _T.slate50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              children: kStages.where((si) => !_hidden.contains(si.stage)).map((si) {
                final stageTasks = widget.tasks
                    .where((t) => t.status == si.stage)
                    .toList();

                // Original: hide pending lane when empty
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
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER BAR
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final List<_StageGroup>        groups;
  final bool Function(int)       groupFullyOn;
  final bool Function(int)       groupPartial;
  final Set<int>                 expandedGroups;
  final Set<TaskStatus>          hidden;
  final ValueChanged<int>        onToggleGroup;
  final ValueChanged<TaskStatus> onToggleStage;
  final ValueChanged<int>        onToggleExpand;

  const _FilterBar({
    required this.groups,
    required this.groupFullyOn,
    required this.groupPartial,
    required this.expandedGroups,
    required this.hidden,
    required this.onToggleGroup,
    required this.onToggleStage,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:  _T.white,
        border: Border(bottom: BorderSide(color: _T.slate100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    
          // ── Group pill row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text(
                  'Showing',
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w500,
                    color:      _T.slate400,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(groups.length, (gi) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _GroupPill(
                          group:      groups[gi],
                          isOn:       groupFullyOn(gi),
                          isPartial:  groupPartial(gi),
                          isExpanded: expandedGroups.contains(gi),
                          onTap:      () => onToggleGroup(gi),
                          onExpand:   () => onToggleExpand(gi),
                        ),
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
    
          // ── Detail chip rows ───────────────────────────────────────────────
          for (int gi = 0; gi < groups.length; gi++)
            if (expandedGroups.contains(gi))
              _DetailChipRow(
                group:      groups[gi],
                hidden:     hidden,
                onToggle:   onToggleStage,
                onCollapse: () => onToggleExpand(gi),
              ),
    
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GROUP PILL
// ─────────────────────────────────────────────────────────────────────────────
class _GroupPill extends StatelessWidget {
  final _StageGroup  group;
  final bool         isOn;
  final bool         isPartial;
  final bool         isExpanded;
  final VoidCallback onTap;
  final VoidCallback onExpand;

  const _GroupPill({
    required this.group,
    required this.isOn,
    required this.isPartial,
    required this.isExpanded,
    required this.onTap,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final bool   active = isOn || isPartial;
    final Color  fg     = active ? group.color                  : _T.slate400;
    final Color  bg     = active ? group.color.withOpacity(0.08) : _T.slate100;
    final Color  bd     = active ? group.color.withOpacity(0.22) : _T.slate200;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration:    const Duration(milliseconds: 160),
        decoration:  BoxDecoration(
          color:        bg,
          border:       Border.all(color: bd),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
      
            // Toggle tap target
            GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      child: Icon(
                        isPartial
                            ? Icons.remove_rounded
                            : isOn
                                ? Icons.check_rounded
                                : Icons.remove_rounded,
                        key:   ValueKey('$isOn-$isPartial'),
                        size:  12,
                        color: active ? group.color : _T.slate400,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      group.label,
                      style: TextStyle(
                        fontSize:   11.5,
                        fontWeight: FontWeight.w600,
                        color:      fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      
            // Divider
            Container(width: 1, height: 20, color: bd),
      
            // Chevron
            GestureDetector(
              onTap: onExpand,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                child: AnimatedRotation(
                  turns:    isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  child:    Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: fg),
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
// DETAIL CHIP ROW
// ─────────────────────────────────────────────────────────────────────────────
class _DetailChipRow extends StatelessWidget {
  final _StageGroup          group;
  final Set<TaskStatus>      hidden;
  final ValueChanged<TaskStatus> onToggle;
  final VoidCallback             onCollapse;

  const _DetailChipRow({
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
      decoration: const BoxDecoration(
        color:  _T.slate50,
        border: Border(
          top:    BorderSide(color: _T.slate100),
          bottom: BorderSide(color: _T.slate100),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: group.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: group.statuses.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: _StageChip(
                    label:     _label(s),
                    isVisible: !hidden.contains(s),
                    color:     group.color,
                    onTap:     () => onToggle(s),
                  ),
                )).toList(),
              ),
            ),
          ),
          GestureDetector(
            onTap: onCollapse,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: _T.slate400),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _StageChip extends StatelessWidget {
  final String       label;
  final bool         isVisible;
  final Color        color;
  final VoidCallback onTap;

  const _StageChip({
    required this.label,
    required this.isVisible,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:    const Duration(milliseconds: 130),
        padding:     const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:  BoxDecoration(
          color:        isVisible ? color.withOpacity(0.07) : Colors.transparent,
          border:       Border.all(
            color: isVisible ? color.withOpacity(0.25) : _T.slate200,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize:   10.5,
            fontWeight: FontWeight.w500,
            color:      isVisible ? color : _T.slate400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KANBAN LANE  — original implementation, zero changes to logic or style
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

          // Header
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

          // Cards
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

          // Add button
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
// LANE EMPTY STATE — original, unchanged
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
// ADD CARD BUTTON — original, unchanged
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