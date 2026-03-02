import 'package:flutter/material.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

class StagePill extends StatelessWidget {
  final DesignStageInfo stageInfo;
  const StagePill({required this.stageInfo});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(stageInfo.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stageInfo.color))
  );
}