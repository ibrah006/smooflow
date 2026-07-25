// lib/screens/desktop/dashboard/views/minimal_overview_view.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/minimal_overview.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';

class MinimalOverviewView extends StatelessWidget {
  final MinimalOverview data;
  const MinimalOverviewView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: KpiStat(
                label: 'MY OPEN TASKS',
                value: '${data.totalOpenTasks}',
                icon: Icons.checklist_outlined,
                accentColor: DashboardTokens.minimalAccent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'UNREAD MESSAGES',
                value: '${data.totalUnreadMessages}',
                icon: Icons.mark_chat_unread_outlined,
                accentColor:
                    data.totalUnreadMessages > 0
                        ? DashboardTokens.info
                        : DashboardTokens.minimalAccent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'MY PROJECTS',
                value: '${data.myProjects.length}',
                icon: Icons.folder_open_outlined,
                accentColor: DashboardTokens.minimalAccent,
              ),
            ),
          ],
        ),

        const SizedBox(height: DashboardTokens.space32),

        const DashboardSectionHeader(title: 'My Tasks'),
        TaskListCard(
          title: 'Assigned to me',
          tasks: data.myTasks,
          emptyMessage: 'No tasks assigned to you right now',
          maxVisible: 10,
        ),

        const SizedBox(height: DashboardTokens.space32),

        const DashboardSectionHeader(title: 'My Projects'),
        if (data.myProjects.isEmpty)
          const DashboardCard(
            child: DashboardEmptyState(
              message: 'You\'re not attached to any projects yet',
            ),
          )
        else
          Wrap(
            spacing: DashboardTokens.space16,
            runSpacing: DashboardTokens.space16,
            children:
                data.myProjects.map((p) {
                  return Container(
                    width: 220,
                    padding: const EdgeInsets.all(DashboardTokens.space16),
                    decoration: BoxDecoration(
                      color: DashboardTokens.surface,
                      borderRadius: BorderRadius.circular(
                        DashboardTokens.radiusMd,
                      ),
                      border: Border.all(color: DashboardTokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: DashboardTokens.cardTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: DashboardTokens.space4),
                        Text(p.status, style: DashboardTokens.caption),
                        const SizedBox(height: DashboardTokens.space12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: p.progressPct / 100,
                            minHeight: 5,
                            backgroundColor: DashboardTokens.surfaceSunken,
                            valueColor: const AlwaysStoppedAnimation(
                              DashboardTokens.minimalAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: DashboardTokens.space4),
                        Text(
                          '${p.progressPct}% complete',
                          style: DashboardTokens.caption,
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),

        const SizedBox(height: DashboardTokens.space24),
      ],
    );
  }
}
