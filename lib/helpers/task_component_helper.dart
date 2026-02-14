
import 'package:flutter/material.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/extensions/duration_format.dart';

class TaskComponentHelper {

  TaskStatus status;
  final Color color;
  final String labelTitle, labelSubTitle;
  IconData icon;
  DateTime? actualProductionStartTime;
  DateTime? actualProductionEndTime;

  // Calculate time display based on status
  String get timeDisplay => actualProductionStartTime != null && actualProductionEndTime != null?
    // If production has ended, show total duration
    actualProductionEndTime?.difference(actualProductionStartTime!).formatTime?? 'Just finished'
    // If production has started but not ended, show how long it's been running
    : actualProductionStartTime != null? actualProductionStartTime!.eventAgo
    : 'Not Started';

  TaskComponentHelper(this.status, this.labelTitle, this.labelSubTitle, this.icon, this.color, this.actualProductionStartTime, this.actualProductionEndTime);

  factory TaskComponentHelper.get(Task task) {
    switch (task.status) {
      case TaskStatus.pending:
        return TaskComponentHelper(
          TaskStatus.pending,
          'Pending',
          'Start working on this task',
          Icons.play_circle_rounded,
          const Color(0xFFF59E0B),
          task.actualProductionStartTime,
          task.actualProductionEndTime
        );
      case TaskStatus.designing || TaskStatus.printing || TaskStatus.finishing || TaskStatus.installing || TaskStatus.delivery:
        return TaskComponentHelper(
          task.status,
          "${task.status.name[0].toUpperCase()}${task.status.name.substring(1)}",
          'Task is in designing stage',
          Icons.design_services_rounded,
          const Color(0xFF3B82F6),
          task.actualProductionStartTime,
          task.actualProductionEndTime
        );
      case TaskStatus.waitingApproval:
        return TaskComponentHelper(
          TaskStatus.waitingApproval,
          'Pending Approval',
          'Submit for client review',
          Icons.send_rounded,
          const Color(0xFF8B5CF6),
          task.actualProductionStartTime,
          task.actualProductionEndTime
        );
      case TaskStatus.clientApproved:
        return TaskComponentHelper(
          TaskStatus.clientApproved,
          'Client Approved',
          'Mark as complete and approved',
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
          task.actualProductionStartTime,
          task.actualProductionEndTime
        );
      case TaskStatus.revision:
        return TaskComponentHelper(
          TaskStatus.revision,
          'Needs Revision',
          'Make necessary changes',
          Icons.edit_rounded,
          const Color(0xFFF59E0B,),
          task.actualProductionStartTime,
          task.actualProductionEndTime
        );
      case TaskStatus.blocked:
        return TaskComponentHelper(
          TaskStatus.blocked,
          'Blocked',
          'Task is currently blocked',
          Icons.block_rounded,
          const Color(0xFFEF4444),
          task.actualProductionStartTime,
          task.actualProductionEndTime
        );
      case TaskStatus.paused:
        return TaskComponentHelper(
          TaskStatus.paused,
          'Paused',
          'Task is currently paused',
          Icons.pause_circle_rounded,
          const Color(0xFF64748B),
          task.actualProductionStartTime,
          task.actualProductionEndTime
        );
      case TaskStatus.completed:
        return TaskComponentHelper(
          TaskStatus.completed,
          'Completed',
          'Task is complete',
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
          task.actualProductionStartTime,
          task.actualProductionEndTime
        );
    }
  }
}