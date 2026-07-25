// lib/screens/desktop/dashboard/views/production_overview_view.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/production_overview.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';

class ProductionOverviewView extends StatelessWidget {
  final ProductionOverview data;
  const ProductionOverviewView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = DashboardTokens.productionAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── KPI row ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: KpiStat(
                label: 'PRINTERS AVAILABLE',
                value: '${data.printers.availablePrinterCount}',
                icon: Icons.check_circle_outline,
                accentColor: accent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'CURRENTLY PRINTING',
                value: '${data.productionQueue.printingCount}',
                icon: Icons.print_outlined,
                accentColor: accent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'WAITING TO START',
                value: '${data.productionQueue.waitingForPrintCount}',
                icon: Icons.hourglass_empty_outlined,
                accentColor: accent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'COMPLETED TODAY',
                value: '${data.completedToday.length}',
                icon: Icons.done_all_outlined,
                accentColor: DashboardTokens.success,
              ),
            ),
          ],
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Printer board ──────────────────────────────────────────────
        const DashboardSectionHeader(title: 'Printer Board'),
        if (data.printers.fleet.isEmpty)
          const DashboardCard(
            child: DashboardEmptyState(
              message: 'No printers configured yet',
              icon: Icons.print_disabled_outlined,
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: DashboardTokens.space16,
              crossAxisSpacing: DashboardTokens.space16,
              childAspectRatio: 1.3,
            ),
            itemCount: data.printers.fleet.length,
            itemBuilder:
                (context, i) => PrinterTile(printer: data.printers.fleet[i]),
          ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Today's schedule ──────────────────────────────────────────
        const DashboardSectionHeader(title: "Today's Schedule"),
        TaskListCard(
          title: 'Scheduled for today',
          tasks: data.printers.todaysSchedule,
          emptyMessage: 'Nothing scheduled for today yet',
          showPrinter: true,
          maxVisible: 8,
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Production queue by stage ────────────────────────────────
        const DashboardSectionHeader(title: 'Production Queue'),
        StatusGroupList(
          groups: data.productionQueue.statusGroups,
          emptyMessage: 'Nothing queued for production right now',
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Two column: Logistics + Attention ────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _LogisticsSection(data: data)),
            const SizedBox(width: DashboardTokens.space24),
            Expanded(child: _AttentionAndRunsSection(data: data)),
          ],
        ),

        const SizedBox(height: DashboardTokens.space24),
      ],
    );
  }
}

class _LogisticsSection extends StatelessWidget {
  final ProductionOverview data;
  const _LogisticsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(title: 'Logistics'),
        DashboardCard(
          padding: const EdgeInsets.symmetric(
            vertical: DashboardTokens.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.logistics.deliveryTaskCount == 0 &&
                  data.logistics.installationTaskCount == 0)
                const DashboardEmptyState(
                  message: 'No jobs in delivery or installation right now',
                )
              else ...[
                if (data.logistics.deliveryTaskCount > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardTokens.space16,
                    ),
                    child: Text(
                      'Delivery',
                      style: DashboardTokens.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: DashboardTokens.space4),
                  ...data.logistics.delivery
                      .expand((g) => g.items)
                      .take(5)
                      .map((t) => TaskRow(task: t)),
                ],
                if (data.logistics.installationTaskCount > 0) ...[
                  const SizedBox(height: DashboardTokens.space8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardTokens.space16,
                    ),
                    child: Text(
                      'Installation',
                      style: DashboardTokens.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: DashboardTokens.space4),
                  ...data.logistics.installation
                      .expand((g) => g.items)
                      .take(5)
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

class _AttentionAndRunsSection extends StatelessWidget {
  final ProductionOverview data;
  const _AttentionAndRunsSection({required this.data});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!data.attention.hasIssues && data.runsInProgress.isEmpty)
                const DashboardEmptyState(
                  message: 'All jobs on schedule',
                  icon: Icons.check_circle_outline,
                )
              else ...[
                if (data.attention.overrunningTasks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardTokens.space16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: DashboardTokens.danger,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Running over estimate',
                          style: DashboardTokens.caption.copyWith(
                            color: DashboardTokens.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DashboardTokens.space4),
                  ...data.attention.overrunningTasks
                      .take(4)
                      .map((t) => TaskRow(task: t, showPrinter: true)),
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
                      .map((t) => TaskRow(task: t, showPrinter: true)),
                ],
                if (data.runsInProgress.isNotEmpty) ...[
                  const SizedBox(height: DashboardTokens.space8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardTokens.space16,
                    ),
                    child: Text(
                      'Multi-run jobs in progress',
                      style: DashboardTokens.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: DashboardTokens.space4),
                  ...data.runsInProgress
                      .take(4)
                      .map(
                        (t) => TaskRow(
                          task: t,
                          showPrinter: true,
                          trailing:
                              t.runs != null
                                  ? Text(
                                    '${t.runs} runs',
                                    style: DashboardTokens.caption,
                                  )
                                  : null,
                        ),
                      ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
