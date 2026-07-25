// lib/screens/desktop/dashboard/views/admin_overview_view.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/admin_overview.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';

class AdminOverviewView extends StatelessWidget {
  final AdminOverview data;
  const AdminOverviewView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = DashTheme.adminAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DashKpiTile(
                label: 'Active tasks',
                value: '${data.pipeline.totalTasks}',
                icon: Icons.dashboard_customize_outlined,
                accent: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Overdue',
                value: '${data.pipeline.overdueTaskCount}',
                icon: Icons.schedule_outlined,
                accent: accent,
                alert: data.pipeline.overdueTaskCount > 0,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Needs attention',
                value: '${data.pipeline.totalAttention}',
                icon: Icons.flag_outlined,
                accent: accent,
                alert: data.pipeline.totalAttention > 0,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Printers active',
                value:
                    '${data.printers.activeCount}/${data.printers.totalPrinters}',
                icon: Icons.print_outlined,
                accent: accent,
              ),
            ),
          ],
        ),

        const SizedBox(height: 26),

        const DashSectionHeader(title: 'Pipeline'),
        DashCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PipelineStrip(statusCounts: data.pipeline.statusCounts),
              const SizedBox(height: 14),
              PipelineLegend(statusCounts: data.pipeline.statusCounts),
              if (data.pipeline.totalAttention > 0) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: DashTheme.slate200),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 13,
                      color: DashTheme.amber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Attention needed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DashTheme.amber,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PipelineLegend(statusCounts: data.pipeline.attentionCounts),
              ],
            ],
          ),
        ),

        const SizedBox(height: 26),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _PrinterFleetSection(data: data)),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: _ProjectsAtRiskSection(data: data)),
          ],
        ),

        const SizedBox(height: 26),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _MaterialsSection(data: data)),
            const SizedBox(width: 20),
            Expanded(child: _TeamWorkloadSection(data: data)),
          ],
        ),

        const SizedBox(height: 26),

        const DashSectionHeader(title: 'Top Clients'),
        _TopClientsSection(data: data),

        const SizedBox(height: 20),
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
        DashSectionHeader(
          title: 'Printer Fleet',
          count: data.printers.totalPrinters,
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
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.3,
            ),
            itemCount: data.printers.fleet.length,
            itemBuilder:
                (context, i) =>
                    DashPrinterTile(printer: data.printers.fleet[i]),
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
        DashSectionHeader(
          title: 'Projects At Risk',
          count: data.projectsAtRisk.length,
        ),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child:
              data.projectsAtRisk.isEmpty
                  ? const DashEmptyState(
                    title: 'Nothing flagged',
                    subtitle: 'All projects are tracking on schedule',
                    icon: Icons.verified_outlined,
                  )
                  : Column(
                    children:
                        data.projectsAtRisk.take(6).map((p) {
                          final overdue = p.isOverdue;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
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
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: DashTheme.ink3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${p.progressPct}%',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            overdue
                                                ? DashTheme.red
                                                : DashTheme.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: p.progressPct / 100,
                                    minHeight: 5,
                                    backgroundColor: DashTheme.slate100,
                                    valueColor: AlwaysStoppedAnimation(
                                      overdue
                                          ? DashTheme.red
                                          : DashTheme.adminAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  p.clientName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: DashTheme.slate400,
                                    fontWeight: FontWeight.w500,
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

class _MaterialsSection extends StatelessWidget {
  final AdminOverview data;
  const _MaterialsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashSectionHeader(
          title: 'Low Stock Materials',
          count: data.materials.lowStock.length,
          accent: DashTheme.amber,
        ),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child:
              data.materials.lowStock.isEmpty
                  ? const DashEmptyState(
                    title: 'Stock levels healthy',
                    subtitle: 'All materials are above minimum levels',
                    icon: Icons.inventory_2_outlined,
                  )
                  : Column(
                    children:
                        data.materials.lowStock.take(6).map((m) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: DashTheme.amber50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 13,
                                    color: DashTheme.amber,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: DashTheme.ink3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${m.currentStock.toStringAsFixed(0)} / ${m.minStockLevel.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: DashTheme.amber,
                                    fontWeight: FontWeight.w700,
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
        DashSectionHeader(title: 'Team Workload', count: data.team.totalPeople),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child:
              data.team.workload.isEmpty
                  ? const DashEmptyState(
                    title: 'No open tasks assigned',
                    subtitle:
                        'Workload will appear here once tasks are assigned',
                    icon: Icons.groups_outlined,
                  )
                  : Column(
                    children:
                        data.team.workload.take(6).map((w) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 11,
                                  backgroundColor:
                                      _parseColor(w.colorHex) ??
                                      DashTheme.adminAccent,
                                  child: Text(
                                    w.name.isNotEmpty
                                        ? w.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    w.name,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: DashTheme.ink3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 72,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: w.openTaskCount / maxCount,
                                      minHeight: 5,
                                      backgroundColor: DashTheme.slate100,
                                      valueColor: const AlwaysStoppedAnimation(
                                        DashTheme.adminAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${w.openTaskCount}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: DashTheme.slate500,
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
      return const DashCard(
        child: DashEmptyState(
          title: 'No active clients yet',
          subtitle: 'Client activity will appear here',
          icon: Icons.apartment_outlined,
        ),
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children:
          data.topClients.take(8).map((c) {
            return Container(
              width: 190,
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
                    c.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: DashTheme.ink2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.activeProjectCount} active project${c.activeProjectCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: DashTheme.slate400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
