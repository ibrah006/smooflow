import 'package:flutter/material.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/extensions/duration_format.dart';
import 'package:smooflow/models/work_activity_log.dart';

class WorkActivityTile extends StatelessWidget {
  final WorkActivityLog log;

  const WorkActivityTile(this.log, {super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final duration = log.end?.difference(log.start);
    final durationDisplay =
        duration != null ? duration.formatHoursMinutes : "Ongoing";

    return Row(
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
              Text(log.userId, style: textTheme.titleMedium),
              Row(
                spacing: 15,
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 0.4,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: colorPrimary.withValues(alpha: 0.15),
                    ),
                  ),
                  Text(durationDisplay, style: textTheme.titleMedium),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
