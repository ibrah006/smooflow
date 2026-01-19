import 'package:flutter/widgets.dart';

@deprecated
class CreateTaskScreenArgs {
  final String projectId;
  const CreateTaskScreenArgs({Key? key, required this.projectId});
}

class CreateTaskArgs {
  final String? preselectedProjectId;
  final Function(
    String taskName,
    String projectId,
    String? notes,
    bool autoProgress,
    String? priority,
  ) onCreateTask;

  const CreateTaskArgs({
    this.preselectedProjectId,
    required this.onCreateTask,
  });
}