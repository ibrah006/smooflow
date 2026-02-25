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

  const DetailPanel({required this.task, required this.projects, required this.onClose, required this.onAdvance});

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
  }

  void _showMoveToNextStageDialog() {

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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _T.slate200))),
            child: Row(
              children: List.generate(kStages.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stageIdx = i ~/ 2;
                  final done = stageIdx < curIdx;
                  return Expanded(child: Container(height: 2, color: done ? _T.blue : _T.slate200));
                }
                final idx = i ~/ 2;
                final s = kStages[idx];
                final isDone    = idx < curIdx;
                final isCurrent = idx == curIdx;
                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? _T.blue : isCurrent ? _T.white : _T.slate100,
                        border: Border.all(color: isDone ? _T.blue : isCurrent ? _T.blue : _T.slate200, width: isCurrent ? 2 : 1.5),
                        boxShadow: isCurrent ? [BoxShadow(color: _T.blue.withOpacity(0.15), blurRadius: 6, spreadRadius: 1)] : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : isCurrent
                                ? Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle))
                                : Container(width: 5, height: 5, decoration: const BoxDecoration(color: _T.slate300, shape: BoxShape.circle)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(s.shortLabel, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isCurrent ? _T.blue : isDone ? _T.ink3 : _T.slate400)),
                  ],
                );
              }),
            ),
          ),

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
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                    child: Column(
                      children: kStages.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final s = entry.value;
                        final isDone    = idx < curIdx;
                        final isCurrent = idx == curIdx;
                        final isLast    = idx == kStages.length - 1;
                        return Container(
                          decoration: BoxDecoration(
                            color: isCurrent ? s.bg : Colors.transparent,
                            border: isLast ? null : const Border(bottom: BorderSide(color: _T.slate100)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(color: isDone ? _T.blue : isCurrent ? s.color : _T.slate100, shape: BoxShape.circle),
                                child: Center(
                                  child: isDone
                                      ? const Icon(Icons.check, size: 11, color: Colors.white)
                                      : isCurrent
                                          ? Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
                                          : Container(width: 5, height: 5, decoration: const BoxDecoration(color: _T.slate300, shape: BoxShape.circle)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(s.label, style: TextStyle(fontSize: 12.5, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500, color: isCurrent ? s.color : isDone ? _T.ink3 : _T.slate400))),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(color: s.bg, border: Border.all(color: s.color.withOpacity(0.3)), borderRadius: BorderRadius.circular(99)),
                                  child: Text('Current', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: s.color)),
                                ),
                              if (isDone)
                                const Text('✓ Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _T.slate400)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
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
                            color: (next == TaskStatus.clientApproved)
                                ? _T.green
                                : ((next == TaskStatus.printing ||
                                        next == TaskStatus.designing ||
                                        next == TaskStatus.waitingApproval ||
                                        (next == TaskStatus.delivery && LoginService.currentUser!.isAdmin))
                                    ? _T.blue
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(_T.r),
                            boxShadow: (next == TaskStatus.clientApproved ||
                                    next == TaskStatus.printing ||
                                    next == TaskStatus.designing ||
                                    next == TaskStatus.waitingApproval ||
                                    (next == TaskStatus.delivery && LoginService.currentUser!.isAdmin))
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
                                next == TaskStatus.clientApproved
                                    ? Icons.check
                                    : Icons.arrow_forward,
                                size: 15,
                                color: (next == TaskStatus.clientApproved ||
                                        next == TaskStatus.printing ||
                                        next == TaskStatus.designing ||
                                        next == TaskStatus.waitingApproval ||
                                        (next == TaskStatus.delivery && LoginService.currentUser!.isAdmin))
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
                                  color: (next == TaskStatus.clientApproved ||
                                          next == TaskStatus.printing ||
                                          next == TaskStatus.designing ||
                                          next == TaskStatus.waitingApproval ||
                                          (next == TaskStatus.delivery && LoginService.currentUser!.isAdmin))
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