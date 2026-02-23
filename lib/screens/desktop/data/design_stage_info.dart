import 'package:flutter/rendering.dart';
import 'package:smooflow/enums/task_status.dart';

class DesignStageInfo {
  final TaskStatus stage;
  final String label;
  final String shortLabel;
  final Color color;
  final Color bg;
  const DesignStageInfo(this.stage, this.label, this.shortLabel, this.color, this.bg);
}