import 'dart:async';

import 'package:card_loading/card_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/components/native_button.dart';
import 'package:smooflow/components/work_activity_tile.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/main.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/providers/progress_log_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/providers/user_provider.dart';
import 'package:smooflow/providers/work_activity_log_providers.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/task_args.dart';

class TaskScreen extends ConsumerStatefulWidget {
  final int taskId;
  const TaskScreen(this.taskId, {super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> with RouteAware {
  late Future<ProgressLog> progressLogFuture;

  /// This Task's work-activity-logs
  late Future<List<WorkActivityLog>> workActivityLogsFuture;

  bool isStartTaskLoading = false;

  bool _isLoading = false;

  Timer? _timer;

  // late EventNotifier<int>? activeLogDurationSecondsNotifier;

  late Task task; // => ref.watch(taskByIdProviderSimple(widget.taskId))!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;

    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Called when this screen is closed
  @override
  void didPop() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.didPop();
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      task = (await ref.watch(taskByIdProvider(widget.taskId)))!;

      // progressLogFuture = ref
      //     .watch(
      //       progressLogsByProjectProvider(
      //         ProgressLogsByProviderArgs(task.projectId),
      //       ),
      //     )
      //     .then((value) {
      //       return value.progressLogs.isNotEmpty
      //           ? value.progressLogs.firstWhere(
      //             (log) => log.id == task.progressLogId,
      //           )
      //           : ProgressLog.deleted(task.progressLogId);
      //     });

      // workActivityLogsFuture = ref.watch(
      //   workActivityLogsByTaskProvider(task.id),
      // );

      try {
        await startDurationEventHandler();
      } catch (e) {
        // no active work activity log
      }

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      task;
    } catch (e) {
      // Still loading up task
      return LoadingOverlay(isLoading: true, child: Scaffold());
    }

    final textTheme = Theme.of(context).textTheme;

    workActivityLogsFuture = ref.watch(workActivityLogsByTaskProvider(task.id));

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
        task.dateCompleted != null || task.status.toLowerCase() == "completed";

    final assigneesFuture = ref
        .watch(userNotifierProvider.notifier)
        .getTaskUsers(task: task);

    final Future<WorkActivityLog?> activeWorkActivityLogFuture =
        ref.watch(workActivityLogNotifierProvider.notifier).activeLog;

    final durationNotifier =
        ref
            .watch(workActivityLogNotifierProvider.notifier)
            .activeLogDurationNotifier;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(centerTitle: false, title: Text(task.name)),
        body: LoadingOverlay(
          isLoading: showLoadingOverlay,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child:
                showPageContents
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            task.status,
                            style: textTheme.labelMedium!.copyWith(
                              color: colorPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
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
                            width: MediaQuery.of(context).size.width / 1.35,
                            child: Text(
                              task.description,
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
                        if (task.assignees.isNotEmpty)
                          FutureBuilder(
                            future: assigneesFuture,
                            builder: (context, snapshot) {
                              final assignees = snapshot.data;

                              if (assignees == null) {
                                return CardLoading(
                                  height: 25,
                                  width:
                                      MediaQuery.of(context).size.width / 2.5,
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
                                  // FutureBuilder(
                                  //   future: progressLogFuture,
                                  //   builder: (context, snapshot) {
                                  //     if (snapshot.data == null) {
                                  //       return CircularProgressIndicator();
                                  //     }
                                  //     final status = snapshot.data!.status.name;

                                  //     return Text(
                                  //       !snapshot.data!.isDeleted
                                  //           ? "${status[0].toUpperCase()}${status.substring(1)}"
                                  //           :
                                  //           // Deleted progress log
                                  //           "Deleted Progress Log",
                                  //       style: textTheme.titleMedium,
                                  //     );
                                  //   },
                                  // ),
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
                                  child: Icon(
                                    Icons.access_time_filled,
                                    size: 14,
                                  ),
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
                                    .getTotalLogDurationSeconds(task.id);

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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 15,
                                          children: [
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
                                            // SizedBox(
                                            //   width: double.infinity,
                                            //   child: FilledButton(
                                            //     style: FilledButton.styleFrom(
                                            //       disabledBackgroundColor:
                                            //           Colors.grey.shade200,
                                            //       padding: EdgeInsets.all(10),
                                            //     ),
                                            //     onPressed:
                                            //         !isCompleted
                                            //             ? openBottomSheet
                                            //             : null,
                                            //     child: Text("Add Activity Log"),
                                            //   ),
                                            // ),
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
                        Container(
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
                          child: FutureBuilder(
                            future: activeWorkActivityLogFuture,
                            builder: (context, snapshot) {
                              final WorkActivityLog? activeWorkActivityLog =
                                  snapshot.data;

                              return Row(
                                spacing: 11,
                                children: [
                                  if (activeWorkActivityLog == null &&
                                      !isCompleted)
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
                                  if (activeWorkActivityLog != null)
                                    Expanded(
                                      child: NativeButton(
                                        onPressed: () {
                                          if (activeWorkActivityLog.taskId !=
                                              task.id) {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.task,
                                              arguments: TaskArgs(
                                                  activeWorkActivityLog.taskId!),
                                            );
                                          }
                                        },
                                        trailingAction: FilledButton(
                                          onPressed: stopTask,
                                          style: FilledButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: Text(
                                            "Stop",
                                            style: textTheme.titleMedium!
                                                .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                          ),
                                        ),

                                        child: Row(
                                          spacing: 10,
                                          children: [
                                            Icon(
                                              Icons.account_circle_rounded,
                                              size: 24,
                                              color: Colors.grey.shade700,
                                            ),
                                            Expanded(
                                              child: Text(
                                                "You",
                                                style: textTheme.titleMedium,
                                                overflow: TextOverflow.fade,
                                                maxLines: 2,
                                              ),
                                            ),
                                            if (durationNotifier != null)
                                              StreamBuilder<int>(
                                                stream: durationNotifier.stream,
                                                builder: (context, snapshot) {
                                                  final seconds =
                                                      snapshot.data ?? 0;
                                                  return Text(
                                                    activeActivityLogDuration(
                                                      seconds,
                                                    ),
                                                    style: textTheme.titleLarge!
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  );
                                                },
                                              ),
                                            Spacer(),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          disabledBackgroundColor:
                                              Colors.grey.shade100,
                                          padding: EdgeInsets.all(10),
                                          textStyle: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          iconSize: 24,
                                        ),
                                        onPressed:
                                            !isCompleted
                                                ? (isStartTaskLoading
                                                    ? null
                                                    : startTask)
                                                : null,
                                        child: Stack(
                                          children: [
                                            if (isStartTaskLoading)
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 3,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade400,
                                                      ),
                                                ),
                                              ),
                                            Align(
                                              alignment: Alignment.center,
                                              child: Text("Start"),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    )
                    : null,
          ),
        ),
      ),
    );
  }

  /// start the active work-activity-log duration event handler
  Future<void> startDurationEventHandler() async {
    WorkActivityLog? activeWorkActivityLog =
        await ref.watch(workActivityLogNotifierProvider.notifier).activeLog;

    // work activity log ended
    if (_timer?.isActive == true && activeWorkActivityLog == null) {
      _timer!.cancel();
      _timer == null;
      return;
    }

    if (_timer?.isActive == true || activeWorkActivityLog == null) {
      // No active work-activity-log found || or already running timer for an active work activity log
      return;
    }

    // .activeLog (attrib) won't be null at this point because at this point we assume a work activity log is already active
    activeWorkActivityLog =
        (await ref.watch(workActivityLogNotifierProvider.notifier).activeLog)!;

    // Duration event handler
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      Future.delayed(Duration(seconds: 1)).then((value) {
        try {
          if (ref
                  .read(workActivityLogNotifierProvider.notifier)
                  .activeLogDurationNotifier ==
              null) {
            _timer!.cancel();
            _timer = null;

            return;
          }

          ref
              .read(workActivityLogNotifierProvider.notifier)
              .activeLogDurationNotifier!
              .sink
              .add(activeWorkActivityLog!.duration.inSeconds);
        } catch (e) {
          // already disposed / ended the work activity log
          // setState(() {});
          return;
        }
      });
    });
  }

  String activeActivityLogDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    return "${duration.inHours}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }

  void startTask() async {
    setState(() {
      isStartTaskLoading = true;
    });

    // await ref.watch(createTaskActivityLogProvider(task.id));
    // Update task status
    final workActivityLog = await ref
        .read(taskNotifierProvider.notifier)
        .startTask(task.id);

    // Add Work activity log
    await ref
        .read(workActivityLogNotifierProvider.notifier)
        .startWorkSession(taskId: task.id, newLogId: workActivityLog.id);

    startDurationEventHandler();

    setState(() {
      isStartTaskLoading = false;
    });
  }

  void stopTask() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    _timer!.cancel();
    _timer = null;

    // Update task status
    await ref.read(taskNotifierProvider.notifier).endActiveTask();

    await ref.read(workActivityLogNotifierProvider.notifier).endWorkSession();

    setState(() {
      _isLoading = false;
    });
  }
}
