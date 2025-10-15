import 'dart:async';

import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/providers/progress_log_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/providers/work_activity_log_providers.dart';
import 'package:smooflow/services/login_service.dart';

class ActiveWorkActivityLogCard extends ConsumerStatefulWidget {
  const ActiveWorkActivityLogCard({super.key});

  @override
  ConsumerState<ActiveWorkActivityLogCard> createState() =>
      _ActiveWorkActivityLogCardState();
}

class _ActiveWorkActivityLogCardState
    extends ConsumerState<ActiveWorkActivityLogCard> {
  Timer? _timer;

  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();

    _timer!.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final currentUser = LoginService.currentUser!;
    final name =
        "${currentUser.name[0].toUpperCase()}${currentUser.name.substring(1)}";

    final Future<WorkActivityLog?> activeWorkActivityLogFuture =
        ref.watch(workActivityLogNotifierProvider.notifier).activeLog;

    activeWorkActivityLogFuture.then((value) {
      startDurationEventHandler();
    });

    final activeTask = ref.watch(taskNotifierProvider.notifier).activeTask;

    if (_timer?.isActive != true || activeTask == null) {
      return SizedBox();
    }

    final taskProgressLogFuture = ref
        .watch(progressLogNotifierProvider.notifier)
        .getLog(activeTask.progressLogId);

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      width: MediaQuery.of(context).size.width - 40 > 310 ? 310 : null,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 7,
            color: Colors.grey.shade100,
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("Active Work Log", style: textTheme.titleMedium)],
          ),
          SizedBox(height: 3),
          StreamBuilder<int>(
            stream:
                ref
                    .read(workActivityLogNotifierProvider.notifier)
                    .activeLogDurationNotifier!
                    .stream,
            builder: (context, snapshot) {
              return Text(
                snapshot.data != null
                    ? activeActivityLogDuration(snapshot.data!)
                    : "00:00:00",
                style: textTheme.headlineLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.75,
                ),
              );
            },
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  "Task: ${activeTask.name}",
                  style: textTheme.bodyMedium!.copyWith(
                    color: Colors.grey.shade900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: taskProgressLogFuture,
                  builder: (context, snapshot) {
                    final taskProgressLog = snapshot.data;
                    if (taskProgressLog == null) {
                      return CardLoading(
                        height: 15,
                        width: 50,
                        borderRadius: BorderRadius.circular(10),
                      );
                    }

                    return Text(
                      " | Dept: ${taskProgressLog.status.name}",
                      style: textTheme.bodyMedium!.copyWith(
                        color: Colors.grey.shade900,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 3),
          Row(
            spacing: 5,
            children: [
              Icon(Icons.account_circle_rounded, size: 42),
              Text(name, style: textTheme.titleMedium),
              Spacer(),
              FilledButton(
                onPressed: _isLoading ? null : stopTask,
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: Colors.grey.shade200,
                  padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                  minimumSize: Size.zero,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(),
                      ),
                    Text("Stop"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String activeActivityLogDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    return "${duration.inHours.toString().padLeft(2, "0")}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";
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
          ref
              .read(workActivityLogNotifierProvider.notifier)
              .activeLogDurationNotifier!
              .sink
              .add(activeWorkActivityLog!.duration.inSeconds);
        } catch (e) {
          // already disposed / ended the work activity log
          setState(() {});
          return;
        }
      });
      if (ref
              .read(workActivityLogNotifierProvider.notifier)
              .activeLogDurationNotifier ==
          null) {
        return;
      }
    });

    // If we got this far, assume that there exists an active work activity log
    setState(() {});
  }

  void stopTask() async {
    setState(() {
      _isLoading = true;
    });

    // Update task status
    await ref.read(taskNotifierProvider.notifier).endActiveTask();

    await ref.read(workActivityLogNotifierProvider.notifier).endWorkSession();

    setState(() {
      _isLoading = false;
      _timer!.cancel();
      _timer = null;
    });
  }
}
