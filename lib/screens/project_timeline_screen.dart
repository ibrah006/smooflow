import 'package:card_loading/card_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/custom_button.dart';
import 'package:smooflow/data/timeline_refresh_manager.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/progress_log_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/add_project_progress_screen.dart';
import 'dart:io' show Platform;

class ProjectTimelineScreen extends ConsumerStatefulWidget {
  final String projectId;

  ProjectTimelineScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  ConsumerState<ProjectTimelineScreen> createState() =>
      _ProjectTimelineScreenState();
}

class _ProjectTimelineScreenState extends ConsumerState<ProjectTimelineScreen> {
  static final unProgressColor = Colors.grey.shade200;

  late List<ProgressLog> progressLogs;

  late TimelineRefreshManager refreshManager;

  _showModalSheet({
    required context,
    required Widget Function(BuildContext) builder,
  }) {
    return Platform.isAndroid
        ? showModalBottomSheet(context: context, builder: builder)
        : showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: builder,
        );
  }

  Widget _buildStep(
    context,
    progressLogsLength,
    index, {
    required ProgressLog log,
  }) {
    double progress;
    if (log.dueDate != null) {
      Duration totalDuration = log.dueDate!.difference(log.startDate);

      Duration elapsed = DateTime.now().difference(log.startDate);

      progress =
          (elapsed.inSeconds / totalDuration.inSeconds).clamp(0, 1).toDouble();
    } else {
      progress = 0;
    }

    bool isHead = index == 0;
    bool isTail = index == progressLogsLength - 1;
    bool isCurrent = progress <= 1 || (index < progressLogsLength);
    String title =
        "${log.status.name[0].toUpperCase()}${log.status.name.substring(1)}";
    String subtitle = "Due ${log.dueDate?.formatDisplay}";
    String? errorText = log.hasIssues ? log.issue?.name : null;

    print("isCompleted: ${log.isCompleted}, hasIssues: ${log.hasIssues}");

    // if it's the tail, then we set below = t
    final bool nextIsCompleted =
        isTail ? true : progressLogs[index + 1].isCompleted;
    final bool isPreviousCompleted =
        isHead ? true : progressLogs[index - 1].isCompleted;

    return Stack(
      children: [
        // Status vertical line
        Container(
          margin: EdgeInsets.only(left: 12),
          height: isTail ? 20 : 85,
          width: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: isHead ? Radius.circular(10) : Radius.zero,
              bottom: isTail ? Radius.circular(10) : Radius.zero,
            ),
            color: unProgressColor,
            gradient:
                log.isCompleted
                    ? LinearGradient(
                      colors: [
                        ...!isPreviousCompleted ? [unProgressColor] : [],
                        colorPrimary,
                        nextIsCompleted ? colorPrimary : unProgressColor,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                    : null,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 10),
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color:
                    !log.isCompleted
                        ? Theme.of(context).scaffoldBackgroundColor
                        : (log.hasIssues ? colorError : colorPrimary),
                shape: BoxShape.circle,
                border:
                    !log.isCompleted
                        ? Border.all(color: unProgressColor, width: 2.5)
                        : null,
              ),
              child:
                  log.isCompleted
                      ? Icon(
                        log.hasIssues
                            ? Icons.priority_high_rounded
                            : Icons.check,
                        color: Colors.white,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          errorText ?? subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                log.hasIssues
                                    ? Colors.red
                                    : Colors.grey.shade700,
                            fontWeight: log.hasIssues ? FontWeight.w500 : null,
                          ),
                        ),
                        // const SizedBox(height: 8),
                        // LinearProgressIndicator(
                        //   value: progress,
                        //   backgroundColor: unProgressColor,
                        //   color: showError ? Colors.red : colorPrimary,
                        //   minHeight: 6,
                        //   borderRadius: BorderRadius.circular(6),
                        // ),
                        // const SizedBox(height: 20),
                      ],
                    ),
                    CustomButton.icon(
                      icon: Icons.more_horiz,
                      onPressed: () {
                        _showModalSheet(
                          context: context,
                          builder: (context) {
                            final textTheme = Theme.of(context).textTheme;

                            return BottomSheet(
                              backgroundColor: Colors.grey.shade50,
                              enableDrag: false,
                              onClosing: () {},
                              builder:
                                  (context) => Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Wrap(
                                      // main: MainAxisAlignment.end,
                                      alignment: WrapAlignment.end,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: 15,
                                          children: [
                                            Icon(
                                              log.isCompleted
                                                  ? Icons.check_circle_rounded
                                                  : Icons.remove_circle_rounded,
                                              color:
                                                  log.isCompleted
                                                      ? colorPrimary
                                                      : colorPending,
                                              size: 37,
                                            ),
                                            Column(
                                              spacing: 3,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: textTheme.titleLarge!
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                Text(
                                                  subtitle,
                                                  style: textTheme.bodyMedium!
                                                      .copyWith(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade800,
                                                      ),
                                                ),
                                                SizedBox(height: 30),
                                                Text(
                                                  "Assignees",
                                                  style: textTheme.titleMedium!
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                                // Assignees list - Unimplemented as of now
                                                Text(
                                                  "-",
                                                  style: textTheme.bodyMedium!
                                                      .copyWith(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade700,
                                                      ),
                                                ),
                                                if (log.description != null &&
                                                    log
                                                        .description!
                                                        .isNotEmpty) ...[
                                                  SizedBox(height: 5),
                                                  Text(
                                                    log.description!,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 3,
                                                  ),
                                                ],
                                                SizedBox(height: 30),
                                                SizedBox(
                                                  width:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width -
                                                      115,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          "Add Crucial Alert",
                                                        ),
                                                      ),
                                                      CupertinoButton.tinted(
                                                        onPressed:
                                                            log.isCompleted
                                                                ? null
                                                                : () {
                                                                  addCrucialAlert(
                                                                    log,
                                                                  );
                                                                },
                                                        // borderRadius: 8,
                                                        disabledColor:
                                                            log.isCompleted
                                                                ? Colors
                                                                    .grey
                                                                    .shade100
                                                                : CupertinoColors
                                                                    .tertiarySystemFill,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 14,
                                                              vertical: 8,
                                                            ),
                                                        color: Colors.grey,
                                                        child: Text(
                                                          "Add",
                                                          style: textTheme
                                                              .labelLarge!
                                                              .copyWith(
                                                                color:
                                                                    log.isCompleted
                                                                        ? Colors
                                                                            .grey
                                                                            .shade300
                                                                        : null,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 20),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: double.infinity,
                                          child: FilledButton.tonal(
                                            onPressed:
                                                log.isCompleted
                                                    ? null
                                                    : () async {
                                                      await ref
                                                          .watch(
                                                            progressLogNotifierProvider
                                                                .notifier,
                                                          )
                                                          .markAsCompleted(log);
                                                      log.isCompleted = true;
                                                      Navigator.pop(context);
                                                    },
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                              disabledBackgroundColor: Colors
                                                  .grey
                                                  .withValues(alpha: 0.1),
                                            ),
                                            child: Text(
                                              log.isCompleted
                                                  ? "Completed"
                                                  : "Mark as Completed",
                                              style:
                                                  log.isCompleted
                                                      ? TextStyle(
                                                        color: colorPrimary,
                                                      )
                                                      : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            );
                          },
                        );
                      },
                      height: 33,
                      width: 33,
                      iconSize: 23,
                      backgroundColor: Colors.grey.shade100,
                      iconColor: Colors.black87,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void addCrucialAlert(ProgressLog progressLog) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddProjectProgressScreen.view(
              projectId: widget.projectId,
              progressLog: progressLog,
            ),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    refreshManager = TimelineRefreshManager();
    print("at init state");
    Future.microtask(() {
      ref
          .read(
            progressLogsByProjectProvider(
              ProgressLogsByProviderArgs(widget.projectId),
            ),
          )
          .then((value) {
            progressLogs = value;
            setState(() {});
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    late final Project project;

    try {
      project = ref.watch(projectByIdProvider(widget.projectId))!;
    } catch (e) {
      // Project not found
      return Scaffold(body: Center(child: Text("Project not found: E70")));
    }

    /// refresh data only if it's been been specified interval since the last refresh
    // if (refreshManager.reset(widget.projectId)) {
    print("reset, project id: ${widget.projectId}");

    progressLogs = ref.watch(
      progressLogsByProjectProviderSimple(widget.projectId),
    );
    // }

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
                      final log = progressLogs.elementAt(index);

                      return _buildStep(
                        context,
                        progressLogs.length,
                        index,
                        log: log,
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
