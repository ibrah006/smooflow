import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/progress_log_provider.dart';

class TaskScreen extends ConsumerWidget {
  final Task task;
  const TaskScreen(this.task, {super.key});

  @override
  Widget build(BuildContext context, ref) {
    final textTheme = Theme.of(context).textTheme;

    final progressLog = ref
        .watch(progressLogsByProjectProviderSimple(task.projectId))
        .firstWhere((log) => log.id == task.progressLogId);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(task.name),
        actions: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            decoration: BoxDecoration(
              color: colorPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              task.status,
              style: textTheme.labelMedium!.copyWith(color: colorPrimary),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15),
            Row(
              spacing: 7,
              children: [
                Icon(Icons.description_outlined),
                Text(
                  "Description",
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (task.description.trim().isNotEmpty)
              SizedBox(
                width: MediaQuery.of(context).size.width / 3,
                child: Text(
                  task.description,
                  style: textTheme.bodyMedium!.copyWith(
                    color: Colors.grey.shade900,
                  ),
                  maxLines: 2,
                ),
              )
            else
              Text(
                "No description",
                style: textTheme.bodyMedium!.copyWith(
                  color: Colors.grey.shade900,
                ),
              ),
            SizedBox(height: 30),
            Row(
              spacing: 7,
              children: [
                Icon(Icons.people_outline_rounded),
                Text(
                  "Assignees",
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (task.assignees.isNotEmpty)
              ...task.assignees.map((assignee) {
                return Row(
                  children: [
                    Icon(Icons.account_circle_rounded, size: 30),
                    SizedBox(width: 7),
                    Text(assignee.name, style: textTheme.titleMedium),
                  ],
                );
              })
            else
              Text(
                "None assigned",
                style: textTheme.bodyMedium!.copyWith(
                  color: Colors.grey.shade900,
                ),
              ),
            SizedBox(height: 30),
            // Progress phase & Priority
            Row(
              children: [
                // Progress phase
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 7,
                        children: [
                          Icon(Icons.timeline_rounded),
                          Text(
                            "Progress Phase",
                            style: textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "${progressLog.status.name[0].toUpperCase()}${progressLog.status.name.substring(1)}",
                        style: textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                // Priority
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 7,
                        children: [
                          Icon(Icons.priority_high_outlined),
                          Text(
                            "Priority",
                            style: textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text("none", style: textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            Row(
              spacing: 7,
              children: [
                Stack(
                  children: [
                    Icon(Icons.person_outline_rounded),
                    Container(
                      margin: const EdgeInsets.only(top: 12.0, left: 12),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(Icons.access_time_filled, size: 14),
                    ),
                  ],
                ),
                Text(
                  "Logs",
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  SizedBox(height: 20),
                  Row(
                    spacing: 15,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colorPrimary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person_rounded,
                          color: colorPrimary,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Yusuf", style: textTheme.titleMedium),
                            Row(
                              spacing: 15,
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: 0.4,
                                    borderRadius: BorderRadius.circular(10),
                                    backgroundColor: colorPrimary.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                                Text("1h 10m", style: textTheme.titleMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              padding: EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 20,
              ).copyWith(bottom: 20),
              child: Row(
                spacing: 11,
                children: [
                  if (task.dateCompleted == null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.all(10),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.25,
                          ),
                        ),
                        child: Text("Add Log"),
                      ),
                    ),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: Colors.grey.shade200,
                        padding: EdgeInsets.all(10),
                        textStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: task.dateCompleted == null ? () {} : null,
                      child: Text("Start"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startTask() {}
}
