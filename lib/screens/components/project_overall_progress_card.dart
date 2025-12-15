

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/enums/status.dart';
import 'package:smooflow/providers/progress_log_provider.dart';

// Project Overall Progress Card
class ProjectOverallProgressCard extends ConsumerWidget {
  final String? heroKey;

  final Function()? onPressed;
  final EdgeInsetsGeometry? margin;

  final String projectId;

  const ProjectOverallProgressCard({
    super.key,
    this.heroKey,
    this.onPressed,
    this.margin,
    required this.projectId
  });

  @override
  Widget build(BuildContext context, ref) {

    final progressLogs = ref.watch(
      progressLogsByProjectProviderSimple(projectId),
    );

    final totalStagesCount = progressLogs.length;

    final stagesCompltedCount = progressLogs.where((log) {
      return log.status == Status.finished;
    }).length;

    final stageCompletionPercent = totalStagesCount==0? 0.0 : (stagesCompltedCount/totalStagesCount);

    final child = Padding(
      padding: margin?? EdgeInsets.zero,
      child: MaterialButton(
        onPressed: onPressed,
        child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.assessment_rounded,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Progress',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$stagesCompltedCount of $totalStagesCount stages completed',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(stageCompletionPercent*100).toInt()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (onPressed != null) ...[
                      SizedBox(width: 3),
                      Icon(Icons.chevron_right_rounded)
                    ]
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stageCompletionPercent,
                    backgroundColor: Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
      ),
    );

    return heroKey!=null? Hero(
      tag: heroKey!,
      child: child
    ) : child;
  }
}