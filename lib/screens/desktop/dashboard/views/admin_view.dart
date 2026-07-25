// lib/screens/desktop/dashboard/views/admin_overview_view.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/admin_overview.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';

class AdminOverviewView extends StatelessWidget {
  final AdminOverview data;
  const AdminOverviewView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = DashboardTokens.adminAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── KPI row ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: KpiStat(
                label: 'ACTIVE TASKS',
                value: '${data.pipeline.totalTasks}',
                icon: Icons.dashboard_customize_outlined,
                accentColor: accent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'OVERDUE',
                value: '${data.pipeline.overdueTaskCount}',
                icon: Icons.schedule_outlined,
                accentColor:
                    data.pipeline.overdueTaskCount > 0
                        ? DashboardTokens.danger
                        : accent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'NEEDS ATTENTION',
                value: '${data.pipeline.totalAttention}',
                icon: Icons.flag_outlined,
                accentColor:
                    data.pipeline.totalAttention > 0
                        ? DashboardTokens.warning
                        : accent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'PRINTERS ACTIVE',
                value:
                    '${data.printers.activeCount}/${data.printers.totalPrinters}',
                icon: Icons.print_outlined,
                accentColor: accent,
              ),
            ),
          ],
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Pipeline overview ────────────────────────────────────────────
        const DashboardSectionHeader(title: 'Pipeline'),
        DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PipelineStrip(statusCounts: data.pipeline.statusCounts),
              const SizedBox(height: DashboardTokens.space16),
              PipelineLegend(statusCounts: data.pipeline.statusCounts),
              if (data.pipeline.totalAttention > 0) ...[
                const SizedBox(height: DashboardTokens.space16),
                const Divider(height: 1, color: DashboardTokens.border),
                const SizedBox(height: DashboardTokens.space16),
                Text(
                  'ATTENTION NEEDED',
                  style: DashboardTokens.sectionEyebrow.copyWith(
                    color: DashboardTokens.warning,
                  ),
                ),
                const SizedBox(height: DashboardTokens.space8),
                PipelineLegend(statusCounts: data.pipeline.attentionCounts),
              ],
            ],
          ),
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Two-column: Printers + Projects at risk ─────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _PrinterFleetSection(data: data)),
            const SizedBox(width: DashboardTokens.space24),
            Expanded(flex: 2, child: _ProjectsAtRiskSection(data: data)),
          ],
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Two-column: Materials + Team workload ────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _MaterialsSection(data: data)),
            const SizedBox(width: DashboardTokens.space24),
            Expanded(child: _TeamWorkloadSection(data: data)),
          ],
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Top clients ────────────────────────────────────────────────
        const DashboardSectionHeader(title: 'Top Clients'),
        _TopClientsSection(data: data),

        const SizedBox(height: DashboardTokens.space24),
      ],
    );
  }
}

class _PrinterFleetSection extends StatelessWidget {
  final AdminOverview data;
  const _PrinterFleetSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(title: 'Printer Fleet'),
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
              crossAxisCount: 3,
              mainAxisSpacing: DashboardTokens.space16,
              crossAxisSpacing: DashboardTokens.space16,
              childAspectRatio: 1.5,
            ),
            itemCount: data.printers.fleet.length,
            itemBuilder:
                (context, i) => PrinterTile(printer: data.printers.fleet[i]),
          ),
      ],
    );
  }
}

class _ProjectsAtRiskSection extends StatelessWidget {
  final AdminOverview data;
  const _ProjectsAtRiskSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(title: 'Projects At Risk'),
        DashboardCard(
          padding: const EdgeInsets.symmetric(
            vertical: DashboardTokens.space12,
          ),
          child:
              data.projectsAtRisk.isEmpty
                  ? const DashboardEmptyState(
                    message: 'No projects flagged — everything on track',
                  )
                  : Column(
                    children:
                        data.projectsAtRisk.take(6).map((p) {
                          final overdue = p.isOverdue;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DashboardTokens.space16,
                              vertical: DashboardTokens.space8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: DashboardTokens.bodyMd.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${p.progressPct}%',
                                      style: DashboardTokens.bodySm.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            overdue
                                                ? DashboardTokens.danger
                                                : DashboardTokens.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: p.progressPct / 100,
                                    minHeight: 5,
                                    backgroundColor:
                                        DashboardTokens.surfaceSunken,
                                    valueColor: AlwaysStoppedAnimation(
                                      overdue
                                          ? DashboardTokens.danger
                                          : DashboardTokens.adminAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.clientName,
                                  style: DashboardTokens.caption,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }
}

class _MaterialsSection extends StatelessWidget {
  final AdminOverview data;
  const _MaterialsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(title: 'Low Stock Materials'),
        DashboardCard(
          padding: const EdgeInsets.symmetric(
            vertical: DashboardTokens.space12,
          ),
          child:
              data.materials.lowStock.isEmpty
                  ? const DashboardEmptyState(
                    message: 'All materials above minimum levels',
                    icon: Icons.inventory_2_outlined,
                  )
                  : Column(
                    children:
                        data.materials.lowStock.take(6).map((m) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DashboardTokens.space16,
                              vertical: DashboardTokens.space8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: DashboardTokens.warning,
                                ),
                                const SizedBox(width: DashboardTokens.space8),
                                Expanded(
                                  child: Text(
                                    m.name,
                                    style: DashboardTokens.bodyMd,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${m.currentStock.toStringAsFixed(0)} / ${m.minStockLevel.toStringAsFixed(0)}',
                                  style: DashboardTokens.bodySm.copyWith(
                                    color: DashboardTokens.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }
}

class _TeamWorkloadSection extends StatelessWidget {
  final AdminOverview data;
  const _TeamWorkloadSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxCount =
        data.team.workload.isEmpty
            ? 1
            : data.team.workload
                .map((w) => w.openTaskCount)
                .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(title: 'Team Workload'),
        DashboardCard(
          padding: const EdgeInsets.symmetric(
            vertical: DashboardTokens.space12,
          ),
          child:
              data.team.workload.isEmpty
                  ? const DashboardEmptyState(
                    message: 'No open tasks assigned yet',
                  )
                  : Column(
                    children:
                        data.team.workload.take(6).map((w) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DashboardTokens.space16,
                              vertical: DashboardTokens.space8,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      _parseColor(w.colorHex) ??
                                      DashboardTokens.adminAccent,
                                  child: Text(
                                    w.name.isNotEmpty
                                        ? w.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: DashboardTokens.space12),
                                Expanded(
                                  child: Text(
                                    w.name,
                                    style: DashboardTokens.bodyMd,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: w.openTaskCount / maxCount,
                                      minHeight: 5,
                                      backgroundColor:
                                          DashboardTokens.surfaceSunken,
                                      valueColor: const AlwaysStoppedAnimation(
                                        DashboardTokens.adminAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: DashboardTokens.space8),
                                Text(
                                  '${w.openTaskCount}',
                                  style: DashboardTokens.bodySm.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }
}

class _TopClientsSection extends StatelessWidget {
  final AdminOverview data;
  const _TopClientsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.topClients.isEmpty) {
      return const DashboardCard(
        child: DashboardEmptyState(message: 'No active clients yet'),
      );
    }

    return Wrap(
      spacing: DashboardTokens.space16,
      runSpacing: DashboardTokens.space16,
      children:
          data.topClients.take(8).map((c) {
            return Container(
              width: 200,
              padding: const EdgeInsets.all(DashboardTokens.space16),
              decoration: BoxDecoration(
                color: DashboardTokens.surface,
                borderRadius: BorderRadius.circular(DashboardTokens.radiusMd),
                border: Border.all(color: DashboardTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: DashboardTokens.cardTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DashboardTokens.space4),
                  Text(
                    '${c.activeProjectCount} active project${c.activeProjectCount == 1 ? '' : 's'}',
                    style: DashboardTokens.bodySm,
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
