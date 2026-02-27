// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PANEL
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static const sidebarW  = 220.0;
  static const topbarH   = 52.0;
  static const detailW   = 400.0;
  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE ORDER
//
// The canonical linear sequence of statuses. Used to derive "previous stages"
// for the stage-back feature. Cross-cutting statuses (blocked, paused,
// revision) are excluded — they have no position in the linear chain.
// ─────────────────────────────────────────────────────────────────────────────
const List<TaskStatus> _kStatusOrder = [
  TaskStatus.pending,
  TaskStatus.designing,
  TaskStatus.waitingApproval,
  TaskStatus.clientApproved,
  TaskStatus.waitingPrinting,
  TaskStatus.printing,
  TaskStatus.printingCompleted,
  TaskStatus.finishing,
  TaskStatus.productionCompleted,
  TaskStatus.waitingDelivery,
  TaskStatus.delivery,
  TaskStatus.delivered,
  TaskStatus.waitingInstallation,
  TaskStatus.installing,
  TaskStatus.completed,
];

/// Returns all statuses that come before [current] in the linear chain.
/// Returns empty list for cross-cutting statuses or [pending] (nothing before).
List<TaskStatus> _previousStatuses(TaskStatus current) {
  final idx = _kStatusOrder.indexOf(current);
  if (idx <= 0) return []; // pending or not in chain (blocked/paused/revision)
  return _kStatusOrder.sublist(0, idx).reversed.toList();
}

/// Human-readable label for any status.
String _statusLabel(TaskStatus s) => switch (s) {
  TaskStatus.pending             => 'Initialized',
  TaskStatus.designing           => 'Designing',
  TaskStatus.waitingApproval     => 'Waiting Approval',
  TaskStatus.clientApproved      => 'Client Approved',
  TaskStatus.waitingPrinting     => 'Waiting Printing',
  TaskStatus.printing            => 'Printing',
  TaskStatus.printingCompleted   => 'Print Complete',
  TaskStatus.finishing           => 'Finishing',
  TaskStatus.productionCompleted => 'Production Complete',
  TaskStatus.waitingDelivery     => 'Waiting Delivery',
  TaskStatus.delivery            => 'Out for Delivery',
  TaskStatus.delivered           => 'Delivered',
  TaskStatus.waitingInstallation => 'Waiting Installation',
  TaskStatus.installing          => 'Installing',
  TaskStatus.completed           => 'Completed',
  TaskStatus.blocked             => 'Blocked',
  TaskStatus.paused              => 'Paused',
  TaskStatus.revision            => 'Needs Revision',
};

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PANEL
// ─────────────────────────────────────────────────────────────────────────────
class DetailPanel extends ConsumerStatefulWidget {
  final Task task;
  final List<Project> projects;
  final VoidCallback onClose;
  final VoidCallback onAdvance;

  const DetailPanel({
    super.key,
    required this.task,
    required this.projects,
    required this.onClose,
    required this.onAdvance,
  });

  @override
  ConsumerState<DetailPanel> createState() => __DetailPanelState();
}

class __DetailPanelState extends ConsumerState<DetailPanel> {

  final GlobalKey _advanceButtonKey   = GlobalKey();
  final GlobalKey _stageBackButtonKey = GlobalKey();

  // ── Unchanged data logic ──────────────────────────────────────────────────

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
    late final TaskStatus nextStage;
    if (widget.task.status == TaskStatus.paused || widget.task.status == TaskStatus.blocked) {
      nextStage = TaskStatus.pending;
    } else if (widget.task.status == TaskStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No explicit next stage from current phase")));
      return;
    } else {
      nextStage = widget.task.status.nextStage!;
    }
    await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: widget.task.id, newStatus: nextStage);
    setState(() {});
    widget.onAdvance();
  }

  // ── Stage-back handler — only data call, no new logic ────────────────────

  Future<void> _stageBackTo(TaskStatus target) async {
    await ref.watch(taskNotifierProvider.notifier).progressStage(
      taskId:    widget.task.id,
      newStatus: target,
    );
    setState(() {});
    widget.onAdvance(); // reuse the same refresh callback
  }

  // ── Stage-back overlay ────────────────────────────────────────────────────

  void _showStageBackMenu() {
    final previous = _previousStatuses(widget.task.status);
    if (previous.isEmpty) return;

    final RenderBox btn = _stageBackButtonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset offset = btn.localToGlobal(Offset.zero, ancestor: overlay);
    final Size btnSize  = btn.size;

    // Max height: 5 rows at ~40px each, or actual count — whichever is smaller
    final menuH = (previous.length * 40.0);

    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'stage-back',
      pageBuilder: (ctx, _, __) => SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        return Stack(
          children: [
            // Invisible barrier that dismisses on tap
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            // Menu — anchored above the button
            Positioned(
              left:  offset.dx,
              top:   offset.dy - menuH - 6,
              width: btnSize.width,
              child: FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end:   Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: _StageBackMenu(
                    statuses:   previous,
                    onSelect:   (s) {
                      Navigator.of(ctx).pop();
                      _stageBackTo(s);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionDuration: const Duration(milliseconds: 180),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final curIdx = stageIndex(widget.task.status);
    final si     = stageInfo(widget.task.status);
    final proj   = widget.projects.cast<Project?>()
        .firstWhere((p) => p!.id == widget.task.projectId, orElse: () => null)
        ?? widget.projects.first;

    Member? member;
    try {
      member = ref.watch(memberNotifierProvider).members
          .firstWhere((m) => widget.task.assignees.contains(m.id));
    } catch (_) {
      member = null;
    }

    final d        = widget.task.createdAt;
    final dueDate  = widget.task.dueDate;
    final now      = DateTime.now();
    final isOverdue = dueDate != null && dueDate.isBefore(now);
    final isSoon    = dueDate != null && !isOverdue && dueDate.difference(now).inDays <= 3;
    final next      = widget.task.status.nextStage;

    final ableToReinitialize =
        widget.task.status == TaskStatus.paused ||
        widget.task.status == TaskStatus.blocked;

    final progressBtnEnabled =
        next != TaskStatus.printing && next != null || ableToReinitialize;

    // Stage-back: available for any status that has predecessors in the chain
    final canStageBack = _previousStatuses(widget.task.status).isNotEmpty;

    return Container(
      width: _T.detailW,
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(left: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        children: [

          // ── Top bar ───────────────────────────────────────────────────────
          Container(
            height: _T.topbarH,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _T.slate200))),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        border:       Border.all(color: _T.slate200),
                        borderRadius: BorderRadius.circular(_T.r),
                      ),
                      child: const Icon(Icons.close, size: 13, color: _T.slate400),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'TASK-${widget.task.id}',
                  style: const TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color:      _T.slate400,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // ── Stage stepper ─────────────────────────────────────────────────
          _StageStepper(currentStatus: widget.task.status),

          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Title
                  Text(
                    widget.task.name,
                    style: const TextStyle(
                      fontFamily:   'Plus Jakarta Sans',
                      fontSize:     16,
                      fontWeight:   FontWeight.w700,
                      color:        _T.ink,
                      letterSpacing: -0.3,
                      height:       1.35,
                    ),
                  ),
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
                        label: 'Start Date',
                        child: Row(children: [
                          Text(fmtDate(d), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isOverdue ? _T.red : isSoon ? _T.amber : _T.ink3)),
                          if (isOverdue) ...[const SizedBox(width: 6), const _Badge('Overdue', _T.red, _T.red50)],
                          if (isSoon && !isOverdue) ...[const SizedBox(width: 6), const _Badge('Due soon', _T.amber, _T.amber50)],
                        ]),
                      ),
                      _DetailMetaCell(
                        label: 'Due Date',
                        child: dueDate != null
                            ? Row(children: [
                                Text(fmtDate(dueDate), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isOverdue ? _T.red : isSoon ? _T.amber : _T.ink3)),
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
                      decoration: BoxDecoration(
                        color:        _T.slate50,
                        border:       Border.all(color: _T.slate200),
                        borderRadius: BorderRadius.circular(_T.r),
                      ),
                      child: Text(widget.task.description, style: const TextStyle(fontSize: 13, color: _T.slate500, height: 1.65)),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Stage pipeline
                  const _DetailSectionTitle('Stage Pipeline'),
                  const SizedBox(height: 8),
                  _StagePipeline(
                    currentStatus: widget.task.status,
                    stages: kStages,
                  ),
                ],
              ),
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────────
          _DetailFooter(
            task:               widget.task,
            next:               next,
            progressBtnEnabled: progressBtnEnabled,
            ableToReinitialize: ableToReinitialize,
            canStageBack:       canStageBack,
            advanceButtonKey:   _advanceButtonKey,
            stageBackButtonKey: _stageBackButtonKey,
            onAdvanceTap: () {
              if (!progressBtnEnabled) return;
              if (next == TaskStatus.clientApproved) {
                approveDesignStage();
              } else {
                _showMoveToNextStageDialog();
              }
            },
            onStageBackTap: _showStageBackMenu,
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL FOOTER
//
// Three possible states:
//   1. Locked (next == printing): lock icon + message, no actions.
//   2. Normal: primary advance button. If canStageBack, a secondary
//      "Stage back" text button sits below it.
//
// The stage-back button is visually subordinate:
//   • No filled background, no border — plain text with a left-arrow icon.
//   • slate500 colour — present but not competing with the primary action.
//   • On tap, opens _StageBackMenu anchored above the button.
// ─────────────────────────────────────────────────────────────────────────────
class _DetailFooter extends StatelessWidget {
  final Task       task;
  final TaskStatus? next;
  final bool       progressBtnEnabled;
  final bool       ableToReinitialize;
  final bool       canStageBack;
  final GlobalKey  advanceButtonKey;
  final GlobalKey  stageBackButtonKey;
  final VoidCallback onAdvanceTap;
  final VoidCallback onStageBackTap;

  const _DetailFooter({
    required this.task,
    required this.next,
    required this.progressBtnEnabled,
    required this.ableToReinitialize,
    required this.canStageBack,
    required this.advanceButtonKey,
    required this.stageBackButtonKey,
    required this.onAdvanceTap,
    required this.onStageBackTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = next == TaskStatus.printing;

    return Container(
      decoration: const BoxDecoration(
        color:  _T.slate50,
        border: Border(top: BorderSide(color: _T.slate200)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (task.status != TaskStatus.completed) (isLocked
              // ── Locked state ─────────────────────────────────────────────────
              ? Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 14, color: _T.slate400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Handed off to production${LoginService.currentUser!.isAdmin ? '' : ' — design locked'}',
                        style: const TextStyle(fontSize: 12.5, color: _T.slate400),
                      ),
                    ),
                  ],
                )
              // ── Advance + optional stage-back ─────────────────────────────────
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
          
                    // Section label
                    const Text(
                      'ADVANCE STAGE',
                      style: TextStyle(
                        fontSize:      9.5,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 1.0,
                        color:         _T.slate400,
                      ),
                    ),
                    const SizedBox(height: 9),
          
                    // Primary advance button — unchanged from original
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        key: advanceButtonKey,
                        onTap: onAdvanceTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: ableToReinitialize
                                ? _T.slate400
                                : (next == TaskStatus.clientApproved)
                                    ? _T.green
                                    : ((next == TaskStatus.designing ||
                                            next == TaskStatus.waitingApproval ||
                                            ((next == TaskStatus.waitingPrinting ||
                                                    next == TaskStatus.printingCompleted ||
                                                    next == TaskStatus.finishing ||
                                                    next == TaskStatus.productionCompleted ||
                                                    next == TaskStatus.waitingDelivery ||
                                                    next == TaskStatus.delivery ||
                                                    next == TaskStatus.waitingInstallation ||
                                                    next == TaskStatus.installing ||
                                                    next == TaskStatus.completed) &&
                                                LoginService.currentUser!.isAdmin))
                                        ? _T.blue
                                        : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(_T.r),
                            boxShadow: progressBtnEnabled
                                ? [
                                    BoxShadow(
                                      color: (ableToReinitialize
                                              ? _T.slate400
                                              : (next == TaskStatus.clientApproved)
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
                                progressBtnEnabled ? Icons.check : Icons.arrow_forward,
                                size: 15,
                                color: progressBtnEnabled ? Colors.white : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                next == TaskStatus.clientApproved
                                    ? 'Confirm Client Approval'
                                    : ableToReinitialize
                                        ? 'Re-initialize Task'
                                        : 'Move to "${stageInfo(next!).label}"',
                                style: TextStyle(
                                  fontSize:   13.5,
                                  fontWeight: FontWeight.w700,
                                  color: progressBtnEnabled ? Colors.white : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
                // ── Stage-back button (subordinate) ───────────────────────
                    if (canStageBack) ...[
                      const SizedBox(height: 1),
                      // Divider with label — visually separates the two actions
                      if (task.status != TaskStatus.completed) Row(
                        children: [
                          const Expanded(child: Divider(color: _T.slate200, height: 20)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'or',
                              style: const TextStyle(
                                fontSize:   10.5,
                                color:      _T.slate400,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: _T.slate200, height: 20)),
                        ],
                      ),
                      // Stage-back trigger — text-only, no fill
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          key: stageBackButtonKey,
                          onTap: onStageBackTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color:        Colors.transparent,
                              border:       Border.all(color: _T.slate200),
                              borderRadius: BorderRadius.circular(_T.r),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back_rounded, size: 12, color: _T.slate500),
                                SizedBox(width: 6),
                                Text(
                                  'Stage back',
                                  style: TextStyle(
                                    fontSize:   12,
                                    fontWeight: FontWeight.w500,
                                    color:      _T.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE BACK MENU
//
// A flat dropdown anchored above the "Stage back" button.
// Shows all preceding statuses in reverse order (most recent first).
//
// Design language matches the _DetailDrawer in board_view.dart:
//   • White surface, 1px slate200 border, rLg radius.
//   • Rows: ink2 text, hover = slate50 bg, no fills.
//   • A thin 2px amber left rule is the only colour signal — amber because
//     staging back is a corrective/cautionary action, not a destructive one.
// ─────────────────────────────────────────────────────────────────────────────
class _StageBackMenu extends StatelessWidget {
  final List<TaskStatus>          statuses;
  final ValueChanged<TaskStatus>  onSelect;

  const _StageBackMenu({
    required this.statuses,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:       Colors.transparent,
      elevation:   0,
      child: Container(
        decoration: BoxDecoration(
          color:        _T.white,
          border:       Border.all(color: _T.slate200),
          borderRadius: BorderRadius.circular(_T.rLg),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_T.rLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _T.slate100)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 2, height: 12,
                      decoration: BoxDecoration(
                        color:        _T.amber,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MOVE BACK TO',
                      style: TextStyle(
                        fontSize:      9.5,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 0.9,
                        color:         _T.slate500,
                      ),
                    ),
                  ],
                ),
              ),

              // Status rows
              ...statuses.asMap().entries.map((entry) {
                final i  = entry.key;
                final s  = entry.value;
                final isLast = i == statuses.length - 1;
                return _StageBackRow(
                  status: s,
                  isLast: isLast,
                  onTap:  () => onSelect(s),
                );
              }),

            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE BACK ROW
// ─────────────────────────────────────────────────────────────────────────────
class _StageBackRow extends StatefulWidget {
  final TaskStatus   status;
  final bool         isLast;
  final VoidCallback onTap;

  const _StageBackRow({
    required this.status,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_StageBackRow> createState() => _StageBackRowState();
}

class _StageBackRowState extends State<_StageBackRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Show the position in the chain as a subtle numeric hint
    final chainIdx = _kStatusOrder.indexOf(widget.status);

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color:  _hovered ? _T.slate50 : Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              border: widget.isLast
                  ? null
                  : const Border(bottom: BorderSide(color: _T.slate100)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
          
                // Chain position number — tabular, slate300, gives spatial context
                SizedBox(
                  width: 18,
                  child: Text(
                    '${chainIdx + 1}',
                    style: const TextStyle(
                      fontSize:      10,
                      fontWeight:    FontWeight.w600,
                      color:         _T.slate300,
                      fontFeatures:  [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
          
                const SizedBox(width: 8),
          
                // Status label
                Expanded(
                  child: Text(
                    _statusLabel(widget.status),
                    style: const TextStyle(
                      fontSize:   12.5,
                      fontWeight: FontWeight.w500,
                      color:      _T.ink2,
                    ),
                  ),
                ),
          
                // Arrow — appears on hover
                AnimatedOpacity(
                  opacity:  _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 100),
                  child: const Icon(Icons.arrow_back_rounded, size: 12, color: _T.slate400),
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
// UNCHANGED COMPONENTS — verbatim from original
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSectionTitle extends StatelessWidget {
  final String text;
  const _DetailSectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize:      9.5,
      fontWeight:    FontWeight.w700,
      letterSpacing: 1.0,
      color:         _T.slate400,
    ),
  );
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
// STAGE STEPPER — unchanged from previous version
// ─────────────────────────────────────────────────────────────────────────────

class _Milestone {
  final String     shortLabel;
  final TaskStatus status;
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

int _milestoneIndexFor(TaskStatus status) => switch (status) {
  TaskStatus.pending             => 0,
  TaskStatus.designing           => 0,
  TaskStatus.waitingApproval     => 0,
  TaskStatus.clientApproved      => 0,
  TaskStatus.revision            => 0,
  TaskStatus.waitingPrinting     => 1,
  TaskStatus.printing            => 1,
  TaskStatus.printingCompleted   => 1,
  TaskStatus.finishing           => 2,
  TaskStatus.productionCompleted => 2,
  TaskStatus.waitingDelivery     => 3,
  TaskStatus.delivery            => 3,
  TaskStatus.delivered           => 3,
  TaskStatus.waitingInstallation => 4,
  TaskStatus.installing          => 4,
  TaskStatus.completed           => 5,
  TaskStatus.blocked             => 0,
  TaskStatus.paused              => 0,
};

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
          if (i.isOdd) {
            final done = (i ~/ 2) < curIdx;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color:        done ? _T.blue : _T.slate200,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final idx       = i ~/ 2;
          final m         = _kMilestones[idx];
          final isDone    = idx < curIdx;
          final isCurrent = idx == curIdx;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? _T.blue : isCurrent ? _T.white : _T.slate100,
                  border: Border.all(
                    color: isDone ? _T.blue : isCurrent ? _T.blue : _T.slate200,
                    width: isCurrent ? 2 : 1.5,
                  ),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: _T.blue.withOpacity(0.15), blurRadius: 6, spreadRadius: 1)]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : isCurrent
                          ? Container(width: 8, height: 8, decoration: BoxDecoration(color: m.color, shape: BoxShape.circle))
                          : Container(width: 5, height: 5, decoration: const BoxDecoration(color: _T.slate300, shape: BoxShape.circle)),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                m.shortLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:      9,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isCurrent ? _T.blue : isDone ? _T.ink3 : _T.slate400,
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
// STAGE PIPELINE — unchanged from previous version
// ─────────────────────────────────────────────────────────────────────────────

class _PipelineMilestone {
  final String           label;
  final TaskStatus       status;
  final List<TaskStatus> subSteps;
  const _PipelineMilestone(this.label, this.status, this.subSteps);
}

const List<_PipelineMilestone> _kPipelineMilestones = [
  _PipelineMilestone('Initialized', TaskStatus.pending, []),
  _PipelineMilestone('Design', TaskStatus.designing, [
    TaskStatus.designing,
    TaskStatus.waitingApproval,
    TaskStatus.clientApproved,
    TaskStatus.revision,
  ]),
  _PipelineMilestone('Printing Department', TaskStatus.printing, [
    TaskStatus.waitingPrinting,
    TaskStatus.printing,
    TaskStatus.printingCompleted,
  ]),
  _PipelineMilestone('Finishing Department', TaskStatus.finishing, [
    TaskStatus.finishing,
    TaskStatus.productionCompleted,
  ]),
  _PipelineMilestone('Delivery Department', TaskStatus.delivery, [
    TaskStatus.waitingDelivery,
    TaskStatus.delivery,
    TaskStatus.delivered,
  ]),
  _PipelineMilestone('Installation Department', TaskStatus.installing, [
    TaskStatus.waitingInstallation,
    TaskStatus.installing,
  ]),
  _PipelineMilestone('Completed', TaskStatus.completed, []),
];

int _milestoneOf(TaskStatus s) {
  for (int i = 0; i < _kPipelineMilestones.length; i++) {
    final m = _kPipelineMilestones[i];
    if (m.status == s) return i;
    if (m.subSteps.contains(s)) return i;
  }
  return 0;
}

bool _isIntermediate(TaskStatus s) {
  for (final m in _kPipelineMilestones) {
    if (m.subSteps.contains(s) && m.status != s) return true;
  }
  return false;
}

String _subLabel(TaskStatus s) => switch (s) {
  TaskStatus.pending             => 'Initialized',
  TaskStatus.designing           => 'Designing',
  TaskStatus.waitingApproval     => 'Waiting Approval',
  TaskStatus.clientApproved      => 'Client Approved',
  TaskStatus.revision            => 'Needs Revision',
  TaskStatus.waitingPrinting     => 'Handed to Print',
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

class _StagePipeline extends StatelessWidget {
  final TaskStatus            currentStatus;
  final List<DesignStageInfo> stages;

  const _StagePipeline({required this.currentStatus, required this.stages});

  DesignStageInfo? _infoFor(TaskStatus s) =>
      stages.cast<DesignStageInfo?>()
          .firstWhere((si) => si!.stage == s, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    final curMilestoneIdx = _milestoneOf(currentStatus);
    final intermediate    = _isIntermediate(currentStatus);
    final subSi           = intermediate ? _infoFor(currentStatus) : null;
    final Color subFg     = subSi?.color ?? _T.blue;
    final Color subBg     = subSi?.bg    ?? _T.blue50;

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
          final injectSubStep   = isCurrent && intermediate;
          final isVisuallyLast  = idx == _kPipelineMilestones.length - 1 && !injectSubStep;
          final si          = _infoFor(milestone.status);
          final Color dotColor = si?.color ?? _T.blue;
          final Color bgColor  = si?.bg    ?? _T.blue50;

          return [
            Container(
              decoration: BoxDecoration(
                color: isCurrent && !injectSubStep ? bgColor : Colors.transparent,
                border: isVisuallyLast ? null : const Border(bottom: BorderSide(color: _T.slate100)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: isDone
                          ? _T.blue
                          : isCurrent && !injectSubStep ? dotColor : _T.slate100,
                      shape: BoxShape.circle,
                      border: injectSubStep && isCurrent
                          ? Border.all(color: dotColor.withOpacity(0.4), width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 11, color: Colors.white)
                          : isCurrent && !injectSubStep
                              ? Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
                              : Container(
                                  width: injectSubStep ? 6 : 5,
                                  height: injectSubStep ? 6 : 5,
                                  decoration: BoxDecoration(
                                    color: injectSubStep ? dotColor.withOpacity(0.45) : _T.slate300,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      milestone.label,
                      style: TextStyle(
                        fontSize:   12.5,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                        color: isCurrent && !injectSubStep
                            ? dotColor
                            : isDone ? _T.ink3
                            : isCurrent ? _T.ink3
                            : _T.slate400,
                      ),
                    ),
                  ),
                  if (isCurrent && !injectSubStep)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color:        bgColor,
                        border:       Border.all(color: dotColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('Current', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: dotColor)),
                    ),
                  if (isDone)
                    const Text('✓ Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _T.slate400)),
                ],
              ),
            ),
            if (injectSubStep)
              Container(
                decoration: BoxDecoration(
                  color: subBg,
                  border: Border(
                    top:    BorderSide(color: subFg.withOpacity(0.12)),
                    bottom: idx == _kPipelineMilestones.length - 1 ? BorderSide.none : const BorderSide(color: _T.slate100),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: subFg, shape: BoxShape.circle),
                      child: Center(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_subLabel(currentStatus), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: subFg)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color:        subBg,
                        border:       Border.all(color: subFg.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('Now', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: subFg)),
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