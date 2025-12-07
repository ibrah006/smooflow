import 'package:flutter/widgets.dart';
import 'package:smooflow/models/progress_log.dart';

class AddProjectProgressArgs {
  final String projectId;

  // Read mode means the user is viewing a project progress log with minimal write privileges (update description and or issue/error)
  late final bool isReadMode;

  final Key? key;

  AddProjectProgressArgs(this.projectId, {this.key}) {
    isReadMode = false;
  }

  late final ProgressLog progressLog;

  AddProjectProgressArgs.view({
    this.key,
    required this.progressLog,
    required this.projectId,
  }) {
    isReadMode = true;
  }
}
