import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/project.dart';

// class ProjectFinishRate {
//   void calculateOverallFinishRate(List<Project> projects) {
//     for (Project project in projects) {
//       for (ProgressLog log in project.progressLogs) {
//         double progress;
//         if (log.dueDate != null) {
//           Duration totalDuration = log.dueDate!.difference(log.startDate);

//           Duration elapsed = DateTime.now().difference(log.startDate);

//           progress =
//               (elapsed.inSeconds / totalDuration.inSeconds)
//                   .clamp(0, 1)
//                   .toDouble();
//         } else {
//           progress = 0;
//         }
//       }
//     }
//   }
// }
