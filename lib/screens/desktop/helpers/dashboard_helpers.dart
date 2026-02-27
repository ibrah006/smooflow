
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

DesignStageInfo stageInfo(TaskStatus s) {
  // try {
  // return [...kStages, DesignStageInfo(TaskStatus.delivery,  'Delivery',   'Delivery', Color(0xFF2563EB), Color(0xFFDBEAFE))].firstWhere((i) => i.stage == s);
  // } catch(e) {
  //   throw "culprit found, status: $s, kstages ln: ${kStages.length}";
  // }
  return kStages.firstWhere((i) => i.stage == s);
}
int stageIndex(TaskStatus s) => kStages.indexWhere((i) => i.stage == s);
String fmtDate(DateTime d) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}