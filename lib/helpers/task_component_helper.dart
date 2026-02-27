// ─────────────────────────────────────────────────────────────────────────────
// TaskComponentHelper — factory mapping every TaskStatus to display metadata.
//
// Color palette is drawn exclusively from the shared _T design tokens:
//
//   Workflow phase   → Color
//   ─────────────────────────────────────────────────────
//   Pending / queued → _T.amber      (0xFFF59E0B)
//   Active work      → _T.blue       (0xFF3B82F6)
//   Waiting / review → _T.purple     (0xFF8B5CF6)
//   Approved / done  → _T.green      (0xFF22C55E)  [using emerald shade below]
//   Blocked          → _T.red        (0xFFEF4444)
//   Paused           → _T.slate500   (0xFF64748B)
//   Revision         → _T.amber      (0xFFF59E0B)
// ─────────────────────────────────────────────────────────────────────────────

// ── Design tokens (must match your shared _T class) ──────────────────────────
// Reproduced inline so this file is self-contained; delete if you import _T.
import 'package:flutter/material.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';

abstract class _T {
  static const Color amber   = Color(0xFFF59E0B);
  static const Color blue    = Color(0xFF3B82F6);
  static const Color purple  = Color(0xFF8B5CF6);
  static const Color green   = Color(0xFF22C55E);
  static const Color emerald = Color(0xFF10B981); // approved / fully complete
  static const Color red     = Color(0xFFEF4444);
  static const Color slate500 = Color(0xFF64748B);
}

// ── Helper model ──────────────────────────────────────────────────────────────
class TaskComponentHelper {
  final TaskStatus status;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime? startTime;
  final DateTime? endTime;

  const TaskComponentHelper(
    this.status,
    this.label,
    this.subtitle,
    this.icon,
    this.color,
    this.startTime,
    this.endTime,
  );

  // ── Factory ────────────────────────────────────────────────────────────────
  factory TaskComponentHelper.get(Task task) {
    switch (task.status) {

      // ── Design phase ───────────────────────────────────────────────────────

      case TaskStatus.pending:
        return TaskComponentHelper(
          TaskStatus.pending,
          'Pending',
          'Waiting to be picked up',
          Icons.schedule_rounded,
          _T.amber,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.designing:
        return TaskComponentHelper(
          TaskStatus.designing,
          'Designing',
          'Design work is in progress',
          Icons.design_services_rounded,
          _T.blue,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.waitingApproval:
        return TaskComponentHelper(
          TaskStatus.waitingApproval,
          'Waiting Approval',
          'Submitted — pending client review',
          Icons.mark_email_unread_rounded,
          _T.purple,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.clientApproved:
        return TaskComponentHelper(
          TaskStatus.clientApproved,
          'Client Approved',
          'Design signed off — ready for production',
          Icons.verified_rounded,
          _T.emerald,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.revision:
        return TaskComponentHelper(
          TaskStatus.revision,
          'Needs Revision',
          'Client requested changes',
          Icons.edit_note_rounded,
          _T.amber,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      // ── Production phase ───────────────────────────────────────────────────

      case TaskStatus.waitingPrinting:
        return TaskComponentHelper(
          TaskStatus.waitingPrinting,
          'Waiting for Printing',
          'Queued — awaiting printer availability',
          Icons.hourglass_top_rounded,
          _T.amber,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.printing:
        return TaskComponentHelper(
          TaskStatus.printing,
          'Printing',
          'Print job is running',
          Icons.print_rounded,
          _T.blue,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.printingCompleted:
        return TaskComponentHelper(
          TaskStatus.printingCompleted,
          'Printing Complete',
          'Print finished — moving to finishing',
          Icons.print_disabled_rounded, // "done printing" feel
          _T.green,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.finishing:
        return TaskComponentHelper(
          TaskStatus.finishing,
          'Finishing',
          'Post-print finishing in progress',
          Icons.auto_fix_high_rounded,
          _T.blue,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.productionCompleted:
        return TaskComponentHelper(
          TaskStatus.productionCompleted,
          'Production Complete',
          'All production steps done',
          Icons.inventory_2_rounded,
          _T.emerald,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      // ── Delivery phase ─────────────────────────────────────────────────────

      case TaskStatus.waitingDelivery:
        return TaskComponentHelper(
          TaskStatus.waitingDelivery,
          'Waiting for Delivery',
          'Ready — awaiting dispatch',
          Icons.inventory_rounded,
          _T.amber,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.delivery:
        return TaskComponentHelper(
          TaskStatus.delivery,
          'Out for Delivery',
          'Item is on its way to the client',
          Icons.local_shipping_rounded,
          _T.blue,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.delivered:
        return TaskComponentHelper(
          TaskStatus.delivered,
          'Delivered',
          'Item received by the client',
          Icons.move_to_inbox_rounded,
          _T.emerald,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      // ── Installation phase ─────────────────────────────────────────────────

      case TaskStatus.waitingInstallation:
        return TaskComponentHelper(
          TaskStatus.waitingInstallation,
          'Waiting for Installation',
          'Delivered — awaiting install slot',
          Icons.pending_actions_rounded,
          _T.amber,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.installing:
        return TaskComponentHelper(
          TaskStatus.installing,
          'Installing',
          'Installation is underway on-site',
          Icons.construction_rounded,
          _T.blue,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.completed:
        return TaskComponentHelper(
          TaskStatus.completed,
          'Completed',
          'Installation complete — task closed',
          Icons.check_circle_rounded,
          _T.emerald,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      // ── Cross-cutting states ───────────────────────────────────────────────

      case TaskStatus.blocked:
        return TaskComponentHelper(
          TaskStatus.blocked,
          'Blocked',
          'Task cannot proceed — action needed',
          Icons.block_rounded,
          _T.red,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );

      case TaskStatus.paused:
        return TaskComponentHelper(
          TaskStatus.paused,
          'Paused',
          'Task is on hold',
          Icons.pause_circle_rounded,
          _T.slate500,
          task.actualProductionStartTime,
          task.actualProductionEndTime,
        );
    }
    // Dart exhaustiveness ensures no default is needed — all cases covered.
  }
}