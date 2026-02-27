// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PANEL
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/desktop/advance_stage_popup.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/priority_pill.dart';
import 'package:smooflow/screens/desktop/components/stage_pill.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Brand
  static const blue       = Color(0xFF2563EB);
  static const blueHover  = Color(0xFF1D4ED8);
  static const blue100    = Color(0xFFDBEAFE);
  static const blue50     = Color(0xFFEFF6FF);
  static const teal       = Color(0xFF38BDF8);

  // Semantic
  static const green      = Color(0xFF10B981);
  static const green50    = Color(0xFFECFDF5);
  static const amber      = Color(0xFFF59E0B);
  static const amber50    = Color(0xFFFEF3C7);
  static const red        = Color(0xFFEF4444);
  static const red50      = Color(0xFFFEE2E2);
  static const purple     = Color(0xFF8B5CF6);
  static const purple50   = Color(0xFFF3E8FF);

  // Neutrals
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

  // Dimensions
  static const sidebarW  = 220.0;
  static const topbarH   = 52.0;
  static const detailW   = 400.0;

  // Radius
  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class DetailPanel extends ConsumerStatefulWidget {
  final Task task;
  final List<Project> projects;
  final VoidCallback onClose;
  final VoidCallback onAdvance;

  const DetailPanel({super.key, required this.task, required this.projects, required this.onClose, required this.onAdvance});

  @override
  ConsumerState<DetailPanel> createState() => __DetailPanelState();
}

class __DetailPanelState extends ConsumerState<DetailPanel> {

  // GlobalKey for the button
  final GlobalKey _advanceButtonKey = GlobalKey();

  // if (task.status.nextStage == TaskStatus.printing) 
  void approveDesignStage() async {
    final nextStage = widget.task.status.nextStage;
    if (nextStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to advance stage")));
      return;
    }

    await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: widget.task.id, newStatus: nextStage);
    setState(() {});

    widget.onAdvance();
  }

  void _showMoveToNextStageDialog() async {

    final nextStage = widget.task.status.nextStage;

    if (nextStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No explicit next stage from current phase")));
      return;
    }

    AdvanceStagePopup.show(
      context: context,
      buttonKey: _advanceButtonKey,
      taskId: widget.task.id,
      onConfirm: (notes) async {
        await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: widget.task.id, newStatus: nextStage);
        setState(() {
          // Update task status
          // task.status = getNextStatus(task.status);
        });
        
        if (notes != null) {
          // Save notes to activity timeline
          // task.addActivity(notes);
        }

        widget.onAdvance();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final curIdx = stageIndex(widget.task.status);
    final si     = stageInfo(widget.task.status);
    final proj  = widget.projects.cast<Project?>().firstWhere((p) => p!.id == widget.task.projectId, orElse: () => null) ?? widget.projects.first;

    Member? member;
    try {
      member = ref.watch(memberNotifierProvider).members.firstWhere((m) => widget.task.assignees.contains(m.id));
    } catch (_) {
      member = null;
    }

    final d = widget.task.dueDate;
    final now = DateTime.now();
    final isOverdue = d != null && d.isBefore(now);
    final isSoon    = d != null && !isOverdue && d.difference(now).inDays <= 3;
    final next      = widget.task.status.nextStage;

    final progressBtnEnabled =
      next != TaskStatus.printing;

    return Container(
      width: _T.detailW,
      decoration: const BoxDecoration(color: _T.white, border: Border(left: BorderSide(color: _T.slate200))),
      child: Column(
        children: [
          // Detail topbar
          Container(
            height: _T.topbarH,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _T.slate200))),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                    child: const Icon(Icons.close, size: 13, color: _T.slate400),
                  ),
                ),
                const SizedBox(width: 10),
                Text('TASK-${widget.task.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: _T.slate400)),
                const Spacer(),
              ],
            ),
          ),

          // Stage stepper
          _StageStepper(currentStatus: widget.task.status),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(widget.task.name, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: _T.ink, letterSpacing: -0.3, height: 1.35)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: proj.color, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(proj.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _T.slate500)),
                  ]),
                  const SizedBox(height: 18),

                  // Details grid
                  const _DetailSectionTitle('Details'),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _DetailMetaCell(label: 'Current Stage', child: StagePill(stageInfo: si)),
                      _DetailMetaCell(label: 'Priority', child: PriorityPill(priority: widget.task.priority)),
                      if (member != null)
                        _DetailMetaCell(label: 'Assignee', child: Row(children: [
                          AvatarWidget(initials: member.initials, color: member.color, size: 22),
                          const SizedBox(width: 6),
                          Expanded(child: Text(member.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _T.ink3))),
                        ])),
                      _DetailMetaCell(
                        label: 'Due Date',
                        child: d != null
                            ? Row(children: [
                                Text(fmtDate(d), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isOverdue ? _T.red : isSoon ? _T.amber : _T.ink3)),
                                if (isOverdue) ...[const SizedBox(width: 6), const _Badge('Overdue', _T.red, _T.red50)],
                                if (isSoon && !isOverdue) ...[const SizedBox(width: 6), const _Badge('Due soon', _T.amber, _T.amber50)],
                              ])
                            : const Text('—', style: TextStyle(color: _T.slate400)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Description
                  if (widget.task.description.trim().isNotEmpty) ...[
                    const _DetailSectionTitle('Description'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _T.slate50, border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                      child: Text(widget.task.description, style: const TextStyle(fontSize: 13, color: _T.slate500, height: 1.65)),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Stage pipeline
                  const _DetailSectionTitle('Stage Pipeline'),
                  const SizedBox(height: 8),
                  _StagePipeline(
                    currentStatus: widget.task.status,
                    stages: kStages, // your existing DesignStageInfo list
                  ),
                ],
              ),
            ),
          ),

          // Footer action
          Container(
            decoration: const BoxDecoration(color: _T.slate50, border: Border(top: BorderSide(color: _T.slate200))),
            padding: const EdgeInsets.all(14),
            child: next != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('ADVANCE STAGE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: _T.slate400)),
                      const SizedBox(height: 9),
                      GestureDetector(
                        key: _advanceButtonKey,
                        onTap: () {
                          // Determine if button should be enabled
                          final isAllowedStage = next == TaskStatus.clientApproved ||
                              next == TaskStatus.printing ||
                              next == TaskStatus.designing ||
                              next == TaskStatus.waitingApproval ||
                              (next == TaskStatus.delivery && LoginService.currentUser!.isAdmin);

                          if (!isAllowedStage) return;

                          // Call proper handler
                          if (next == TaskStatus.clientApproved) {
                            return approveDesignStage();
                          } else {
                            return _showMoveToNextStageDialog();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color:
                            (next == TaskStatus.clientApproved)
                                ? _T.green
                                : ((next == TaskStatus.printing ||
                                    next == TaskStatus.designing ||
                                    next == TaskStatus.waitingApproval ||
                                    (next == TaskStatus.delivery && LoginService.currentUser!.isAdmin))
                                    ? _T.blue
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(_T.r),
                            boxShadow: progressBtnEnabled
                                ? [
                                    BoxShadow(
                                      color: ((next == TaskStatus.clientApproved)
                                              ? _T.green
                                              : _T.blue)
                                          .withOpacity(0.28),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                progressBtnEnabled
                                    ? Icons.check
                                    : Icons.arrow_forward,
                                size: 15,
                                color: progressBtnEnabled
                                    ? Colors.white
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                next == TaskStatus.clientApproved
                                    ? 'Confirm Client Approval'
                                    : 'Move to "${stageInfo(next).label}"',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: progressBtnEnabled
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: const [
                      Icon(Icons.lock_outline, size: 14, color: _T.slate400),
                      SizedBox(width: 8),
                      Expanded(child: Text('Handed off to production — design locked', style: TextStyle(fontSize: 12.5, color: _T.slate400))),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  final String text;
  const _DetailSectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: _T.slate400));
}

class _DetailMetaCell extends StatelessWidget {
  final String label;
  final Widget child;
  const _DetailMetaCell({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _T.slate400)),
      const SizedBox(height: 4),
      child,
    ],
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color, bg;
  const _Badge(this.text, this.color, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
    child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE STEPPER — top-level milestones only
//
// Shows 6 milestone stages regardless of the task's granular status.
// Intermediate statuses (e.g. waitingPrinting, printingCompleted) are mapped
// to the correct milestone position so the dot and connector state is always
// accurate.
//
// Milestone order:
//   Designing → Printing → Finishing → Delivery → Installing → Completed
//
// Mapping rules:
//   pending, designing, waitingApproval,
//     clientApproved, revision          → milestone 0 (Designing)
//   waitingPrinting, printing,
//     printingCompleted                 → milestone 1 (Printing)
//   finishing, productionCompleted      → milestone 2 (Finishing)
//   waitingDelivery, delivery,
//     delivered                         → milestone 3 (Delivery)
//   waitingInstallation, installing     → milestone 4 (Installing)
//   completed                           → milestone 5 (Completed)
//   blocked / paused                    → same index as their last known phase
// ─────────────────────────────────────────────────────────────────────────────

// ── Milestone definition ─────────────────────────────────────────────────────

class _Milestone {
  final String     shortLabel;
  final TaskStatus status;   // the canonical status for this milestone dot
  final Color      color;
  const _Milestone(this.shortLabel, this.status, this.color);
}

const List<_Milestone> _kMilestones = [
  _Milestone('Design',   TaskStatus.designing,  Color(0xFF8B5CF6)),
  _Milestone('Print',    TaskStatus.printing,   Color(0xFF2563EB)),
  _Milestone('Finish',   TaskStatus.finishing,  Color(0xFF0EA5E9)),
  _Milestone('Delivery', TaskStatus.delivery,   Color(0xFF10B981)),
  _Milestone('Install',  TaskStatus.installing, Color(0xFF10B981)),
  _Milestone('Done',     TaskStatus.completed,  Color(0xFF10B981)),
];

// ── Status → milestone index ─────────────────────────────────────────────────
// Returns the index of the milestone the task is currently AT (not past).
// "AT" means: actively in this phase or waiting to enter the next one.

int _milestoneIndexFor(TaskStatus status) => switch (status) {
  // Design phase
  TaskStatus.pending             => 0,
  TaskStatus.designing           => 0,
  TaskStatus.waitingApproval     => 0,
  TaskStatus.clientApproved      => 0,
  TaskStatus.revision            => 0,
  // Printing phase
  TaskStatus.waitingPrinting     => 1,
  TaskStatus.printing            => 1,
  TaskStatus.printingCompleted   => 1,
  // Finishing phase
  TaskStatus.finishing           => 2,
  TaskStatus.productionCompleted => 2,
  // Delivery phase
  TaskStatus.waitingDelivery     => 3,
  TaskStatus.delivery            => 3,
  TaskStatus.delivered           => 3,
  // Installation phase
  TaskStatus.waitingInstallation => 4,
  TaskStatus.installing          => 4,
  // Complete
  TaskStatus.completed           => 5,
  // Cross-cutting: blocked/paused don't advance the milestone
  // Default to design so we never throw; caller should handle these
  // by reading the task's previous status if available.
  TaskStatus.blocked             => 0,
  TaskStatus.paused              => 0,
};

// ── Stepper widget ────────────────────────────────────────────────────────────

class _StageStepper extends StatelessWidget {
  final TaskStatus currentStatus;

  const _StageStepper({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final curIdx = _milestoneIndexFor(currentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _T.slate200)),
      ),
      child: Row(
        children: List.generate(_kMilestones.length * 2 - 1, (i) {

          // ── Connector segment ─────────────────────────────────────────────
          if (i.isOdd) {
            final stageIdx = i ~/ 2;
            // Segment is "done" when the milestone AFTER it is already past.
            final done = stageIdx < curIdx;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: done ? _T.blue : _T.slate200,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }

          // ── Milestone dot + label ─────────────────────────────────────────
          final idx       = i ~/ 2;
          final m         = _kMilestones[idx];
          final isDone    = idx < curIdx;
          final isCurrent = idx == curIdx;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:  26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? _T.blue
                      : isCurrent
                          ? _T.white
                          : _T.slate100,
                  border: Border.all(
                    color: isDone
                        ? _T.blue
                        : isCurrent
                            ? _T.blue
                            : _T.slate200,
                    width: isCurrent ? 2 : 1.5,
                  ),
                  boxShadow: isCurrent
                      ? [BoxShadow(
                          color:      _T.blue.withOpacity(0.15),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : isCurrent
                          ? Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: m.color,
                                shape: BoxShape.circle,
                              ),
                            )
                          : Container(
                              width: 5, height: 5,
                              decoration: const BoxDecoration(
                                color: _T.slate300,
                                shape: BoxShape.circle,
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                m.shortLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:   9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isCurrent
                      ? _T.blue
                      : isDone
                          ? _T.ink3
                          : _T.slate400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE PIPELINE — detail panel component
//
// Default view: 6 milestone rows only.
//
// When the task's current status is an intermediate sub-step (e.g.
// waitingPrinting, printingCompleted, delivered), the parent milestone row
// expands inline to show its sub-steps. This gives the user precise context
// without showing all 18 rows at all times.
//
// Example — task is in `waitingPrinting`:
//
//   ✓  Design
//   ↳  [waiting print] [● printing] [print done]   ← sub-steps inline
//      Printing                                     ← milestone label
//   ○  Finishing
//   ○  Delivery
//   ○  Installing
//   ○  Completed
// ─────────────────────────────────────────────────────────────────────────────

// ── Milestone + sub-step data ─────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// STAGE PIPELINE — detail panel component
//
// Default view: 6 milestone rows only.
//
// When the task's current status is an intermediate sub-step (e.g.
// waitingPrinting, printingCompleted, delivered), ONE extra row is inserted
// immediately after the parent milestone row — showing ONLY the current
// sub-step. No siblings, no indentation — same visual level as milestones.
//
// Example — task is in `waitingPrinting`:
//
//   ✓  Design
//   ◉  Printing            ← milestone (parent context, muted)
//   ●  Waiting for Print   ← single sub-step row, same level, "Now" badge
//   ○  Finishing
//   ○  Delivery
//   ○  Installing
//   ○  Completed
// ─────────────────────────────────────────────────────────────────────────────

// ── Milestone + sub-step data ─────────────────────────────────────────────────

class _PipelineMilestone {
  final String         label;
  final TaskStatus     status;       // canonical milestone status
  final List<TaskStatus> subSteps;   // intermediate statuses within this phase
  //   Empty list = no sub-steps (the milestone IS the only status in its phase)
  const _PipelineMilestone(this.label, this.status, this.subSteps);
}

const List<_PipelineMilestone> _kPipelineMilestones = [
  _PipelineMilestone('Initialized', TaskStatus.pending, []),
  _PipelineMilestone('Design', TaskStatus.designing, [
    // Sub-steps shown when task is in any of these
    TaskStatus.designing,
    TaskStatus.waitingApproval,
    TaskStatus.clientApproved,
    TaskStatus.revision,
  ]),
  _PipelineMilestone('Printing', TaskStatus.printing, [
    TaskStatus.waitingPrinting,
    TaskStatus.printing,
    TaskStatus.printingCompleted,
  ]),
  _PipelineMilestone('Finishing', TaskStatus.finishing, [
    TaskStatus.finishing,
    TaskStatus.productionCompleted,
  ]),
  _PipelineMilestone('Delivery', TaskStatus.delivery, [
    TaskStatus.waitingDelivery,
    TaskStatus.delivery,
    TaskStatus.delivered,
  ]),
  _PipelineMilestone('Installing', TaskStatus.installing, [
    TaskStatus.waitingInstallation,
    TaskStatus.installing,
  ]),
  _PipelineMilestone('Completed', TaskStatus.completed, []),
];

// ── Which milestone index owns a given status ─────────────────────────────────

int _milestoneOf(TaskStatus s) {
  for (int i = 0; i < _kPipelineMilestones.length; i++) {
    final m = _kPipelineMilestones[i];
    if (m.status == s) return i;
    if (m.subSteps.contains(s)) return i;
  }
  return 0;
}

// ── Is this status an intermediate sub-step (not the milestone itself)? ───────
// "Intermediate" = the status is inside a sub-step list but is NOT the
// canonical milestone status. When true, the parent milestone row expands.

bool _isIntermediate(TaskStatus s) {
  for (final m in _kPipelineMilestones) {
    if (m.subSteps.contains(s) && m.status != s) return true;
  }
  return false;
}

// ── Sub-step label map ────────────────────────────────────────────────────────

String _subLabel(TaskStatus s) => switch (s) {
  TaskStatus.pending             => 'Initialized',
  TaskStatus.designing           => 'Designing',
  TaskStatus.waitingApproval     => 'Waiting Approval',
  TaskStatus.clientApproved      => 'Client Approved',
  TaskStatus.revision            => 'Needs Revision',
  TaskStatus.waitingPrinting     => 'Waiting for Print',
  TaskStatus.printing            => 'Printing',
  TaskStatus.printingCompleted   => 'Print Complete',
  TaskStatus.finishing           => 'Finishing',
  TaskStatus.productionCompleted => 'Production Complete',
  TaskStatus.waitingDelivery     => 'Waiting for Delivery',
  TaskStatus.delivery            => 'Out for Delivery',
  TaskStatus.delivered           => 'Delivered',
  TaskStatus.waitingInstallation => 'Waiting for Install',
  TaskStatus.installing          => 'Installing',
  TaskStatus.completed           => 'Completed',
  TaskStatus.blocked             => 'Blocked',
  TaskStatus.paused              => 'Paused',
};

// ── Pipeline widget ───────────────────────────────────────────────────────────

class _StagePipeline extends StatelessWidget {
  final TaskStatus currentStatus;
  // stageInfos used to resolve .bg and .color per status
  final List<DesignStageInfo> stages;

  const _StagePipeline({
    required this.currentStatus,
    required this.stages,
  });

  DesignStageInfo? _infoFor(TaskStatus s) =>
      stages.cast<DesignStageInfo?>()
          .firstWhere((si) => si!.stage == s, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    final curMilestoneIdx = _milestoneOf(currentStatus);
    final intermediate    = _isIntermediate(currentStatus);

    // Pre-resolve the sub-step's DesignStageInfo once (used for the inserted row)
    final subSi       = intermediate ? _infoFor(currentStatus) : null;
    final Color subFg = subSi?.color ?? _T.blue;
    final Color subBg = subSi?.bg    ?? _T.blue50;

    return Container(
      decoration: BoxDecoration(
        border:       Border.all(color: _T.slate200),
        borderRadius: BorderRadius.circular(_T.r),
      ),
      child: Column(
        children: _kPipelineMilestones.asMap().entries.expand((entry) {
          final idx       = entry.key;
          final milestone = entry.value;
          final isDone    = idx < curMilestoneIdx;
          final isCurrent = idx == curMilestoneIdx;

          // Whether a sub-step row should be injected after this milestone
          final injectSubStep = isCurrent && intermediate;

          // Total row count changes when a sub-step is injected, so we
          // compute isLast against the final rendered list rather than
          // _kPipelineMilestones.length. We handle the border on the
          // sub-step row itself when it is injected.
          final isVisuallyLast =
              idx == _kPipelineMilestones.length - 1 && !injectSubStep;

          final si = _infoFor(milestone.status);
          final Color dotColor = si?.color ?? _T.blue;
          final Color bgColor  = si?.bg    ?? _T.blue50;

          // if ();

          return [

            // ── Milestone row ───────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                // When a sub-step row follows, don't highlight the milestone —
                // it becomes a parent-context label, not the active item.
                color: isCurrent && !injectSubStep ? bgColor : Colors.transparent,
                border: isVisuallyLast
                    ? null
                    : const Border(bottom: BorderSide(color: _T.slate100)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [

                  // Dot
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      // When a sub-step is injected the milestone dot is muted
                      // (hollow ring) so the sub-step row reads as "current".
                      color: isDone
                          ? _T.blue
                          : isCurrent && !injectSubStep
                              ? dotColor
                              : _T.slate100,
                      shape: BoxShape.circle,
                      border: injectSubStep && isCurrent
                          ? Border.all(color: dotColor.withOpacity(0.4), width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 11, color: Colors.white)
                          : isCurrent && !injectSubStep
                              ? Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : Container(
                                  width: injectSubStep ? 6 : 5,
                                  height: injectSubStep ? 6 : 5,
                                  decoration: BoxDecoration(
                                    color: injectSubStep
                                        ? dotColor.withOpacity(0.45)
                                        : _T.slate300,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Label
                  Expanded(
                    child: Text(
                      milestone.label,
                      style: TextStyle(
                        fontSize:   12.5,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                        color: isCurrent && !injectSubStep
                            ? dotColor
                            : isDone
                                ? _T.ink3
                                : isCurrent  // injectSubStep case
                                    ? _T.ink3
                                    : _T.slate400,
                      ),
                    ),
                  ),

                  // Badge — only when this milestone IS the current row
                  if (isCurrent && !injectSubStep)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color:        bgColor,
                        border:       Border.all(color: dotColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Current',
                        style: TextStyle(
                          fontSize:   10.5,
                          fontWeight: FontWeight.w700,
                          color:      dotColor,
                        ),
                      ),
                    ),

                  if (isDone)
                    const Text(
                      '✓ Done',
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      _T.slate400,
                      ),
                    ),
                ],
              ),
            ),

            // ── Single sub-step row — injected at the same level ────────────
            if (injectSubStep)
              Container(
                decoration: BoxDecoration(
                  color: subBg,
                  border: Border(
                    top:    BorderSide(color: subFg.withOpacity(0.12)),
                    bottom: idx == _kPipelineMilestones.length - 1
                        ? BorderSide.none
                        : const BorderSide(color: _T.slate100),
                  ),
                ),
                // Identical horizontal padding to milestone rows — same level.
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [

                    // Dot — same size as milestone dots, stage colour
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color:  subFg,
                        shape:  BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Label
                    Expanded(
                      child: Text(
                        _subLabel(currentStatus),
                        style: TextStyle(
                          fontSize:   12.5,
                          fontWeight: FontWeight.w700,
                          color:      subFg,
                        ),
                      ),
                    ),

                    // "Now" badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color:        subBg,
                        border:       Border.all(color: subFg.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Now',
                        style: TextStyle(
                          fontSize:   10.5,
                          fontWeight: FontWeight.w700,
                          color:      subFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

          ];
        }).toList(),
      ),
    );
  }
}

// _SubStepList removed — replaced by the single inline sub-step row above.