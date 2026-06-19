import 'package:flutter/material.dart';
import 'package:smooflow/data/pipeline_milestone.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blue50 = Color(0xFFEFF6FF);
  static const ink3 = Color(0xFF334155);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const r = 8.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// _StagePipeline
// ─────────────────────────────────────────────────────────────────────────────
class StagePipeline extends StatelessWidget {
  final TaskStatus currentStatus;
  final ValueChanged<TaskStatus>? onStageTap;

  const StagePipeline({required this.currentStatus, this.onStageTap});

  DesignStageInfo? _infoFor(TaskStatus s) => kStages
      .cast<DesignStageInfo?>()
      .firstWhere((si) => si!.stage == s, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    final curMilestoneIdx = _milestoneOf(currentStatus);
    final intermediate = _isIntermediate(currentStatus);

    final subSi = intermediate ? _infoFor(currentStatus) : null;
    final Color subFg = subSi?.color ?? _T.blue;
    final Color subBg = subSi?.bg ?? _T.blue50;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _T.slate200),
        borderRadius: BorderRadius.circular(_T.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_T.r),
        child: Column(
          children:
              kPipelineMilestones.asMap().entries.expand((entry) {
                final idx = entry.key;
                final milestone = entry.value;
                final isDone = idx < curMilestoneIdx;
                final isCurrent = idx == curMilestoneIdx;

                // Show ALL sub-steps when this is the active milestone.
                // Past sub-steps get a check, the current one gets the "Now"
                // chip, future sub-steps are shown dimmed so the user can see
                // what's still ahead inside this stage.
                final injectSubSteps = isCurrent && intermediate;
                final List<TaskStatus> visibleSubSteps =
                    injectSubSteps ? milestone.subSteps : [];

                final int currentSubIdx =
                    injectSubSteps
                        ? milestone.subSteps.indexOf(currentStatus)
                        : -1;

                final bool isLastMilestone =
                    idx == kPipelineMilestones.length - 1;
                final bool milestoneHasBorder =
                    !injectSubSteps && !isLastMilestone;

                final si = _infoFor(milestone.status);
                final Color dotColor = si?.color ?? _T.blue;
                final Color bgColor = si?.bg ?? _T.blue50;

                final bool milestoneClickable = idx > curMilestoneIdx;

                return <Widget>[
                  _MilestoneRow(
                    milestone: milestone,
                    isDone: isDone,
                    isCurrent: isCurrent,
                    injectSubSteps: injectSubSteps,
                    isLastMilestone: isLastMilestone,
                    milestoneHasBorder: milestoneHasBorder,
                    dotColor: dotColor,
                    bgColor: bgColor,
                    clickable: milestoneClickable,
                    onTap:
                        milestoneClickable
                            ? () => onStageTap?.call(milestone.status)
                            : null,
                  ),
                  // All sub-steps: past, current, and upcoming within this stage.
                  ...visibleSubSteps.asMap().entries.map((subEntry) {
                    final subIdx = subEntry.key;
                    final s = subEntry.value;

                    final isCur = subIdx == currentSubIdx;
                    final isPast = subIdx < currentSubIdx;
                    final isUpcoming = subIdx > currentSubIdx;

                    final bool isLastSub = subIdx == visibleSubSteps.length - 1;
                    final bool isVeryLast = isLastSub && isLastMilestone;

                    final rowSi = _infoFor(s);
                    final Color rowFg =
                        isCur
                            ? subFg
                            : isPast
                            ? (rowSi?.color ?? _T.blue)
                            : _T.slate400;

                    return _SubStepRow(
                      status: s,
                      label: _subLabel(s),
                      isCurrent: isCur,
                      isPast: isPast,
                      isUpcoming: isUpcoming,
                      isVeryLast: isVeryLast,
                      isLastSub: isLastSub,
                      subIdx: subIdx,
                      subFg: subFg,
                      subBg: subBg,
                      rowFg: rowFg,
                      clickable: false,
                      onTap: null,
                    );
                  }),
                ];
              }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MILESTONE ROW  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _MilestoneRow extends StatefulWidget {
  final PipelineMilestone milestone;
  final bool isDone;
  final bool isCurrent;
  final bool injectSubSteps;
  final bool isLastMilestone;
  final bool milestoneHasBorder;
  final Color dotColor;
  final Color bgColor;
  final bool clickable;
  final VoidCallback? onTap;

  const _MilestoneRow({
    required this.milestone,
    required this.isDone,
    required this.isCurrent,
    required this.injectSubSteps,
    required this.isLastMilestone,
    required this.milestoneHasBorder,
    required this.dotColor,
    required this.bgColor,
    required this.clickable,
    required this.onTap,
  });

  @override
  State<_MilestoneRow> createState() => _MilestoneRowState();
}

class _MilestoneRowState extends State<_MilestoneRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final showHover = widget.clickable && _hovered;

    Color rowBg;
    if (widget.isCurrent && !widget.injectSubSteps) {
      rowBg = showHover ? widget.bgColor.withOpacity(0.85) : widget.bgColor;
    } else if (showHover) {
      rowBg = _T.slate50;
    } else {
      rowBg = Theme.of(context).canvasColor;
    }

    return MouseRegion(
      cursor: widget.clickable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.clickable ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: rowBg,
            border:
                widget.milestoneHasBorder
                    ? const Border(bottom: BorderSide(color: _T.slate100))
                    : null,
          ),
          child: Transform.scale(
            scale: showHover ? 1.012 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color:
                          widget.isDone
                              ? _T.blue
                              : widget.isCurrent && !widget.injectSubSteps
                              ? widget.dotColor
                              : showHover
                              ? _T.slate200
                              : _T.slate100,
                      shape: BoxShape.circle,
                      border:
                          widget.injectSubSteps && widget.isCurrent
                              ? Border.all(
                                color: widget.dotColor.withOpacity(0.4),
                                width: 1.5,
                              )
                              : null,
                    ),
                    child: Center(
                      child:
                          widget.isDone
                              ? const Icon(
                                Icons.check,
                                size: 11,
                                color: Colors.white,
                              )
                              : widget.isCurrent && !widget.injectSubSteps
                              ? Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                              : Container(
                                width: widget.injectSubSteps ? 6 : 5,
                                height: widget.injectSubSteps ? 6 : 5,
                                decoration: BoxDecoration(
                                  color:
                                      widget.injectSubSteps
                                          ? widget.dotColor.withOpacity(0.45)
                                          : showHover
                                          ? _T.slate400
                                          : _T.slate300,
                                  shape: BoxShape.circle,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.milestone.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            widget.isCurrent
                                ? FontWeight.w600
                                : FontWeight.w500,
                        color:
                            widget.isCurrent && !widget.injectSubSteps
                                ? widget.dotColor
                                : widget.isDone || widget.isCurrent
                                ? _T.ink3
                                : showHover
                                ? _T.ink3
                                : _T.slate400,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder:
                        (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0.15, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                    child:
                        showHover
                            ? _MoveToChip(
                              key: const ValueKey('move'),
                              label: widget.milestone.label,
                              color: widget.dotColor,
                              bg: widget.bgColor,
                            )
                            : widget.isCurrent && !widget.injectSubSteps
                            ? _CurrentChip(
                              key: const ValueKey('current'),
                              color: widget.dotColor,
                              bg: widget.bgColor,
                            )
                            : widget.isDone
                            ? const _DoneLabel(key: ValueKey('done'))
                            : const SizedBox.shrink(key: ValueKey('none')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-STEP ROW  — now supports three states: past · current · upcoming
// ─────────────────────────────────────────────────────────────────────────────
class _SubStepRow extends StatefulWidget {
  final TaskStatus status;
  final String label;
  final bool isCurrent;
  final bool isPast;
  final bool isUpcoming; // ← new: steps after currentStatus in this milestone
  final bool isVeryLast;
  final bool isLastSub;
  final int subIdx;
  final Color subFg;
  final Color subBg;
  final Color rowFg;
  final bool clickable;
  final VoidCallback? onTap;

  const _SubStepRow({
    required this.status,
    required this.label,
    required this.isCurrent,
    required this.isPast,
    required this.isUpcoming,
    required this.isVeryLast,
    required this.isLastSub,
    required this.subIdx,
    required this.subFg,
    required this.subBg,
    required this.rowFg,
    required this.clickable,
    required this.onTap,
  });

  @override
  State<_SubStepRow> createState() => _SubStepRowState();
}

class _SubStepRowState extends State<_SubStepRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final showHover = widget.clickable && _hovered;

    return MouseRegion(
      cursor: widget.clickable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color:
                widget.isCurrent
                    ? widget.subBg
                    : showHover
                    ? _T.slate50
                    : Colors.transparent,
            border: Border(
              top: BorderSide(
                color: widget.subIdx == 0 ? _T.slate200 : _T.slate100,
              ),
              bottom:
                  widget.isVeryLast
                      ? BorderSide.none
                      : widget.isLastSub
                      ? const BorderSide(color: _T.slate100)
                      : BorderSide.none,
            ),
          ),
          child: Transform.scale(
            scale: showHover ? 1.012 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Status dot
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color:
                          widget.isPast
                              ? _T.blue
                              : widget.isCurrent
                              ? widget.subFg
                              : _T.slate100, // upcoming: empty/grey circle
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child:
                          widget.isPast
                              ? const Icon(
                                Icons.check,
                                size: 11,
                                color: Colors.white,
                              )
                              : widget.isCurrent
                              ? Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                              : Container(
                                // upcoming: tiny muted dot
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: _T.slate300,
                                  shape: BoxShape.circle,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Label
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            widget.isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                        // Upcoming steps are visually muted
                        color:
                            widget.isCurrent
                                ? widget.subFg
                                : widget.isPast
                                ? _T.ink3
                                : _T.slate400,
                      ),
                    ),
                  ),

                  // Right chip / label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder:
                        (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                    child:
                        widget.isPast
                            ? const _DoneLabel(key: ValueKey('done'))
                            : widget.isCurrent
                            ? _NowChip(
                              key: const ValueKey('now'),
                              color: widget.subFg,
                              bg: widget.subBg,
                            )
                            : const SizedBox.shrink(
                              key: ValueKey('none'),
                            ), // upcoming: no chip
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHIP / LABEL ATOMS  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _MoveToChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _MoveToChip({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_forward_rounded, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            'Move to $label',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentChip extends StatelessWidget {
  final Color color;
  final Color bg;

  const _CurrentChip({super.key, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'Current',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _NowChip extends StatelessWidget {
  final Color color;
  final Color bg;

  const _NowChip({super.key, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'Now',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DoneLabel extends StatelessWidget {
  const _DoneLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      '✓ Done',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _T.slate400,
      ),
    );
  }
}

int _milestoneOf(TaskStatus s) {
  for (int i = 0; i < kPipelineMilestones.length; i++) {
    final m = kPipelineMilestones[i];
    if (m.status == s) return i;
    if (m.subSteps.contains(s)) return i;
  }
  return 0;
}

bool _isIntermediate(TaskStatus s) {
  for (final m in kPipelineMilestones) {
    if (m.subSteps.contains(s) && m.status != s) return true;
  }
  return false;
}

String _subLabel(TaskStatus s) => switch (s) {
  TaskStatus.pending => 'Initialized',
  TaskStatus.designing => 'Designing',
  TaskStatus.waitingApproval => 'Waiting Approval',
  TaskStatus.clientApproved => 'Client Approved',
  TaskStatus.revision => 'Needs Revision',
  TaskStatus.waitingPrinting => 'Handed to Print',
  TaskStatus.printing => 'Printing',
  TaskStatus.printingCompleted => 'Print Complete',
  TaskStatus.finishing => 'Finishing',
  TaskStatus.productionCompleted => 'Production Complete',
  TaskStatus.waitingDelivery => 'Waiting for Delivery',
  TaskStatus.delivery => 'Out for Delivery',
  TaskStatus.delivered => 'Delivered',
  TaskStatus.waitingInstallation => 'Waiting for Install',
  TaskStatus.installing => 'Installing',
  TaskStatus.completed => 'Completed',
  TaskStatus.blocked => 'Blocked',
  TaskStatus.paused => 'Paused',
};
