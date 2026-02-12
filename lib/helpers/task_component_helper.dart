
import 'package:flutter/material.dart';
import 'package:smooflow/enums/task_status.dart';

class TaskComponentHelper {

  TaskStatus status;
  final Color color;
  final String labelTitle, labelSubTitle;
  IconData icon;

  TaskComponentHelper(this.status, this.labelTitle, this.labelSubTitle, this.icon, this.color);

  factory TaskComponentHelper.get(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return TaskComponentHelper(
          TaskStatus.pending,
          'Pending',
          'Start working on this task',
          Icons.play_circle_rounded,
          const Color(0xFFF59E0B),
        );
      case TaskStatus.designing || TaskStatus.printing || TaskStatus.finishing || TaskStatus.installing || TaskStatus.delivery:
        return TaskComponentHelper(
          status,
          "${status.name[0].toUpperCase()}${status.name.substring(1)}",
          'Task is in designing stage',
          Icons.design_services_rounded,
          const Color(0xFF3B82F6),
        );
      case TaskStatus.waitingApproval:
        return TaskComponentHelper(
          TaskStatus.waitingApproval,
          'Pending Approval',
          'Submit for client review',
          Icons.send_rounded,
          const Color(0xFF8B5CF6),
        );
      case TaskStatus.clientApproved:
        return TaskComponentHelper(
          TaskStatus.clientApproved,
          'Client Approved',
          'Mark as complete and approved',
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
        );
      case TaskStatus.revision:
        return TaskComponentHelper(
          TaskStatus.revision,
          'Needs Revision',
          'Make necessary changes',
          Icons.edit_rounded,
          const Color(0xFFF59E0B,),
        );
      case TaskStatus.blocked:
        return TaskComponentHelper(
          TaskStatus.blocked,
          'Blocked',
          'Task is currently blocked',
          Icons.block_rounded,
          const Color(0xFFEF4444),
        );
      case TaskStatus.paused:
        return TaskComponentHelper(
          TaskStatus.paused,
          'Paused',
          'Task is currently paused',
          Icons.pause_circle_rounded,
          const Color(0xFF64748B),
        );
      case TaskStatus.completed:
        return TaskComponentHelper(
          TaskStatus.completed,
          'Completed',
          'Task is complete',
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
        );
    }
  }
}