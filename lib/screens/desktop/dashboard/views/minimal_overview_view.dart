// lib/screens/desktop/dashboard/views/minimal_overview_view.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/minimal_overview.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';

class MinimalOverviewView extends StatelessWidget {
  final MinimalOverview data;
  const MinimalOverviewView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = DashTheme.minimalAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DashKpiTile(
                label: 'My open tasks',
                value: '${data.totalOpenTasks}',
                icon: Icons.checklist_outlined,
                accent: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Unread messages',
                value: '${data.totalUnreadMessages}',
                icon: Icons.mark_chat_unread_outlined,
                accent: accent,
                alert: data.totalUnreadMessages > 0,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'My projects',
                value: '${data.myProjects.length}',
                icon: Icons.folder_open_outlined,
                accent: accent,
              ),
            ),
          ],
        ),

        const SizedBox(height: 26),

        const DashSectionHeader(title: 'My Tasks'),
        DashTaskListCard(
          title: 'Assigned to me',
          tasks: data.myTasks,
          emptyTitle: 'Nothing assigned',
          emptySubtitle: 'Tasks assigned to you will appear here',
          emptyIcon: Icons.assignment_outlined,
          accent: accent,
          maxVisible: 10,
        ),

        const SizedBox(height: 26),

        const DashSectionHeader(title: 'My Projects'),
        if (data.myProjects.isEmpty)
          const DashCard(
            child: DashEmptyState(
              title: 'No projects yet',
              subtitle: 'Projects you\'re part of will appear here',
              icon: Icons.folder_off_outlined,
            ),
          )
        else
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children:
                data.myProjects.map((p) {
                  return Container(
                    width: 210,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: DashTheme.white,
                      borderRadius: BorderRadius.circular(DashTheme.rLg),
                      border: Border.all(color: DashTheme.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DashTheme.ink2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.status,
                          style: const TextStyle(
                            fontSize: 11,
                            color: DashTheme.slate400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: p.progressPct / 100,
                            minHeight: 5,
                            backgroundColor: DashTheme.slate100,
                            valueColor: const AlwaysStoppedAnimation(
                              DashTheme.minimalAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${p.progressPct}% complete',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: DashTheme.slate400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),

        const SizedBox(height: 20),
      ],
    );
  }
}
