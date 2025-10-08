import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/task_screen.dart';

class TaskTile extends ConsumerStatefulWidget {
  final Task task;

  const TaskTile(this.task, {super.key});

  @override
  ConsumerState<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<TaskTile> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    print("task status: ${widget.task.status.toLowerCase() == "completed"}");

    final isCompleted =
        widget.task.dateCompleted != null ||
        widget.task.status.toLowerCase() == "completed";

    return Row(
      children: [
        SizedBox(width: 10),
        RoundCheckBox(
          isChecked: widget.task.status.toLowerCase() == "completed",
          animationDuration: Durations.medium1,
          size: 27,
          checkedColor: colorPrimary,
          onTap: (newVal) async {
            setState(() {
              print("status: $newVal");
              if (newVal == true) {
                widget.task.status = "completed";
              }
            });

            await ref
                .read(projectNotifierProvider.notifier)
                // We're not really passing in the updated task for the backend to track the new state of the task
                // As the endpoint that's to be called just has one function and only one end state
                // We're just passing it for the called function to know about the projectId and taskId
                .markTaskAsComplete(updatedTask: widget.task);
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
                    builder: (context) => TaskScreen(widget.task),
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
                            widget.task.name,
                            style: textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: textTheme.titleLarge!.fontSize! - 2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              widget.task.description.isEmpty
                                  ? (!isCompleted
                                      ? "Pending completion"
                                      : "Finished ${widget.task.dateCompleted.formatDisplay ?? 'N/a'}")
                                  : widget.task.description,
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
                            "${widget.task.status[0].toUpperCase()}${widget.task.status.substring(1)}",
                            style: textTheme.labelMedium!.copyWith(
                              color: !isCompleted ? colorPrimary : Colors.white,
                            ),
                          ),
                        ),
                        if (widget.task.assignees.isEmpty)
                          Icon(Icons.no_accounts_rounded, size: 20)
                        else
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  gradient: LinearGradient(
                                    colors: [Colors.black, Colors.black54],
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
                                widget.task.assignees.first.name,
                                style: textTheme.labelSmall,
                              ),
                              if (widget.task.assignees.length > 1)
                                Text(
                                  ", ${widget.task.assignees.length} more assigned",
                                  style: textTheme.labelSmall,
                                ),
                            ],
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
    );
  }
}
