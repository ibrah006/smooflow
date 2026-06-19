// ─────────────────────────────────────────────────────────────────────────────
// STAGE PIPELINE
// ─────────────────────────────────────────────────────────────────────────────
import 'package:smooflow/enums/task_status.dart';

class PipelineMilestone {
  final String label;
  final TaskStatus status;
  final List<TaskStatus> subSteps;
  const PipelineMilestone(this.label, this.status, this.subSteps);
}

const List<PipelineMilestone> kPipelineMilestones = [
  PipelineMilestone('Initialized', TaskStatus.pending, []),
  PipelineMilestone('Design', TaskStatus.designing, [
    TaskStatus.designing,
    TaskStatus.waitingApproval,
    TaskStatus.clientApproved,
    TaskStatus.revision,
  ]),
  PipelineMilestone('Production Dept.', TaskStatus.waitingPrinting, [
    TaskStatus.waitingPrinting,
    TaskStatus.printing,
    TaskStatus.printingCompleted,
  ]),
  PipelineMilestone('Finishing Dept.', TaskStatus.finishing, [
    TaskStatus.finishing,
    TaskStatus.productionCompleted,
  ]),
  PipelineMilestone('Delivery', TaskStatus.delivery, [
    TaskStatus.waitingDelivery,
    TaskStatus.delivery,
    TaskStatus.delivered,
  ]),
  PipelineMilestone('Installation', TaskStatus.installing, [
    TaskStatus.waitingInstallation,
    TaskStatus.installing,
  ]),
  PipelineMilestone('Completed', TaskStatus.completed, []),
];
