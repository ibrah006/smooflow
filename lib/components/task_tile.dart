import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/project_provider.dart';

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
    print(widget.task.status);
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
          child: Container(
            margin: EdgeInsets.only(right: 20, left: 10),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Text(
                          widget.task.description.isEmpty
                              ? "Pending completion"
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
                Container(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Pending",
                    style: textTheme.labelMedium!.copyWith(color: colorPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
