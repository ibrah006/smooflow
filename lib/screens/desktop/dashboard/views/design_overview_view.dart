// lib/screens/desktop/dashboard/views/design_overview_view.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/design_overview.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';

class DesignOverviewView extends StatelessWidget {
  final DesignOverview data;
  const DesignOverviewView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = DashTheme.designAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DashKpiTile(
                label: 'In my queue',
                value: '${data.myQueue.allTasksCount}',
                icon: Icons.brush_outlined,
                accent: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Needs revision',
                value: '${data.myQueue.revisionTasks.length}',
                icon: Icons.replay_outlined,
                accent: accent,
                alert: data.myQueue.revisionTasks.isNotEmpty,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Ready to hand off',
                value: '${data.handoff.readyForPrintCount}',
                icon: Icons.local_shipping_outlined,
                accent: DashTheme.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Unread messages',
                value: '${data.messages.totalUnreadCount}',
                icon: Icons.mark_chat_unread_outlined,
                accent: accent,
                alert: data.messages.totalUnreadCount > 0,
              ),
            ),
          ],
        ),

        const SizedBox(height: 26),

        DashSectionHeader(
          title: 'My Queue',
          count: data.myQueue.allTasksCount,
          accent: accent,
        ),
        if (data.myQueue.statusGroups.isEmpty &&
            data.myQueue.revisionTasks.isEmpty)
          const DashCard(
            child: DashEmptyState(
              title: 'Queue is clear',
              subtitle: 'New work assigned to you will show up here',
              icon: Icons.self_improvement_outlined,
            ),
          )
        else
          Column(
            children: [
              if (data.myQueue.revisionTasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DashCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: kDashRowHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: DashTheme.red50,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(DashTheme.rLg),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.replay_outlined,
                                size: 15,
                                color: DashTheme.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Revision',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: DashTheme.red.withOpacity(0.9),
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              DashCounterPill(
                                count: data.myQueue.revisionTasks.length,
                                accent: DashTheme.red,
                              ),
                            ],
                          ),
                        ),
                        ...data.myQueue.revisionTasks.map(
                          (t) => DashTaskRow(task: t),
                        ),
                      ],
                    ),
                  ),
                ),
              DashStatusGroupList(
                groups: data.myQueue.statusGroups,
                emptyTitle: 'Nothing queued',
                emptySubtitle: 'No tasks in this stage right now',
              ),
            ],
          ),

        const SizedBox(height: 26),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _HandoffSection(data: data)),
            const SizedBox(width: 20),
            Expanded(child: _AttentionSection(data: data)),
          ],
        ),

        const SizedBox(height: 26),

        const DashSectionHeader(title: 'Upcoming Deadlines'),
        DashTaskListCard(
          title: 'Next 7 days',
          tasks: data.upcomingDeadlines,
          emptyTitle: 'Nothing due soon',
          emptySubtitle: 'You\'re clear for the next 7 days',
          emptyIcon: Icons.event_available_outlined,
          accent: accent,
          maxVisible: 8,
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

class _HandoffSection extends StatelessWidget {
  final DesignOverview data;
  const _HandoffSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasPending = data.handoff.hasPendingWork;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashSectionHeader(title: 'Handoff Readiness'),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child:
              !hasPending
                  ? const DashEmptyState(
                    title: 'Print-ready',
                    subtitle: 'All approved work has complete specs',
                    icon: Icons.task_alt_outlined,
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.handoff.missingSpecTasks.isNotEmpty) ...[
                        DashLabelChip(
                          label: 'MISSING PRINT SPEC',
                          color: DashTheme.amber,
                          icon: Icons.error_outline,
                        ),
                        const SizedBox(height: 4),
                        ...data.handoff.missingSpecTasks
                            .take(4)
                            .map((t) => DashTaskRow(task: t)),
                      ],
                      if (data.handoff.multiSpecTasks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        DashLabelChip(
                          label: 'MULTI-STAGE — REVIEW',
                          color: DashTheme.blue,
                          icon: Icons.layers_outlined,
                        ),
                        const SizedBox(height: 4),
                        ...data.handoff.multiSpecTasks
                            .take(4)
                            .map((t) => DashTaskRow(task: t)),
                      ],
                    ],
                  ),
        ),
      ],
    );
  }
}

class _AttentionSection extends StatelessWidget {
  final DesignOverview data;
  const _AttentionSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashSectionHeader(title: 'Attention Needed'),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child:
              !data.attention.hasIssues
                  ? const DashEmptyState(
                    title: 'Clear runway',
                    subtitle: 'Nothing stalled or blocked right now',
                    icon: Icons.check_circle_outline,
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.attention.stalledApprovalTasks.isNotEmpty) ...[
                        DashLabelChip(
                          label: 'AWAITING CLIENT RESPONSE',
                          color: DashTheme.amber,
                        ),
                        const SizedBox(height: 4),
                        ...data.attention.stalledApprovalTasks
                            .take(4)
                            .map((t) => DashTaskRow(task: t)),
                      ],
                      if (data.attention.blockedOrPausedTasks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        DashLabelChip(
                          label: 'BLOCKED OR PAUSED',
                          color: DashTheme.red,
                        ),
                        const SizedBox(height: 4),
                        ...data.attention.blockedOrPausedTasks
                            .take(4)
                            .map((t) => DashTaskRow(task: t)),
                      ],
                    ],
                  ),
        ),
      ],
    );
  }
}
