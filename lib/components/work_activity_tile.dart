import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/extensions/duration_format.dart';
import 'package:smooflow/models/work_activity_log.dart';
import 'package:smooflow/providers/user_provider.dart';

class WorkActivityTile extends ConsumerWidget {
  final WorkActivityLog log;
  final double totalTaskContributionSeconds;

  const WorkActivityTile(
    this.log, {
    super.key,
    required this.totalTaskContributionSeconds,
  });

  @override
  Widget build(BuildContext context, ref) {
    final textTheme = Theme.of(context).textTheme;

    final duration = log.end?.difference(log.start);
    final durationDisplay = duration != null ? duration.formatTime : "Ongoing";

    double contributionPercent =
        (log.end?.difference(log.start).inSeconds ?? 0) /
        totalTaskContributionSeconds;

    contributionPercent =
        contributionPercent.isNaN
            ? 0
            : contributionPercent.isInfinite
            ? 100
            : contributionPercent;

    // users in memory
    final users = ref.read(userNotifierProvider);
    final logUser = users.firstWhere((user) => user.id == log.userId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        spacing: 15,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorPrimary.withValues(alpha: 0.1),
            child: Icon(Icons.person_rounded, color: colorPrimary, size: 28),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${logUser.name[0].toUpperCase()}${logUser.name.substring(1)}",
                  style: textTheme.titleMedium,
                ),
                Row(
                  spacing: 15,
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: contributionPercent,
                        borderRadius: BorderRadius.circular(10),
                        backgroundColor: colorPrimary.withValues(alpha: 0.15),
                      ),
                    ),
                    SizedBox(
                      width: 75,
                      child: Text(
                        durationDisplay,
                        style: textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
