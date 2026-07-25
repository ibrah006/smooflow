// lib/screens/desktop/dashboard/views/production_overview_view.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/production_overview.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';

class ProductionOverviewView extends StatelessWidget {
  final ProductionOverview data;
  const ProductionOverviewView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = DashTheme.productionAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DashKpiTile(
                label: 'Printers available',
                value: '${data.printers.availablePrinterCount}',
                icon: Icons.check_circle_outline,
                accent: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Currently printing',
                value: '${data.productionQueue.printingCount}',
                icon: Icons.print_outlined,
                accent: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Waiting to start',
                value: '${data.productionQueue.waitingForPrintCount}',
                icon: Icons.hourglass_empty_outlined,
                accent: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Completed today',
                value: '${data.completedToday.length}',
                icon: Icons.done_all_outlined,
                accent: DashTheme.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 26),

        DashSectionHeader(
          title: 'Printer Board',
          count: data.printers.fleet.length,
          accent: accent,
        ),
        if (data.printers.fleet.isEmpty)
          const DashCard(
            child: DashEmptyState(
              title: 'No printers yet',
              subtitle: 'Printers you add will appear here',
              icon: Icons.print_disabled_outlined,
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.3,
            ),
            itemCount: data.printers.fleet.length,
            itemBuilder:
                (context, i) =>
                    DashPrinterTile(printer: data.printers.fleet[i]),
          ),

        const SizedBox(height: 26),

        const DashSectionHeader(title: "Today's Schedule"),
        DashTaskListCard(
          title: 'Scheduled for today',
          tasks: data.printers.todaysSchedule,
          emptyTitle: 'Nothing scheduled',
          emptySubtitle: 'No jobs scheduled for today yet',
          emptyIcon: Icons.event_note_outlined,
          showPrinter: true,
          accent: accent,
          maxVisible: 8,
        ),

        const SizedBox(height: 26),

        const DashSectionHeader(title: 'Production Queue'),
        DashStatusGroupList(
          groups: data.productionQueue.statusGroups,
          emptyTitle: 'Queue is clear',
          emptySubtitle: 'Nothing queued for production right now',
        ),

        const SizedBox(height: 26),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _LogisticsSection(data: data)),
            const SizedBox(width: 20),
            Expanded(child: _AttentionAndRunsSection(data: data)),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

class _LogisticsSection extends StatelessWidget {
  final ProductionOverview data;
  const _LogisticsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasAny =
        data.logistics.deliveryTaskCount > 0 ||
        data.logistics.installationTaskCount > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashSectionHeader(title: 'Logistics'),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child:
              !hasAny
                  ? const DashEmptyState(
                    title: 'Nothing in transit',
                    subtitle: 'No jobs in delivery or installation right now',
                    icon: Icons.local_shipping_outlined,
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.logistics.deliveryTaskCount > 0) ...[
                        const DashLabelChip(
                          label: 'DELIVERY',
                          color: DashTheme.blue,
                        ),
                        const SizedBox(height: 4),
                        ...data.logistics.delivery
                            .expand((g) => g.items)
                            .take(5)
                            .map((t) => DashTaskRow(task: t)),
                      ],
                      if (data.logistics.installationTaskCount > 0) ...[
                        const SizedBox(height: 8),
                        const DashLabelChip(
                          label: 'INSTALLATION',
                          color: Color(0xFF0D9488),
                        ),
                        const SizedBox(height: 4),
                        ...data.logistics.installation
                            .expand((g) => g.items)
                            .take(5)
                            .map((t) => DashTaskRow(task: t)),
                      ],
                    ],
                  ),
        ),
      ],
    );
  }
}

class _AttentionAndRunsSection extends StatelessWidget {
  final ProductionOverview data;
  const _AttentionAndRunsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasAny = data.attention.hasIssues || data.runsInProgress.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashSectionHeader(title: 'Attention Needed'),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child:
              !hasAny
                  ? const DashEmptyState(
                    title: 'On schedule',
                    subtitle: 'All jobs running as expected',
                    icon: Icons.check_circle_outline,
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.attention.overrunningTasks.isNotEmpty) ...[
                        const DashLabelChip(
                          label: 'RUNNING OVER ESTIMATE',
                          color: DashTheme.red,
                          icon: Icons.warning_amber_rounded,
                        ),
                        const SizedBox(height: 4),
                        ...data.attention.overrunningTasks
                            .take(4)
                            .map(
                              (t) => DashTaskRow(task: t, showPrinter: true),
                            ),
                      ],
                      if (data.attention.blockedOrPausedTasks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const DashLabelChip(
                          label: 'BLOCKED OR PAUSED',
                          color: DashTheme.slate500,
                        ),
                        const SizedBox(height: 4),
                        ...data.attention.blockedOrPausedTasks
                            .take(4)
                            .map(
                              (t) => DashTaskRow(task: t, showPrinter: true),
                            ),
                      ],
                      if (data.runsInProgress.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const DashLabelChip(
                          label: 'MULTI-RUN JOBS IN PROGRESS',
                          color: DashTheme.blue,
                        ),
                        const SizedBox(height: 4),
                        ...data.runsInProgress
                            .take(4)
                            .map(
                              (t) => DashTaskRow(
                                task: t,
                                showPrinter: true,
                                trailing:
                                    t.runs != null
                                        ? Text(
                                          '${t.runs} runs',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: DashTheme.slate400,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                      ],
                    ],
                  ),
        ),
      ],
    );
  }
}
