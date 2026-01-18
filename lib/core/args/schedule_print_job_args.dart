import 'package:smooflow/core/models/task.dart';

class SchedulePrintJobArgs {
  final String? projectId;

  SchedulePrintJobArgs({this.projectId}) {
    isDetails = false;
  }

  late final Task task;

  late final bool isDetails;

  SchedulePrintJobArgs.details({this.projectId, required this.task}) {
    isDetails = true;
  }
}