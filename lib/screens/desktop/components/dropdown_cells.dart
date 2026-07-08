// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY DROPDOWN CELL
//
// Replaces the old SelectionPill-based priority cell. Shows the current
// priority as a small colored pill; on hover a chevron appears on the far
// right of the cell. Tapping anywhere in the cell opens a dropdown menu
// (anchored under the cell) to change the priority.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/billing_status.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/providers/task_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const white = Colors.white;
  static const r = 6.0;

  // Priority colors (highest → lowest)
  static const priorityUrgent = Color(0xFFFF878A);
  static const priorityHigh = Color(0xFFFEA06A);
  static const priorityNormal = Color(0xFFF7BD51);
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY HELPERS
// ─────────────────────────────────────────────────────────────────────────────
Color _priorityColor(TaskPriority p) => switch (p) {
  TaskPriority.urgent => _T.priorityUrgent,
  TaskPriority.high => _T.priorityHigh,
  TaskPriority.normal => _T.priorityNormal,
  _ => _T.slate400,
};

String _priorityLabel(TaskPriority p) => switch (p) {
  TaskPriority.urgent => 'Urgent',
  TaskPriority.high => 'High',
  TaskPriority.normal => 'Normal',
  _ => p.name,
};

class PriorityDropdownCell extends ConsumerStatefulWidget {
  final Task task;
  final bool dimmed;

  const PriorityDropdownCell({required this.task, this.dimmed = false});

  @override
  ConsumerState<PriorityDropdownCell> createState() =>
      _PriorityDropdownCellState();
}

class _PriorityDropdownCellState extends ConsumerState<PriorityDropdownCell> {
  bool _hovering = false;
  final GlobalKey _anchorKey = GlobalKey();

  late TaskPriority priority;

  static const _options = [
    TaskPriority.urgent,
    TaskPriority.high,
    TaskPriority.normal,
  ];

  Future<void> _savePriorityStatus(TaskPriority newPriority) async {
    // setState(() {
    //   _billingSaving = true;
    // });

    try {
      await ref
          .read(taskNotifierProvider.notifier)
          .update(
            task: widget.task,
            billingStatus: null,
            ref: null,
            quantity: null,
            size: null,
            name: null,
            date: null,
            updatedPrintSpecs: null,
            newPrintSpec: null,
            deletePrintSpecId: null,
            priority: newPriority,
          );
      widget.task.priority = newPriority;
      setState(() {});
      // if (mounted) {
      //   setState(() => _billingEditMode = false);
      // }
    } finally {
      // if (mounted) setState(() => _billingSaving = false);
    }
  }

  Future<void> _openMenu() async {
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final topLeft = renderObject.localToGlobal(
      Offset(0, renderObject.size.height + 4),
      ancestor: overlay,
    );
    final bottomRight = renderObject.localToGlobal(
      Offset(renderObject.size.width + 8, renderObject.size.height + 4),
      ancestor: overlay,
    );

    final selected = await showMenu<TaskPriority>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        overlay.size.width - bottomRight.dx,
        0,
      ),
      color: _T.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_T.r),
        side: const BorderSide(color: _T.slate200),
      ),
      constraints: const BoxConstraints(minWidth: 140),
      items:
          _options.map((p) {
            final active = p == priority;
            final color = _priorityColor(p);
            return PopupMenuItem<TaskPriority>(
              value: p,
              height: 40,
              onTap: () {
                _savePriorityStatus(p);
              },
              child: Row(
                children: [
                  // Updated to mirror the main cell's color-dominant block appearance
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      _priorityLabel(p),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color:
                            Colors
                                .black54, // Matches cell's signature dark text contrast
                      ),
                    ),
                  ),
                  Spacer(),
                  // An alignment-preserving structural layout block for selection feedback
                  Opacity(
                    opacity: active ? 1.0 : 0.0,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: _T.blue,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );

    if (selected != null && selected != priority) {
      // NOTE: adjust this call to match your actual task-update API.
      // ref
      //     .read(taskNotifierProvider.notifier)
      //     .updateTaskPriority(widget.taskId, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    priority = widget.task.priority;

    final color = _priorityColor(priority);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        key: _anchorKey,
        behavior: HitTestBehavior.opaque,
        onTap: _openMenu,
        child: Opacity(
          opacity: widget.dimmed ? 0.45 : 1.0,
          child: Row(
            children: [
              SizedBox(width: kCellHPad / 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: color),
                ),
                child: Text(
                  _priorityLabel(priority),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
              Spacer(),
              if (_hovering)
                const Padding(
                  key: ValueKey('chevron'),
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: Colors.black54,
                  ),
                ),
              SizedBox(width: kCellHPad),
            ],
          ),
        ),
      ),
    );
  }

  @override
  initState() {
    super.initState();
    priority = widget.task.priority;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Billing DROPDOWN CELL
//
// Replaces the old SelectionPill-based priority cell. Shows the current
// priority as a small colored pill; on hover a chevron appears on the far
// right of the cell. Tapping anywhere in the cell opens a dropdown menu
// (anchored under the cell) to change the priority.
// ─────────────────────────────────────────────────────────────────────────────
class BillingDropdownCell extends ConsumerStatefulWidget {
  final Task task;
  final bool dimmed;

  const BillingDropdownCell({required this.task, this.dimmed = false});

  @override
  ConsumerState<BillingDropdownCell> createState() =>
      _BillingDropdownCellState();
}

class _BillingDropdownCellState extends ConsumerState<BillingDropdownCell> {
  bool _hovering = false;
  final GlobalKey _anchorKey = GlobalKey();

  static const _options = [
    BillingStatus.cancelled,
    BillingStatus.foc,
    BillingStatus.invoiced,
    BillingStatus.quoteGiven,
  ];

  late BillingStatus billing;

  Future<void> _saveBillingStatus(BillingStatus newStatus) async {
    // setState(() {
    //   _billingSaving = true;
    // });

    try {
      await ref
          .read(taskNotifierProvider.notifier)
          .update(
            task: widget.task,
            billingStatus: newStatus,
            ref: null,
            quantity: null,
            size: null,
            name: null,
            date: null,
            updatedPrintSpecs: null,
            newPrintSpec: null,
            deletePrintSpecId: null,
            priority: null,
          );
      widget.task.billingStatus = newStatus;
      setState(() {});
      // if (mounted) {
      //   setState(() => _billingEditMode = false);
      // }
    } finally {
      // if (mounted) setState(() => _billingSaving = false);
    }
  }

  Future<void> _openMenu() async {
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final topLeft = renderObject.localToGlobal(
      Offset(0, renderObject.size.height + 4),
      ancestor: overlay,
    );
    final bottomRight = renderObject.localToGlobal(
      Offset(renderObject.size.width + 8, renderObject.size.height + 4),
      ancestor: overlay,
    );

    final selected = await showMenu<BillingStatus>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        overlay.size.width - bottomRight.dx,
        0,
      ),
      color: _T.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_T.r),
        side: const BorderSide(color: _T.slate200),
      ),
      constraints: const BoxConstraints(minWidth: 140),
      items: [
        PopupMenuItem<BillingStatus>(
          value: BillingStatus.pending,
          height: 40,
          child: Row(
            children: [
              SizedBox(width: 5),
              const Text(
                '—',
                style: TextStyle(fontSize: 15, color: _T.slate300),
              ),
              // Updated to mirror the main cell's color-dominant block appearance
              Spacer(),
              // An alignment-preserving structural layout block for selection feedback
              Opacity(
                opacity: billing == BillingStatus.pending ? 1.0 : 0.0,
                child: const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Icon(Icons.check_rounded, size: 15, color: _T.blue),
                ),
              ),
            ],
          ),
        ),
        ..._options.map((b) {
          final active = b == billing;
          final color = b.color;
          return PopupMenuItem<BillingStatus>(
            value: b,
            height: 40,
            onTap: () {
              _saveBillingStatus(b);
            },
            child: Row(
              children: [
                // Updated to mirror the main cell's color-dominant block appearance
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    b.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color:
                          Colors
                              .black54, // Matches cell's signature dark text contrast
                    ),
                  ),
                ),
                Spacer(),
                // An alignment-preserving structural layout block for selection feedback
                Opacity(
                  opacity: active ? 1.0 : 0.0,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Icon(Icons.check_rounded, size: 15, color: _T.blue),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );

    if (selected != null && selected != billing) {
      // NOTE: adjust this call to match your actual task-update API.
      // ref
      //     .read(taskNotifierProvider.notifier)
      //     .updateTaskPriority(widget.taskId, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = billing.color;

    billing = widget.task.billingStatus;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        key: _anchorKey,
        behavior: HitTestBehavior.opaque,
        onTap: _openMenu,
        child: Opacity(
          opacity: widget.dimmed ? 0.45 : 1.0,
          child: Row(
            children: [
              SizedBox(width: kCellHPad / 2),
              if (billing == BillingStatus.pending)
                const Text(
                  '—',
                  style: TextStyle(fontSize: 12, color: _T.slate300),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    billing.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: billing.textColor,
                    ),
                  ),
                ),
              Spacer(),
              if (_hovering)
                Padding(
                  key: ValueKey('chevron'),
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: billing.textColor,
                  ),
                ),
              SizedBox(width: kCellHPad),
            ],
          ),
        ),
      ),
    );
  }

  @override
  initState() {
    super.initState();
    billing = widget.task.billingStatus;
  }
}
