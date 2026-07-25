// lib/screens/desktop/dashboard/views/design_overview_view.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/design_overview.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';

class DesignOverviewView extends StatelessWidget {
  final DesignOverview data;
  const DesignOverviewView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = DashboardTokens.designAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── KPI row ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: KpiStat(
                label: 'IN MY QUEUE',
                value: '${data.myQueue.allTasksCount}',
                icon: Icons.brush_outlined,
                accentColor: accent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'NEEDS REVISION',
                value: '${data.myQueue.revisionTasks.length}',
                icon: Icons.replay_outlined,
                accentColor:
                    data.myQueue.revisionTasks.isNotEmpty
                        ? DashboardTokens.danger
                        : accent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'READY TO HAND OFF',
                value: '${data.handoff.readyForPrintCount}',
                icon: Icons.local_shipping_outlined,
                accentColor: DashboardTokens.success,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'UNREAD MESSAGES',
                value: '${data.messages.totalUnreadCount}',
                icon: Icons.mark_chat_unread_outlined,
                accentColor:
                    data.messages.totalUnreadCount > 0
                        ? DashboardTokens.info
                        : accent,
              ),
            ),
          ],
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── My queue, grouped by status ──────────────────────────────────
        const DashboardSectionHeader(title: 'My Queue'),
        if (data.myQueue.statusGroups.isEmpty &&
            data.myQueue.revisionTasks.isEmpty)
          const DashboardCard(
            child: DashboardEmptyState(
              message: 'Nothing in your queue — new work will show up here',
              icon: Icons.self_improvement_outlined,
            ),
          )
        else
          Column(
            children: [
              if (data.myQueue.revisionTasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: DashboardTokens.space16,
                  ),
                  child: DashboardCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: DashboardTokens.space16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DashboardTokens.space16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.replay_outlined,
                                size: 16,
                                color: DashboardTokens.danger,
                              ),
                              const SizedBox(width: DashboardTokens.space8),
                              Text(
                                'Revision',
                                style: DashboardTokens.cardTitle.copyWith(
                                  color: DashboardTokens.danger,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${data.myQueue.revisionTasks.length}',
                                style: DashboardTokens.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DashboardTokens.space8),
                        ...data.myQueue.revisionTasks.map(
                          (t) => TaskRow(task: t),
                        ),
                      ],
                    ),
                  ),
                ),
              StatusGroupList(groups: data.myQueue.statusGroups),
            ],
          ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Two column: Handoff readiness + Attention ────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _HandoffSection(data: data)),
            const SizedBox(width: DashboardTokens.space24),
            Expanded(child: _AttentionSection(data: data)),
          ],
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Upcoming deadlines ────────────────────────────────────────────
        const DashboardSectionHeader(title: 'Upcoming Deadlines'),
        TaskListCard(
          title: 'Next 7 days',
          tasks: data.upcomingDeadlines,
          emptyMessage: 'No deadlines coming up',
          maxVisible: 8,
        ),

        const SizedBox(height: DashboardTokens.space24),
      ],
    );
  }
}

class _HandoffSection extends StatelessWidget {
  final DesignOverview data;
  const _HandoffSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(title: 'Handoff Readiness'),
        DashboardCard(
          padding: const EdgeInsets.symmetric(
            vertical: DashboardTokens.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.handoff.missingSpecTasks.isEmpty &&
                  data.handoff.multiSpecTasks.isEmpty)
                const DashboardEmptyState(
                  message: 'All approved work is print-ready',
                  icon: Icons.task_alt_outlined,
                )
              else ...[
                if (data.handoff.missingSpecTasks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardTokens.space16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 14,
                          color: DashboardTokens.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Missing print spec',
                          style: DashboardTokens.caption.copyWith(
                            color: DashboardTokens.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DashboardTokens.space4),
                  ...data.handoff.missingSpecTasks
                      .take(4)
                      .map((t) => TaskRow(task: t)),
                ],
                if (data.handoff.multiSpecTasks.isNotEmpty) ...[
                  const SizedBox(height: DashboardTokens.space8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardTokens.space16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 14,
                          color: DashboardTokens.info,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Multi-stage — review before handoff',
                          style: DashboardTokens.caption.copyWith(
                            color: DashboardTokens.info,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DashboardTokens.space4),
                  ...data.handoff.multiSpecTasks
                      .take(4)
                      .map((t) => TaskRow(task: t)),
                ],
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
        const DashboardSectionHeader(title: 'Attention Needed'),
        DashboardCard(
          padding: const EdgeInsets.symmetric(
            vertical: DashboardTokens.space12,
          ),
          child:
              !data.attention.hasIssues
                  ? const DashboardEmptyState(
                    message: 'Nothing stalled or blocked — clear runway',
                    icon: Icons.check_circle_outline,
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.attention.stalledApprovalTasks.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DashboardTokens.space16,
                          ),
                          child: Text(
                            'Awaiting client response',
                            style: DashboardTokens.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: DashboardTokens.space4),
                        ...data.attention.stalledApprovalTasks
                            .take(4)
                            .map((t) => TaskRow(task: t)),
                      ],
                      if (data.attention.blockedOrPausedTasks.isNotEmpty) ...[
                        const SizedBox(height: DashboardTokens.space8),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DashboardTokens.space16,
                          ),
                          child: Text(
                            'Blocked or paused',
                            style: DashboardTokens.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: DashboardTokens.space4),
                        ...data.attention.blockedOrPausedTasks
                            .take(4)
                            .map((t) => TaskRow(task: t)),
                      ],
                    ],
                  ),
        ),
      ],
    );
  }
}
