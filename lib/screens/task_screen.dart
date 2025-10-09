import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/components/work_activity_tile.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/models/user.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/providers/progress_log_provider.dart';
import 'package:smooflow/providers/user_provider.dart';
import 'package:smooflow/providers/work_activity_log_providers.dart';

class TaskScreen extends ConsumerStatefulWidget {
  final Task task;
  const TaskScreen(this.task, {super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  late Future<ProgressLog> progressLogFuture;

  /// This Task's work-activity-logs
  late final Future<List<WorkActivityLog>> workActivityLogsFuture;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      progressLogFuture = ref
          .watch(
            progressLogsByProjectProvider(
              ProgressLogsByProviderArgs(widget.task.projectId),
            ),
          )
          .then((progressLogs) {
            print("progressLogs ln: ${progressLogs.length}");
            return progressLogs.isNotEmpty
                ? progressLogs.firstWhere(
                  (log) => log.id == widget.task.progressLogId,
                )
                : ProgressLog.deleted(widget.task.progressLogId);
          });

      workActivityLogsFuture = ref.watch(
        workActivityLogsByTaskProvider(widget.task.id),
      );

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    late final bool showLoadingOverlay;
    try {
      progressLogFuture;
      workActivityLogsFuture;
      showLoadingOverlay = false;
    } catch (e) {
      showLoadingOverlay = true;
    }

    bool showPageContents = !showLoadingOverlay;

    final isCompleted =
        widget.task.dateCompleted != null ||
        widget.task.status.toLowerCase() == "completed";

    final assigneesFuture = ref
        .watch(userNotifierProvider.notifier)
        .getTaskUsers(task: widget.task);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(widget.task.name),
        actions: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            decoration: BoxDecoration(
              color: colorPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              widget.task.status,
              style: textTheme.labelMedium!.copyWith(color: colorPrimary),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: LoadingOverlay(
        isLoading: showLoadingOverlay,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child:
              showPageContents
                  ? Column(
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
                      if (widget.task.description.trim().isNotEmpty)
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 1.35,
                          child: Text(
                            widget.task.description,
                            style: textTheme.bodyMedium!.copyWith(
                              color: Colors.grey.shade900,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                      if (widget.task.assignees.isNotEmpty)
                        FutureBuilder(
                          future: assigneesFuture,
                          builder: (context, snapshot) {
                            final assignees = snapshot.data;

                            if (assignees == null) {
                              return CardLoading(
                                height: 25,
                                width: MediaQuery.of(context).size.width / 2.5,
                                borderRadius: BorderRadius.circular(20),
                              );
                            }

                            return Column(
                              children:
                                  assignees.map((assignee) {
                                    return Row(
                                      children: [
                                        Icon(
                                          Icons.account_circle_rounded,
                                          size: 30,
                                        ),
                                        SizedBox(width: 7),
                                        Text(
                                          "${assignee.name[0].toUpperCase()}${assignee.name.substring(1)}",
                                          style: textTheme.titleMedium,
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            );
                          },
                        )
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
                                FutureBuilder(
                                  future: progressLogFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.data == null) {
                                      return CircularProgressIndicator();
                                    }
                                    final status = snapshot.data!.status.name;

                                    return Text(
                                      !snapshot.data!.isDeleted
                                          ? "${status[0].toUpperCase()}${status.substring(1)}"
                                          :
                                          // Deleted progress log
                                          "Deleted Progress Log",
                                      style: textTheme.titleMedium,
                                    );
                                  },
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
                                margin: const EdgeInsets.only(
                                  top: 12.0,
                                  left: 12,
                                ),

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
                        child: FutureBuilder(
                          future: workActivityLogsFuture,
                          builder: (context, snapshot) {
                            final workActivityLogs = snapshot.data;

                            if (workActivityLogs != null) {
                              final totalLogDurationSeconds = ref
                                  .read(
                                    workActivityLogNotifierProvider.notifier,
                                  )
                                  .getTotalLogDurationSeconds(widget.task.id);

                              return workActivityLogs.isNotEmpty
                                  ? ListView(
                                    children: [
                                      SizedBox(height: 20),
                                      ...workActivityLogs.map((log) {
                                        return WorkActivityTile(
                                          log,
                                          totalTaskContributionSeconds:
                                              totalLogDurationSeconds,
                                        );
                                      }),
                                    ],
                                  )
                                  :
                                  // No Activity logs message
                                  Center(
                                    child: SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width /
                                          1.75,
                                      child: Column(
                                        spacing: 15,
                                        children: [
                                          SizedBox(height: 10),
                                          SvgPicture.asset(
                                            "assets/icons/no_activity_logs.svg",
                                            width: 100,
                                          ),
                                          Text(
                                            "No activity logs recorded for this task yet",
                                            style: textTheme.titleLarge!
                                                .copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                disabledBackgroundColor:
                                                    Colors.grey.shade200,
                                                padding: EdgeInsets.all(10),
                                              ),
                                              onPressed:
                                                  widget.task.dateCompleted ==
                                                          null
                                                      ? startTask
                                                      : null,
                                              child: Text("Add Activity Log"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                            }
                            return LoadingOverlay(
                              isLoading: true,
                              child: SizedBox(),
                            );
                          },
                        ),
                      ),
                      FutureBuilder(
                        future: workActivityLogsFuture,
                        builder: (context, snapshot) {
                          final workActivityLog = snapshot.data;

                          if (workActivityLog != null &&
                              workActivityLog.isEmpty) {
                            return SizedBox();
                          }

                          return Container(
                            decoration: BoxDecoration(
                              border: Border.symmetric(
                                horizontal: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ).copyWith(bottom: 20),
                            child: Row(
                              spacing: 11,
                              children: [
                                if (!isCompleted)
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
                                      disabledBackgroundColor:
                                          Colors.grey.shade200,
                                      padding: EdgeInsets.all(10),
                                      textStyle: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: !isCompleted ? startTask : null,
                                    child: Text("Start"),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  )
                  : null,
        ),
      ),
    );
  }

  void startTask() async {
    // await ref.read(taskNotifierProvider.notifier).startTask(widget.task);
  }
}
