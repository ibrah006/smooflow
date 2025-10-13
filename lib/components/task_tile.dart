import 'package:card_loading/card_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/providers/user_provider.dart';
import 'package:smooflow/screens/task_screen.dart';

class TaskTile extends ConsumerStatefulWidget {
  final int taskId;

  const TaskTile(this.taskId, {super.key});

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile> {
  Task get task => ref.watch(taskByIdProvider(widget.taskId))!;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final isCompleted =
        task.dateCompleted != null || task.status.toLowerCase() == "completed";

    final assigneesFuture = ref
        .read(userNotifierProvider.notifier)
        .getTaskUsers(task: task);

    return Padding(
      // margin
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 10),
          RoundCheckBox(
            isChecked: task.status.toLowerCase() == "completed",
            animationDuration: Durations.medium1,
            size: 27,
            checkedColor: colorPrimary,
            onTap: (newVal) async {
              setState(() {
                if (newVal == true) {
                  task.status = "completed";
                }
              });

              await ref
                  .read(projectNotifierProvider.notifier)
                  // We're not really passing in the updated task for the backend to track the new state of the task
                  // As the endpoint that's to be called just has one function and only one end state
                  // We're just passing it for the called function to know about the projectId and taskId
                  .markTaskAsComplete(updatedTask: task);
            },
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 20, left: 10),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskScreen(task.id),
                    ),
                  );
                },
                splashColor: Colors.grey.withValues(alpha: 0.01),
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  padding: EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        spreadRadius: 1,
                        blurRadius: 7,
                        color: Colors.grey.shade100,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 5,
                          children: [
                            Text(
                              task.name,
                              style: textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: textTheme.titleLarge!.fontSize! - 2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Text(
                                task.description.isEmpty
                                    ? (!isCompleted
                                        ? "Pending completion"
                                        : "Finished ${task.dateCompleted.formatDisplay ?? 'N/a'}")
                                    : task.description,
                                style: textTheme.bodyMedium!.copyWith(
                                  color: Colors.grey.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 8,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  !isCompleted
                                      ? colorPrimary.withValues(alpha: 0.08)
                                      : colorPrimary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${task.status[0].toUpperCase()}${task.status.substring(1)}",
                              style: textTheme.labelMedium!.copyWith(
                                color:
                                    !isCompleted ? colorPrimary : Colors.white,
                              ),
                            ),
                          ),
                          if (task.assignees.isEmpty)
                            Icon(Icons.no_accounts_rounded, size: 20)
                          else
                            FutureBuilder(
                              future: assigneesFuture,
                              builder: (context, snapshot) {
                                final assignees = snapshot.data;
                                if (assignees == null) {
                                  return Row(
                                    spacing: 5,
                                    children: [
                                      CardLoading(
                                        height: 20,
                                        width: 20,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      CardLoading(
                                        height: 20,
                                        width: 60,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black,
                                            Colors.black54,
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      "${assignees.first.name[0].toUpperCase()}${assignees.first.name.substring(1)}",
                                      style: textTheme.labelSmall,
                                    ),
                                    if (task.assignees.length > 1)
                                      Text(
                                        ", ${task.assignees.length - 1} more",
                                        style: textTheme.labelSmall,
                                      ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
