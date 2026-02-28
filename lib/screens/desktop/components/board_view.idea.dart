// ─────────────────────────────────────────────────────────────────────────────
// board_view.dart — collapsible Kanban lanes + progress stage indicator
//
// CHANGES FROM PREVIOUS VERSION
// ───────────────────────────────
//  • Compact body: stage label removed entirely.
//  • Compact body: left colour bar removed. A thin colour stroke now appears
//    only at the very top of each compact lane (8 px tall, full width), giving
//    a minimal identity hint without hurting the eyes.
//  • Density bar: re-designed.
//      – Fills top-to-bottom (taller = more tasks).
//      – Takes up the full inner width of the compact lane (no card chrome).
//      – No card wrapper — the lane itself IS the container.
//      – Renders as a frosted, gradient pill that reads like a liquid level.
//  • Progress stage indicator: a slim fixed header row above the board that
//    shows 6 milestone labels (Designing → Completed). Each label floats
//    above its corresponding lane group and animates its x-position when
//    lanes expand / collapse / pin. A thin connector line links milestones.
//
// ANIMATION RULES (unchanged)
// ────────────────────────────
//  • Lane width:      220 ms easeOutCubic
//  • Compact fade:    140 ms easeIn
//  • Expanded fade:   170 ms easeOut
//  • Pin icon swap:   AnimatedSwitcher 160 ms
//  • Progress labels: 220 ms easeOutCubic (matches lane width)
//
// LOGIC PRESERVATION
// ───────────────────
//  All original data paths untouched:
//    isAddingTask, onCreated, onDismiss, addTaskFocusNode,
//    selectedProjectId, onTaskSelected, kStages.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/desktop/components/task_card.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue       = Color(0xFF2563EB);
  static const blueHover  = Color(0xFF1D4ED8);
  static const blue100    = Color(0xFFDBEAFE);
  static const blue50     = Color(0xFFEFF6FF);
  static const teal       = Color(0xFF38BDF8);
  static const green      = Color(0xFF10B981);
  static const green50    = Color(0xFFECFDF5);
  static const amber      = Color(0xFFF59E0B);
  static const amber50    = Color(0xFFFEF3C7);
  static const red        = Color(0xFFEF4444);
  static const red50      = Color(0xFFFEE2E2);
  static const purple     = Color(0xFF8B5CF6);
  static const purple50   = Color(0xFFF3E8FF);
  static const slate50    = Color(0xFFF8FAFC);
  static const slate100   = Color(0xFFF1F5F9);
  static const slate200   = Color(0xFFE2E8F0);
  static const slate300   = Color(0xFFCBD5E1);
  static const slate400   = Color(0xFF94A3B8);
  static const slate500   = Color(0xFF64748B);
  static const ink        = Color(0xFF0F172A);
  static const ink2       = Color(0xFF1E293B);
  static const ink3       = Color(0xFF334155);
  static const white      = Colors.white;
  static const sidebarW   = 220.0;
  static const topbarH    = 52.0;
  static const detailW    = 400.0;
  static const r          = 8.0;
  static const rLg        = 12.0;
  static const rXl        = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const double _kCompactW        = 52.0;
const double _kExpandedW       = 260.0;
const double _kLaneGap         = 10.0;
const int    _kDensityMaxTasks = 14;

// ─────────────────────────────────────────────────────────────────────────────
// MILESTONE DEFINITION
//
// Maps a milestone label → the TaskStatus of the lane it should float above.
// We use the *first* lane of a logical phase group as the anchor.
// ─────────────────────────────────────────────────────────────────────────────
class _Milestone {
  final String     label;
  final TaskStatus anchorStatus; // the lane whose left edge this floats above
  const _Milestone(this.label, this.anchorStatus);
}

const List<_Milestone> _kMilestones = [
  _Milestone('Designing',   TaskStatus.designing),
  _Milestone('Printing',    TaskStatus.printing),
  _Milestone('Finishing',   TaskStatus.finishing),
  _Milestone('Delivery',    TaskStatus.delivery),
  _Milestone('Installing',  TaskStatus.installing),
  _Milestone('Completed',   TaskStatus.completed),
];

@Deprecated("Not In USE")
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
  final Set<int> _pinned       = {};
  int?           _hoveredIndex;
  int?           _expandedIndex; // what the layout actually reflows to

  // ── Collapse debounce ──────────────────────────────────────────────────────
  // When the cursor leaves a lane we wait 320 ms before collapsing everything.
  // If the user enters another lane in that window the timer cancels and the
  // board stays open — preventing jarring snaps when crossing the narrow gap
  // between adjacent lanes or when the mouse briefly overshoots an edge.
  static const _kCollapseDelay = Duration(milliseconds: 320);
  Timer? _collapseTimer;

  void _onLaneEnter(int i) {
    _collapseTimer?.cancel();
    _collapseTimer = null;
    setState(() {
      _hoveredIndex  = i;
      _expandedIndex = i;
    });
  }

  void _onLaneExit(int i) {
    if (_pinned.contains(i)) return; // pinned lanes never start the timer
    _collapseTimer?.cancel();
    _collapseTimer = Timer(_kCollapseDelay, () {
      if (mounted) setState(() {
        _hoveredIndex  = null;
        if (_pinned.isEmpty) _expandedIndex = null;
      });
    });
  }

  bool _isExpanded(int i) => _expandedIndex == i || _pinned.contains(i);

  void _togglePin(int i) {
    setState(() {
      if (_pinned.contains(i)) {
        _pinned.remove(i);
      } else {
        _pinned.add(i);
        _collapseTimer?.cancel();
        _collapseTimer = null;
        _expandedIndex = i;
      }
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  double _milestoneX(TaskStatus anchorStatus) {
    double x = 16.0;
    for (int i = 0; i < kStages.length; i++) {
      if (kStages[i].stage == anchorStatus) break;
      x += (_isExpanded(i) ? _kExpandedW : _kCompactW) + _kLaneGap;
    }
    return x;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressIndicator(
          milestones: _kMilestones,
          milestoneX: _milestoneX,
          stages:     kStages,
          isExpanded: _isExpanded,
        ),
        Expanded(
          child: Container(
            color: _T.slate50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: List.generate(kStages.length, (i) {
                final si         = kStages[i];
                final stageTasks = widget.tasks
                    .where((t) => t.status == si.stage)
                    .toList();
                final isFirst = i == 0;

                return Padding(
                  padding: const EdgeInsets.only(right: _kLaneGap),
                  child: _KanbanLane(
                    key:               ValueKey(si.stage),
                    stageInfo:         si,
                    tasks:             stageTasks,
                    projects:          widget.projects,
                    selectedTaskId:    widget.selectedTaskId,
                    onTaskSelected:    widget.onTaskSelected,
                    showAddTaskBtn:    si.label == 'Initialized',
                    addTaskFocusNode:  isFirst ? widget.addTaskFocusNode : null,
                    isAddingTask:      isFirst ? widget.isAddingTask : false,
                    selectedProjectId: widget.selectedProjectId,
                    isPinned:          _pinned.contains(i),
                    onPinToggle:       () => _togglePin(i),
                    onLaneEnter:       () => _onLaneEnter(i),
                    onLaneExit:        () => _onLaneExit(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS INDICATOR
//
// A 48 px strip above the board. Design:
//
//   ┌──────────────────────────────────────────────────────────────────┐
//   │  ● Designing  ────────  ● Printing  ──  ● Finishing  ── … ● Completed │
//   └──────────────────────────────────────────────────────────────────┘
//
// Each milestone is an `AnimatedPositioned` pill:
//   • Resting:  label text + small dot, muted slate tones.
//   • The pill for the *currently expanded* lane's group animates to a
//     slightly more prominent state (coloured dot, slightly brighter label).
//   • The connector between milestones is rendered as individual animated
//     segments — each segment's width tracks the distance between its two
//     bounding milestones, so gaps grow and shrink fluidly.
//
// Every position change uses the same 220 ms easeOutCubic as lane width
// so labels glide in perfect sync with the lanes below them.
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressIndicator extends StatelessWidget {
  final List<_Milestone>             milestones;
  final double Function(TaskStatus)  milestoneX;
  final List<DesignStageInfo>        stages;
  final bool Function(int)           isExpanded;

  const _ProgressIndicator({
    required this.milestones,
    required this.milestoneX,
    required this.stages,
    required this.isExpanded,
  });

  Color _colorFor(TaskStatus s) =>
      stages.cast<DesignStageInfo?>()
          .firstWhere((si) => si!.stage == s, orElse: () => null)
          ?.color ??
      _T.slate300;

  @override
  Widget build(BuildContext context) {
    // Pre-compute x positions so segments can measure distances.
    final List<double> xs = milestones
        .map((m) => milestoneX(m.anchorStatus))
        .toList();

    // Pill width — wide enough to contain label + dot with some padding.
    // We measure roughly: longest label ≈ "Designing" = ~70px at 10.5px font.
    const double _pillW = 84.0;
    // Dot size
    const double _dotD  = 6.0;
    // Vertical layout inside the 48px strip:
    //   4 px gap top → 10 px label → 4 px gap → 6 px dot → 24 px track line
    const double _labelTop  = 5.0;
    const double _dotTop    = 20.0;
    const double _lineTop   = 22.0; // centre of dot vertically

    return Container(
      height:  48,
      color:   _T.slate50,
      padding: EdgeInsets.zero,
      child: Stack(
        clipBehavior: Clip.none,
        children: [

          // ── Connector segments ─────────────────────────────────────────────
          // One segment per gap between consecutive milestones.
          // Each is an AnimatedPositioned whose left/width tracks the computed
          // x values, so it stretches and compresses in sync with lane widths.
          for (int i = 0; i < milestones.length - 1; i++) ...[
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve:    Curves.easeOutCubic,
              top:      _lineTop,
              // Start after the dot of milestone i
              left:  xs[i]     + _dotD + 4,
              // End before the dot of milestone i+1
              right: (MediaQuery.of(context).size.width) - xs[i + 1] + 4,
              child: Container(
                height: 1,
                color:  _T.slate200,
              ),
            ),
          ],

          // ── Milestone pills ────────────────────────────────────────────────
          for (int i = 0; i < milestones.length; i++) ...[
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve:    Curves.easeOutCubic,
              left:     xs[i],
              top:      0,
              width:    _pillW,
              child: _MilestonePill(
                label:    milestones[i].label,
                color:    _colorFor(milestones[i].anchorStatus),
                dotTop:   _dotTop,
                labelTop: _labelTop,
                dotD:     _dotD,
              ),
            ),
          ],

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MILESTONE PILL
//
// Label sits above a dot. Both use the stage colour at a soft opacity so the
// strip is readable but never competes with the lane content below it.
// ─────────────────────────────────────────────────────────────────────────────
class _MilestonePill extends StatelessWidget {
  final String label;
  final Color  color;
  final double dotTop;
  final double labelTop;
  final double dotD;

  const _MilestonePill({
    required this.label,
    required this.color,
    required this.dotTop,
    required this.labelTop,
    required this.dotD,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Label
          Positioned(
            top:  labelTop,
            left: 0,
            child: Text(
              label,
              style: TextStyle(
                fontSize:      10,
                fontWeight:    FontWeight.w600,
                color:         color.withOpacity(0.65),
                letterSpacing: 0.25,
              ),
            ),
          ),
          // Dot
          Positioned(
            top:  dotTop,
            left: 0,
            child: Container(
              width:  dotD,
              height: dotD,
              decoration: BoxDecoration(
                color:  color.withOpacity(0.55),
                shape:  BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:      color.withOpacity(0.25),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KANBAN LANE
// ─────────────────────────────────────────────────────────────────────────────
class _KanbanLane extends ConsumerStatefulWidget {
  final DesignStageInfo   stageInfo;
  final List<Task>        tasks;
  final List<Project>     projects;
  final int?              selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  final bool              showAddTaskBtn;
  final FocusNode?        addTaskFocusNode;
  final bool              isAddingTask;
  final String?           selectedProjectId;
  final bool              isPinned;
  final VoidCallback      onPinToggle;
  final VoidCallback      onLaneEnter;
  final VoidCallback      onLaneExit;

  const _KanbanLane({
    super.key,
    required this.stageInfo,
    required this.tasks,
    required this.projects,
    required this.selectedTaskId,
    required this.onTaskSelected,
    required this.showAddTaskBtn,
    required this.addTaskFocusNode,
    required this.isAddingTask,
    required this.selectedProjectId,
    required this.isPinned,
    required this.onPinToggle,
    required this.onLaneEnter,
    required this.onLaneExit,
  });

  @override
  ConsumerState<_KanbanLane> createState() => _KanbanLaneState();
}

class _KanbanLaneState extends ConsumerState<_KanbanLane> {
  bool _hovered     = false;
  late bool _isAddingTask = widget.isAddingTask;

  bool get _expanded => _hovered || widget.isPinned;

  void _onAddTask() {
    widget.addTaskFocusNode?.requestFocus();
    setState(() => _isAddingTask = true);
  }

  void _onDismiss()          => setState(() => _isAddingTask = false);
  void _onCreated(Task task) => setState(() => _isAddingTask = false);

  @override
  void didUpdateWidget(_KanbanLane old) {
    super.didUpdateWidget(old);
    if (old.isAddingTask != widget.isAddingTask) {
      _isAddingTask = widget.isAddingTask;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.stageInfo.stage == TaskStatus.clientApproved;
    final density    = (widget.tasks.length / _kDensityMaxTasks).clamp(0.0, 1.0);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onLaneEnter();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onLaneExit();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve:    Curves.easeOutCubic,
        width:    _expanded ? _kExpandedW : _kCompactW,
        decoration: BoxDecoration(
          color: _T.white,
          border: Border.all(
            color: widget.isPinned
                ? widget.stageInfo.color.withOpacity(0.35)
                : _T.slate200,
            width: widget.isPinned ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(_T.rLg),
          boxShadow: widget.isPinned
              ? [BoxShadow(
                  color:      widget.stageInfo.color.withOpacity(0.07),
                  blurRadius: 12,
                  offset:     const Offset(0, 3),
                )]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_T.rLg - 1),
          child: Stack(
            children: [

              // ── LAYER 1: Compact ─────────────────────────────────────────
              AnimatedOpacity(
                opacity:  _expanded ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve:    Curves.easeIn,
                child: IgnorePointer(
                  ignoring: _expanded,
                  child: _CompactBody(
                    stageInfo: widget.stageInfo,
                    taskCount: widget.tasks.length,
                    density:   density,
                  ),
                ),
              ),

              // ── LAYER 2: Expanded ────────────────────────────────────────
              AnimatedOpacity(
                opacity:  _expanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 170),
                curve:    Curves.easeOut,
                child: IgnorePointer(
                  ignoring: !_expanded,
                  child: SizedBox(
                    width: _kExpandedW,
                    child: Column(
                      children: [
                        _LaneHeader(
                          stageInfo:  widget.stageInfo,
                          taskCount:  widget.tasks.length,
                          isApproved: isApproved,
                          isPinned:   widget.isPinned,
                          isHovered:  _hovered,
                          onPin:      widget.onPinToggle,
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(10),
                            children: [
                              if (widget.tasks.isEmpty)
                                const _LaneEmpty()
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
                          _isAddingTask
                              ? Focus(
                                  focusNode: widget.addTaskFocusNode,
                                  autofocus: true,
                                  child: TaskCard.add(
                                    onCreated:         _onCreated,
                                    onDismiss:         _onDismiss,
                                    projects:          ref.watch(projectNotifierProvider),
                                    selectedProjectId: widget.selectedProjectId,
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  child: _AddCardButton(onTap: _onAddTask),
                                ),
                      ],
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
// COMPACT BODY
//
// Corporate-grade collapsed lane. Anatomy (52 px wide):
//
//   ┌────────────────────┐
//   │  ═══════════════   │  ← 2 px stage-colour rule, inset 10 px each side,
//   │                    │    with a soft colour-matched glow underneath it.
//   │                    │    This is the *only* colour signal.
//   │     14             │  ← Task count: large, tabular, slate ink.
//   │                    │    Zero state: "–" in slate300.
//   │  ┃                 │  ← Density bar: a single 3 px wide vertical bar,
//   │  ┃                 │    left-aligned, height ∝ task count.
//   │  ┃                 │    Colour: stage colour at low opacity.
//   │                    │    Track: slate100, same shape.
//   └────────────────────┘
//
// No blobs, no gradients, no floating fills.
// Whitespace and precision typography do the heavy lifting.
// ─────────────────────────────────────────────────────────────────────────────
class _CompactBody extends StatelessWidget {
  final DesignStageInfo stageInfo;
  final int             taskCount;
  final double          density; // 0.0–1.0

  const _CompactBody({
    required this.stageInfo,
    required this.taskCount,
    required this.density,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = taskCount == 0;

    return SizedBox(
      width:  _kCompactW,
      height: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Stage-colour rule ─────────────────────────────────────────────
            // 2 px height, full available width, with a tight shadow that
            // reads as a refined accent rather than a paint stroke.
            Container(
              height: 2,
              decoration: BoxDecoration(
                color:        stageInfo.color.withOpacity(isEmpty ? 0.25 : 0.7),
                borderRadius: BorderRadius.circular(1),
                boxShadow: isEmpty
                    ? null
                    : [
                        BoxShadow(
                          color:      stageInfo.color.withOpacity(0.18),
                          blurRadius: 6,
                          offset:     const Offset(0, 2),
                        ),
                      ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Task count ────────────────────────────────────────────────────
            // Uses tabular figures. Large enough to read without hunting.
            // Zero state uses an em-dash — cleaner than "0".
            Center(
              child: Text(
                isEmpty ? '–' : '$taskCount',
                style: TextStyle(
                  fontSize:      18,
                  fontWeight:    FontWeight.w700,
                  color: isEmpty ? _T.slate300 : _T.ink2,
                  // Tabular nums so the count doesn't shift width between 1–99
                  fontFeatures:  const [FontFeature.tabularFigures()],
                  height:        1,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Density bar ───────────────────────────────────────────────────
            // A narrow vertical track + fill, left-aligned.
            // Grows top → bottom. Communicates load without decorative noise.
            Expanded(
              child: Center(
                child: _CompactDensityBar(
                  density: density,
                  color:   stageInfo.color,
                  isEmpty: isEmpty,
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
// COMPACT DENSITY BAR
//
// A 3 px wide vertical bar inside a slate100 track.
// Fills from the top downward, proportional to task density.
// No gradients — a single flat colour at controlled opacity is more precise
// and more legible at this narrow width than any gradient.
// ─────────────────────────────────────────────────────────────────────────────
class _CompactDensityBar extends StatelessWidget {
  final double density;
  final Color  color;
  final bool   isEmpty;

  const _CompactDensityBar({
    required this.density,
    required this.color,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    const double barW   = 3.0;
    const double trackR = 1.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalH = constraints.maxHeight;
        final fillH  = isEmpty
            ? 0.0
            : (totalH * density).clamp(6.0, totalH);

        return SizedBox(
          width:  barW,
          height: totalH,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Track
              Container(
                width:  barW,
                height: totalH,
                decoration: BoxDecoration(
                  color:        _T.slate100,
                  borderRadius: BorderRadius.circular(trackR),
                ),
              ),
              // Fill
              AnimatedContainer(
                duration:  const Duration(milliseconds: 420),
                curve:     Curves.easeOutCubic,
                width:     barW,
                height:    fillH,
                decoration: BoxDecoration(
                  color:        color.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(trackR),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LANE HEADER (expanded state) — unchanged except import refs
// ─────────────────────────────────────────────────────────────────────────────
class _LaneHeader extends StatelessWidget {
  final DesignStageInfo stageInfo;
  final int             taskCount;
  final bool            isApproved;
  final bool            isPinned;
  final bool            isHovered;
  final VoidCallback    onPin;

  const _LaneHeader({
    required this.stageInfo,
    required this.taskCount,
    required this.isApproved,
    required this.isPinned,
    required this.isHovered,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 10, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _T.slate100)),
      ),
      child: Row(
        children: [
          Container(
            width: 3, height: 16,
            decoration: BoxDecoration(
              color:        stageInfo.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stageInfo.label,
              style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w700,
                color:      _T.ink,
              ),
            ),
          ),
          if (isApproved) ...[
            Icon(Icons.lock_outline, size: 12, color: stageInfo.color),
            const SizedBox(width: 4),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color:        isApproved ? stageInfo.bg : _T.slate100,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$taskCount',
              style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w700,
                color: isApproved ? stageInfo.color : _T.slate500,
              ),
            ),
          ),
          AnimatedOpacity(
            opacity:  (isHovered || isPinned) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 140),
            child: IgnorePointer(
              ignoring: !(isHovered || isPinned),
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _PinButton(
                  isPinned: isPinned,
                  color:    stageInfo.color,
                  onTap:    onPin,
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
// PIN BUTTON — unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _PinButton extends StatefulWidget {
  final bool         isPinned;
  final Color        color;
  final VoidCallback onTap;

  const _PinButton({
    required this.isPinned,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PinButton> createState() => _PinButtonState();
}

class _PinButtonState extends State<_PinButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color fg = widget.isPinned
        ? widget.color
        : (_hovering ? _T.ink3 : _T.slate400);

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          padding:  const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: widget.isPinned
                ? widget.color.withOpacity(0.09)
                : (_hovering ? _T.slate100 : Colors.transparent),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  widget.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  key:   ValueKey(widget.isPinned),
                  size:  12,
                  color: fg,
                ),
              ),
              const SizedBox(width: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 110),
                style: TextStyle(
                  fontSize:   10,
                  fontWeight: FontWeight.w600,
                  color:      fg,
                ),
                child: Text(widget.isPinned ? 'Pinned' : 'Pin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LANE EMPTY STATE — unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _LaneEmpty extends StatelessWidget {
  const _LaneEmpty();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 28),
    child: Column(children: [
      Icon(Icons.assignment_outlined, size: 28, color: _T.slate300),
      SizedBox(height: 8),
      Text(
        'No tasks here',
        style: TextStyle(fontSize: 12, color: _T.slate300),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD CARD BUTTON — unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _AddCardButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCardButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
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
              style: TextStyle(
                fontSize:   12.5,
                fontWeight: FontWeight.w500,
                color:      _T.slate400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}