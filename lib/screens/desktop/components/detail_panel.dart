// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PANEL
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/billing_status.dart';
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
// BILLING STATUS ENUM + METADATA
//
// If you create smooflow/enums/billing_status.dart later, move the enum there
// and add its import at the top of this file.  The metadata class and the
// _kBillingStatuses list should stay here — they are UI-layer concerns.
// ─────────────────────────────────────────────────────────────────────────────

class _BillingMeta {
  final BillingStatus value;
  final String        label;
  final String        sublabel;   // one-liner shown inside the chip
  final Color         color, bg;
  final IconData      icon;
  const _BillingMeta({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.bg,
    required this.icon,
  });
}

const List<_BillingMeta> _kBilling = [
  _BillingMeta(
    value:    BillingStatus.pending,
    label:    'Pending',
    sublabel: 'Awaiting quote',
    color:    _T.amber,
    bg:       _T.amber50,
    icon:     Icons.hourglass_empty_rounded,
  ),
  _BillingMeta(
    value:    BillingStatus.quoteGiven,
    label:    'Quote Given',
    sublabel: 'Quote sent to client',
    color:    _T.blue,
    bg:       _T.blue50,
    icon:     Icons.request_quote_outlined,
  ),
  _BillingMeta(
    value:    BillingStatus.invoiced,
    label:    'Invoiced',
    sublabel: 'Invoice raised',
    color:    _T.purple,
    bg:       _T.purple50,
    icon:     Icons.receipt_long_outlined,
  ),
  _BillingMeta(
    value:    BillingStatus.foc,
    label:    'FOC',
    sublabel: 'Free of charge',
    color:    _T.green,
    bg:       _T.green50,
    icon:     Icons.volunteer_activism_outlined,
  ),
  _BillingMeta(
    value:    BillingStatus.cancelled,
    label:    'Cancelled',
    sublabel: 'Task cancelled',
    color:    _T.red,
    bg:       _T.red50,
    icon:     Icons.cancel_outlined,
  ),
];

_BillingMeta _billingMeta(BillingStatus s) =>
    _kBilling.firstWhere((m) => m.value == s);

// ─────────────────────────────────────────────────────────────────────────────
// STAGE ORDER
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

List<TaskStatus> _previousStatuses(TaskStatus current) {
  final idx = _kStatusOrder.indexOf(current);
  if (idx <= 0) return [];
  return _kStatusOrder.sublist(0, idx).reversed.toList();
}

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

  bool _isProgressing = false;

  // ── Billing state ─────────────────────────────────────────────────────────
  // Tracks the in-panel selection before it is committed via Save.
  late BillingStatus _billingSelection;
  bool _billingSaving = false;

  bool get _isAccountant =>
      LoginService.currentUser?.role == 'accountant' ||
      LoginService.currentUser?.isAdmin == true;

  bool get _billingDirty {
    final saved = widget.task.billingStatus ?? BillingStatus.pending;
    return _billingSelection != saved;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _billingSelection = widget.task.billingStatus ?? BillingStatus.pending;
  }

  @override
  void didUpdateWidget(DetailPanel old) {
    super.didUpdateWidget(old);
    // Reset local billing selection when the panel is opened for a new task.
    if (old.task.id != widget.task.id) {
      _billingSelection = widget.task.billingStatus ?? BillingStatus.pending;
    }
  }

  // ── Billing save ──────────────────────────────────────────────────────────

  Future<void> _saveBillingStatus() async {
    setState(() => _billingSaving = true);
    try {
      // await ref.read(taskNotifierProvider.notifier).updateBillingStatus(
      //   taskId: widget.task.id,
      //   status: _billingSelection,
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 15, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Billing updated to ${_billingMeta(_billingSelection).label}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ]),
          backgroundColor: _T.ink,
          behavior:        SnackBarBehavior.floating,
          margin:          const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_T.r)),
          duration: const Duration(seconds: 3),
        ));
      }
    } finally {
      if (mounted) setState(() => _billingSaving = false);
    }
  }

  // ── Unchanged data logic (verbatim) ──────────────────────────────────────

  Future<void> approveDesignStage() async {
    final nextStage = widget.task.status.nextStage;
    if (nextStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to advance stage")));
      return;
    }
    await ref.watch(taskNotifierProvider.notifier).progressStage(taskId: widget.task.id, newStatus: nextStage);
    setState(() {});
    widget.onAdvance();
  }

  Future<void> _showMoveToNextStageDialog() async {
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

  Future<void> _stageBackTo(TaskStatus target) async {
    print("target task status: $target");
    await ref.watch(taskNotifierProvider.notifier).progressStage(
      taskId:    widget.task.id,
      newStatus: target,
    );
    setState(() {});
    widget.onAdvance();
  }

  bool dismissed = false;

  void _showStageBackMenu() {
    final previous = _previousStatuses(widget.task.status);
    if (previous.isEmpty) return;

    final RenderBox btn = _stageBackButtonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset offset = btn.localToGlobal(Offset.zero, ancestor: overlay);
    final Size btnSize  = btn.size;
    final menuH = (previous.length * 40.0);
    dismissed = false;

    showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      barrierLabel: 'stage-back',
      pageBuilder: (ctx, _, __) => SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (dismissed) return;
                  dismissed = true;
                  Navigator.of(ctx).pop();
                },
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
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
                    statuses: previous,
                    onSelect: (s) {
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

    final canStageBack = _previousStatuses(widget.task.status).isNotEmpty;

    // Print-specs visibility flags
    final hasRef  = widget.task.ref?.isNotEmpty == true;
    final hasSize = widget.task.size != null;
    final hasQty  = widget.task.quantity != null;
    final hasPrintSpecs = hasRef || hasSize || hasQty;

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

                  // ── PRINT SPECIFICATIONS ─────────────────────────────────
                  // Only rendered when at least one field has a value.
                  if (hasPrintSpecs) ...[
                    const _DetailSectionTitle('Print Specifications'),
                    const SizedBox(height: 10),
                    _PrintSpecsCard(
                      reference: widget.task.ref,
                      size:     widget.task.size,
                      quantity:  widget.task.quantity,
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── BILLING ───────────────────────────────────────────────
                  const _DetailSectionTitle('Billing'),
                  const SizedBox(height: 10),
                  _BillingCard(
                    savedStatus:   widget.task.billingStatus ?? BillingStatus.pending,
                    selection:     _billingSelection,
                    isAccountant:  _isAccountant,
                    isDirty:       _billingDirty,
                    isSaving:      _billingSaving,
                    onSelect:      (s) => setState(() => _billingSelection = s),
                    onSave:        _saveBillingStatus,
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
            isProgressing: _isProgressing,
            onAdvanceTap: () async {
              if (!progressBtnEnabled) return;
              setState(() {
                _isProgressing = true;
              });
              if (next == TaskStatus.clientApproved) {
                await approveDesignStage();
              } else {
                await _showMoveToNextStageDialog();
              }
              setState(() {
                _isProgressing = false;
              });
            },
            onStageBackTap: _showStageBackMenu,
          ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRINT SPECIFICATIONS CARD
//
// Rendered only when at least one of ref / sizeW+sizeH / quantity is set.
//
// Anatomy:
//   purple icon header  ← matches the print specs section in create_task_screen
//   slate100 divider
//   _SpecRow × N        ← icon slug + fixed-width label + value widget
//
// ref     → monospace code tag  (slate100 bg, slate200 border, rounding 5)
// size    → large numerals + weight-300 × separator + "cm" suffix
// qty     → large numeral + "pcs" suffix
//
// Rows that have no value are simply not rendered.
// ─────────────────────────────────────────────────────────────────────────────
class _PrintSpecsCard extends StatelessWidget {
  final String?  reference;
  final String?  size;
  final int?     quantity;

  const _PrintSpecsCard({
    required this.reference,
    required this.size,
    required this.quantity,
  });

  // "3.0" → "3", "3.5" → "3.5"
  // String _dim(double v) =>
  //     v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Widget specRow(String size) {
    final sizeSplitted = size.split("×");

    return Row(
      mainAxisSize:        MainAxisSize.min,
      crossAxisAlignment:  CrossAxisAlignment.baseline,
      textBaseline:        TextBaseline.alphabetic,
      children: [
        Text(sizeSplitted[0],
            style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _T.ink)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Text('×',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w300, color: _T.slate300)),
        ),
        Text(sizeSplitted[1].split(" ")[0],
            style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _T.ink)),
        if (sizeSplitted[1].split(" ").length > 1) ...[
          const SizedBox(width: 5),
          Text(sizeSplitted[1].split(" ")[1],
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: _T.slate400)),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRef  = reference?.isNotEmpty == true;
    final hasSize = size!=null;
    final hasQty  = quantity != null;

    // Build only the rows that have data.
    final rows = <Widget>[];

    

    if (hasRef) {
      rows.add(_SpecRow(
        icon:  Icons.tag_rounded,
        label: 'Ref',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color:        _T.slate100,
            borderRadius: BorderRadius.circular(5),
            border:       Border.all(color: _T.slate200),
          ),
          child: Text(
            reference!,
            style: const TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      _T.ink3,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ));
    }

    if (hasSize) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(_SpecRow(
        icon:  Icons.crop_free_rounded,
        label: 'Size',
        child: specRow(size!)
      ));
    }

    if (hasQty) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(_SpecRow(
        icon:  Icons.inventory_2_outlined,
        label: 'Qty',
        child: Row(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline:       TextBaseline.alphabetic,
          children: [
            Text('$quantity',
                style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _T.ink)),
            const SizedBox(width: 5),
            const Text('pcs',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: _T.slate400)),
          ],
        ),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color:        _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border:       Border.all(color: _T.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Card header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color:        _T.purple50,
                  borderRadius: BorderRadius.circular(8),
                  border:       Border.all(color: _T.purple.withOpacity(0.2)),
                ),
                child: const Icon(Icons.straighten_outlined,
                    size: 15, color: _T.purple),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Print Specs',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _T.ink)),
                  Text('Reference, dimensions & quantity',
                      style: TextStyle(fontSize: 11, color: _T.slate400)),
                ],
              ),
            ]),
          ),

          // ── Divider ──────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child:   Divider(height: 1, color: _T.slate100),
          ),

          // ── Spec rows ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child:   Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEC ROW
// icon slug (28×28, slate100) + fixed-width label (slate400) + value widget
// ─────────────────────────────────────────────────────────────────────────────
class _SpecRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Widget   child;
  const _SpecRow({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color:        _T.slate100,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 14, color: _T.slate500),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 38,
        child: Text(label,
            style: const TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w500, color: _T.slate400)),
      ),
      child,
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BILLING CARD
//
// Green-themed header (finance = green). Always shows the current saved status
// as a compact pill in the top-right of the header so any role can read it at
// a glance without scrolling into the body.
//
// Body — two modes:
//
//   Accountant / Admin:
//     Five chips in a Wrap (2 per row at the 364px content width).
//     Each chip: icon circle + label + sublabel + check mark.
//     Selecting a chip that differs from the saved status shows a "Save"
//     FilledButton that slides in via AnimatedSize.
//
//   Everyone else:
//     A large status badge (icon + label) + a lock note.
//     Read-only; no interactive elements.
// ─────────────────────────────────────────────────────────────────────────────
class _BillingCard extends StatelessWidget {
  final BillingStatus              savedStatus;
  final BillingStatus              selection;
  final bool                       isAccountant;
  final bool                       isDirty;
  final bool                       isSaving;
  final ValueChanged<BillingStatus> onSelect;
  final VoidCallback               onSave;

  const _BillingCard({
    required this.savedStatus,
    required this.selection,
    required this.isAccountant,
    required this.isDirty,
    required this.isSaving,
    required this.onSelect,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final saved = _billingMeta(savedStatus);

    return Container(
      decoration: BoxDecoration(
        color:        _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border:       Border.all(color: _T.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color:        _T.green50,
                    borderRadius: BorderRadius.circular(8),
                    border:       Border.all(color: _T.green.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      size: 15, color: _T.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Billing Status',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: _T.ink)),
                      Text(
                        isAccountant
                            ? 'Select the current billing stage'
                            : 'Managed by accounting',
                        style: const TextStyle(fontSize: 11, color: _T.slate400),
                      ),
                    ],
                  ),
                ),
                // Current saved status — always visible, any role can read this
                _BillingPill(meta: saved),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child:   Divider(height: 1, color: _T.slate100),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: isAccountant
                ? _BillingPicker(
                    selection: selection,
                    isDirty:   isDirty,
                    isSaving:  isSaving,
                    onSelect:  onSelect,
                    onSave:    onSave,
                  )
                : _BillingReadOnly(meta: saved),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILLING PILL — compact status indicator shown in card header
// ─────────────────────────────────────────────────────────────────────────────
class _BillingPill extends StatelessWidget {
  final _BillingMeta meta;
  const _BillingPill({required this.meta});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color:        meta.bg,
      borderRadius: BorderRadius.circular(99),
      border:       Border.all(color: meta.color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 5, height: 5,
        decoration: BoxDecoration(color: meta.color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(meta.label,
          style: TextStyle(
            fontSize:   10.5,
            fontWeight: FontWeight.w700,
            color:      meta.color,
          )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BILLING PICKER  (accountant / admin)
//
// Five chips in a Wrap. Panel content width = 400 − 18 − 18 − 14 − 14 = 336px.
// Two chips per row: (336 − 8) / 2 = 164px each.
//
// Each chip:
//   ┌──────────────────────────────────────────┐
//   │ [icon 28×28]  Label         ✓ (if active)│
//   │               sublabel                   │
//   └──────────────────────────────────────────┘
//
// Selected chip: coloured bg + coloured border + coloured text + box shadow.
// AnimatedSize drives the Save button in from zero height when isDirty.
// ─────────────────────────────────────────────────────────────────────────────
class _BillingPicker extends StatelessWidget {
  final BillingStatus              selection;
  final bool                       isDirty;
  final bool                       isSaving;
  final ValueChanged<BillingStatus> onSelect;
  final VoidCallback               onSave;

  const _BillingPicker({
    required this.selection,
    required this.isDirty,
    required this.isSaving,
    required this.onSelect,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // Chip grid — Wrap so long labels never overflow
        Wrap(
          spacing:     8,
          runSpacing:  8,
          children: _kBilling.map((m) {
            final active = selection == m.value;
            return GestureDetector(
              onTap: () => onSelect(m.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve:    Curves.easeOut,
                width:    164,
                padding:  const EdgeInsets.fromLTRB(10, 9, 10, 9),
                decoration: BoxDecoration(
                  color: active ? m.bg : _T.white,
                  borderRadius: BorderRadius.circular(_T.r),
                  border: Border.all(
                    color: active ? m.color.withOpacity(0.45) : _T.slate200,
                    width: active ? 1.5 : 1,
                  ),
                  boxShadow: active
                      ? [BoxShadow(
                          color:      m.color.withOpacity(0.12),
                          blurRadius: 10,
                          offset:     const Offset(0, 3))]
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: active
                            ? m.color.withOpacity(0.14)
                            : _T.slate100,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(m.icon,
                          size:  14,
                          color: active ? m.color : _T.slate400),
                    ),
                    const SizedBox(width: 8),
                    // Label + sublabel
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(m.label,
                                  style: TextStyle(
                                    fontSize:   12,
                                    fontWeight: FontWeight.w700,
                                    color: active ? m.color : _T.ink3,
                                  )),
                            ),
                            // Check mark fades in when selected
                            AnimatedOpacity(
                              opacity:  active ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: Icon(Icons.check_circle_rounded,
                                  size: 12, color: m.color),
                            ),
                          ]),
                          const SizedBox(height: 2),
                          Text(m.sublabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: active
                                    ? m.color.withOpacity(0.7)
                                    : _T.slate400,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Save button — only visible when selection differs from saved value.
        // AnimatedSize collapses it to zero height when clean.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve:    Curves.easeOutCubic,
          child: isDirty
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton.icon(
                    onPressed: isSaving ? null : onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor:         _T.blue,
                      disabledBackgroundColor: _T.slate200,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_T.r)),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      isSaving ? 'Saving…' : 'Update Billing Status',
                      style: const TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BILLING READ-ONLY  (non-accountant view)
// ─────────────────────────────────────────────────────────────────────────────
class _BillingReadOnly extends StatelessWidget {
  final _BillingMeta meta;
  const _BillingReadOnly({required this.meta});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      // Large badge with icon
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        meta.bg,
          borderRadius: BorderRadius.circular(_T.r),
          border:       Border.all(color: meta.color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(meta.icon, size: 14, color: meta.color),
          const SizedBox(width: 7),
          Text(meta.label,
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w700,
                color:      meta.color,
              )),
        ]),
      ),
      const SizedBox(width: 10),
      // Lock note
      const Expanded(
        child: Row(children: [
          Icon(Icons.lock_outline_rounded, size: 11, color: _T.slate300),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              'Only accountants can update this',
              style: TextStyle(fontSize: 10.5, color: _T.slate400),
            ),
          ),
        ]),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL FOOTER — verbatim from original
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
  final bool isProgressing;

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
    required this.isProgressing,
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        key: advanceButtonKey,
                        onTap: isProgressing ? null : onAdvanceTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isProgressing ? Colors.grey.shade100 : (ableToReinitialize
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
                                        : Colors.grey.shade200)),
                            borderRadius: BorderRadius.circular(_T.r),
                            boxShadow: isProgressing ? null : (progressBtnEnabled
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
                                : null),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isProgressing) SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.75, color: Colors.grey.shade400))
                              else Icon(
                                progressBtnEnabled ? Icons.check : Icons.arrow_forward,
                                size: 15,
                                color: progressBtnEnabled ? Colors.white : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isProgressing ? "Progressing" : (next == TaskStatus.clientApproved
                                    ? 'Confirm Client Approval'
                                    : ableToReinitialize
                                        ? 'Re-initialize Task'
                                        : 'Move to "${stageInfo(next!).label}"'),
                                style: TextStyle(
                                  fontSize:   13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isProgressing ? Colors.grey.shade400 : (progressBtnEnabled ? Colors.white : Colors.grey.shade400),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
              if (canStageBack) ...[
                const SizedBox(height: 1),
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
// STAGE BACK MENU — verbatim from original
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
// STAGE BACK ROW — verbatim from original
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
// STAGE STEPPER — verbatim from original
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
// STAGE PIPELINE — verbatim from original
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
  _PipelineMilestone('Production', TaskStatus.printing, [
    TaskStatus.waitingPrinting,
    TaskStatus.printing,
    TaskStatus.printingCompleted,
  ]),
  _PipelineMilestone('Finishing Dept', TaskStatus.finishing, [
    TaskStatus.finishing,
    TaskStatus.productionCompleted,
  ]),
  _PipelineMilestone('Delivery', TaskStatus.delivery, [
    TaskStatus.waitingDelivery,
    TaskStatus.delivery,
    TaskStatus.delivered,
  ]),
  _PipelineMilestone('Installation', TaskStatus.installing, [
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

    final subSi       = intermediate ? _infoFor(currentStatus) : null;
    final Color subFg = subSi?.color ?? _T.blue;
    final Color subBg = subSi?.bg    ?? _T.blue50;

    return Container(
      decoration: BoxDecoration(
        border:       Border.all(color: _T.slate200),
        borderRadius: BorderRadius.circular(_T.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_T.r),
        child: Column(
          children: _kPipelineMilestones.asMap().entries.expand((entry) {
            final idx       = entry.key;
            final milestone = entry.value;
            final isDone    = idx < curMilestoneIdx;
            final isCurrent = idx == curMilestoneIdx;

            final injectSubSteps = isCurrent && intermediate;

            final List<TaskStatus> visibleSubSteps = injectSubSteps
                ? milestone.subSteps.sublist(
                    0,
                    milestone.subSteps.indexOf(currentStatus) + 1,
                  )
                : [];

            final bool isLastMilestone = idx == _kPipelineMilestones.length - 1;
            final bool milestoneHasBorder = !injectSubSteps && !isLastMilestone;

            final si             = _infoFor(milestone.status);
            final Color dotColor = si?.color ?? _T.blue;
            final Color bgColor  = si?.bg    ?? _T.blue50;

            return <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: isCurrent && !injectSubSteps ? bgColor : Colors.transparent,
                  border: milestoneHasBorder
                      ? const Border(bottom: BorderSide(color: _T.slate100))
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: isDone
                            ? _T.blue
                            : isCurrent && !injectSubSteps
                                ? dotColor
                                : _T.slate100,
                        shape: BoxShape.circle,
                        border: injectSubSteps && isCurrent
                            ? Border.all(color: dotColor.withOpacity(0.4), width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 11, color: Colors.white)
                            : isCurrent && !injectSubSteps
                                ? Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
                                : Container(
                                    width:  injectSubSteps ? 6 : 5,
                                    height: injectSubSteps ? 6 : 5,
                                    decoration: BoxDecoration(
                                      color: injectSubSteps
                                          ? dotColor.withOpacity(0.45)
                                          : _T.slate300,
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
                          color: isCurrent && !injectSubSteps
                              ? dotColor
                              : isDone || isCurrent
                                  ? _T.ink3
                                  : _T.slate400,
                        ),
                      ),
                    ),
                    if (isCurrent && !injectSubSteps)
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
              ...visibleSubSteps.asMap().entries.map((subEntry) {
                final subIdx    = subEntry.key;
                final s         = subEntry.value;
                final isCur     = s == currentStatus;
                final isPast    = !isCur;
                final isLastSub = subIdx == visibleSubSteps.length - 1;
                final isVeryLast = isLastSub && isLastMilestone;

                final rowSi       = _infoFor(s);
                final Color rowFg = isCur ? subFg : (rowSi?.color ?? _T.blue);

                return Container(
                  decoration: BoxDecoration(
                    color: isCur ? subBg : Colors.transparent,
                    border: Border(
                      top: BorderSide(
                        color: subIdx == 0 ? _T.slate200 : _T.slate100,
                      ),
                      bottom: isVeryLast
                          ? BorderSide.none
                          : isLastSub
                              ? const BorderSide(color: _T.slate100)
                              : BorderSide.none,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color:  isPast ? _T.blue : subFg,
                          shape:  BoxShape.circle,
                        ),
                        child: Center(
                          child: isPast
                              ? const Icon(Icons.check, size: 11, color: Colors.white)
                              : Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _subLabel(s),
                          style: TextStyle(
                            fontSize:   12.5,
                            fontWeight: isCur ? FontWeight.w700 : FontWeight.w500,
                            color:      isCur ? subFg : _T.ink3,
                          ),
                        ),
                      ),
                      if (isPast)
                        const Text('✓ Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _T.slate400)),
                      if (isCur)
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
                );
              }),
            ];
          }).toList(),
        ),
      ),
    );
  }
}