import 'package:flutter/material.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

class StagePill extends StatelessWidget {
  final DesignStageInfo stageInfo;
  const StagePill({required this.stageInfo});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Wrap(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: stageInfo.bg, borderRadius: BorderRadius.circular(99)),
          child: Text(stageInfo.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stageInfo.color)),
        ),
      ],
    ),
  );
}