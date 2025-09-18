import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/add_project_progress_screen.dart';

class ProjectTimelineScreen extends ConsumerWidget {
  final String projectId;

  const ProjectTimelineScreen({Key? key, required this.projectId})
    : super(key: key);

  static final unProgressColor = Colors.grey.shade300;

  Widget _buildStep(
    context, {
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isHead = false,
    bool isTail = false,
    bool showError = false,
    String? errorText,
    double progress = 0,
    // is current progress/status
    bool isCurrent = false,
  }) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(left: 12),
          height: 90,
          width: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: isHead ? Radius.circular(10) : Radius.zero,
              bottom: isTail ? Radius.circular(10) : Radius.zero,
            ),
            color:
                showError
                    ? colorError
                    : isCurrent
                    ? unProgressColor
                    : colorPrimary,
          ),
        ),
        Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color:
                    isCurrent
                        ? Theme.of(context).scaffoldBackgroundColor
                        : (showError ? colorError : colorPrimary),
                shape: BoxShape.circle,
                border:
                    isCurrent
                        ? Border.all(color: unProgressColor, width: 3)
                        : null,
              ),
              child:
                  isCurrent
                      ? null
                      : Icon(
                        showError ? Icons.priority_high_rounded : Icons.check,
                        color: Colors.white,
                      ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    errorText ?? subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: showError ? Colors.red : Colors.grey.shade700,
                      fontWeight: showError ? FontWeight.w500 : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: unProgressColor,
                    color: showError ? Colors.red : colorPrimary,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, ref) {
    final textTheme = Theme.of(context).textTheme;

    late final Project project;

    try {
      project = ref.watch(projectByIdProvider(projectId))!;
    } catch (e) {
      // Project not found
      return Scaffold(body: Center(child: Text("Project not found: E70")));
    }

    final progressLogs =
        ref
            .watch(projectNotifierProvider)
            .firstWhere((p) => p.id == project.id)
            .progressLogs;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          children: [
            Text(project.name),
            Text("Project timeline progression", style: textTheme.bodyMedium),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 10,
              children: [
                Icon(Icons.info_outline_rounded),
                Expanded(
                  child: Text(
                    "Track your project’s progress and monitor critical milestones",
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // White card
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView(
                  children: [
                    SizedBox(height: 30),
                    ...List.generate(progressLogs.length, (index) {
                      final log = progressLogs[index];

                      double progress;
                      if (log.dueDate != null) {
                        Duration totalDuration = log.dueDate!.difference(
                          log.startDate,
                        );

                        Duration elapsed = DateTime.now().difference(
                          log.startDate,
                        );

                        progress =
                            (elapsed.inSeconds / totalDuration.inSeconds)
                                .clamp(0, 1)
                                .toDouble();
                      } else {
                        progress = 0;
                      }

                      return _buildStep(
                        context,
                        isHead: index == 0,
                        isTail: index == progressLogs.length - 1,
                        isCompleted: progress >= 1,
                        isCurrent:
                            progress <= 1 || (index < progressLogs.length),
                        title:
                            "${log.status.name[0].toUpperCase()}${log.status.name.substring(1)}",
                        subtitle:
                            log.dueDate?.formatDisplay.toString() as String,
                        showError: log.hasIssues,
                        errorText: log.hasIssues ? log.issue?.name : null,
                        progress: progress,
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // View Project Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddProjectProgressScreen(project.id),
                    ),
                  );
                },
                child: const Text(
                  "Add Progress",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
