import 'package:flutter/widgets.dart';

@deprecated
class CreateTaskScreenArgs {
  final String projectId;
  const CreateTaskScreenArgs({Key? key, required this.projectId});
}

class CreateTaskArgs {
  final String? preselectedProjectId;
  @Deprecated("Will be removed soon. Reason: the older design create task screen which required this input is no longer in use")
  final Function(
    String taskName,
    String projectId,
    String? notes,
    bool autoProgress,
    String? priority,
  )? onCreateTask;

  const CreateTaskArgs({
    this.preselectedProjectId,
    this.onCreateTask,
  });
}