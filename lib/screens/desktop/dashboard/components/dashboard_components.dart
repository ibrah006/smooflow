// lib/screens/desktop/dashboard/widgets/dashboard_widgets.dart
//
// Shared building blocks used across all role dashboards. Keeping these
// generic means each role screen focuses purely on data composition, not
// re-implementing card chrome.

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/dashboard_models.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';

// ── Page scaffold pieces ──────────────────────────────────────────────────

/// Section eyebrow + title row used above every card group.
class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DashboardTokens.space12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(), style: DashboardTokens.sectionEyebrow),
          if (trailingLabel != null)
            InkWell(
              onTap: onTrailingTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  trailingLabel!,
                  style: DashboardTokens.bodySm.copyWith(
                    color: DashboardTokens.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Generic card container with consistent chrome.
class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DashboardTokens.space20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DashboardTokens.surface,
        borderRadius: BorderRadius.circular(DashboardTokens.radiusMd),
        border: Border.all(color: DashboardTokens.border),
        boxShadow: DashboardTokens.cardShadow,
      ),
      child: child,
    );
  }
}

/// Empty-state placeholder, used inside any card/list that has no data.
/// Written as direction, not apology — tells the viewer what the absence means.
class DashboardEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const DashboardEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.check_circle_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DashboardTokens.space24),
      child: Column(
        children: [
          Icon(icon, size: 28, color: DashboardTokens.textTertiary),
          const SizedBox(height: DashboardTokens.space8),
          Text(
            message,
            style: DashboardTokens.bodySm,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── KPI stat card ────────────────────────────────────────────────────────

class KpiStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? accentColor;
  final IconData? icon;
  final String? deltaLabel;
  final bool deltaPositive;

  const KpiStat({
    super.key,
    required this.label,
    required this.value,
    this.accentColor,
    this.icon,
    this.deltaLabel,
    this.deltaPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? DashboardTokens.textPrimary;
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: DashboardTokens.caption),
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: accent),
                ),
            ],
          ),
          const SizedBox(height: DashboardTokens.space12),
          Text(value, style: DashboardTokens.kpiNumber),
          if (deltaLabel != null) ...[
            const SizedBox(height: DashboardTokens.space4),
            Row(
              children: [
                Icon(
                  deltaPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color:
                      deltaPositive
                          ? DashboardTokens.success
                          : DashboardTokens.danger,
                ),
                const SizedBox(width: 2),
                Text(
                  deltaLabel!,
                  style: DashboardTokens.bodySm.copyWith(
                    color:
                        deltaPositive
                            ? DashboardTokens.success
                            : DashboardTokens.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pipeline strip — the dashboard's signature element ──────────────────
//
// Renders the job pipeline as a connected horizontal band of segments,
// each sized by its share of tasks and colored by status. This echoes the
// physical reality of a print job moving through stages, and doubles as
// a tappable filter. Used by Admin (full pipeline) and reused in a
// truncated form by Design/Production for their slice of it.

class PipelineStrip extends StatelessWidget {
  final List<TaskStatusCount> statusCounts;
  final void Function(String status)? onSegmentTap;
  final double height;

  const PipelineStrip({
    super.key,
    required this.statusCounts,
    this.onSegmentTap,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final total = statusCounts.fold<int>(0, (sum, s) => sum + s.count);
    final nonEmpty = statusCounts.where((s) => s.count > 0).toList();

    if (total == 0 || nonEmpty.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: DashboardTokens.surfaceSunken,
          borderRadius: BorderRadius.circular(DashboardTokens.radiusSm),
        ),
        alignment: Alignment.center,
        child: Text(
          'No active tasks in the pipeline',
          style: DashboardTokens.bodySm,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(DashboardTokens.radiusSm),
      child: SizedBox(
        height: height,
        child: Row(
          children:
              nonEmpty.map((s) {
                final flex = (s.count * 1000 / total).round().clamp(1, 1000);
                return Expanded(
                  flex: flex,
                  child: Tooltip(
                    message: '${taskStatusDisplayName(s.status)}: ${s.count}',
                    child: InkWell(
                      onTap:
                          onSegmentTap != null
                              ? () => onSegmentTap!(s.status)
                              : null,
                      child: Container(
                        color: taskStatusColor(s.status),
                        alignment: Alignment.center,
                        child:
                            flex > 60
                                ? Text(
                                  '${s.count}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                                : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

/// Legend row shown beneath the pipeline strip.
class PipelineLegend extends StatelessWidget {
  final List<TaskStatusCount> statusCounts;

  const PipelineLegend({super.key, required this.statusCounts});

  @override
  Widget build(BuildContext context) {
    final nonEmpty = statusCounts.where((s) => s.count > 0).toList();
    return Wrap(
      spacing: DashboardTokens.space16,
      runSpacing: DashboardTokens.space8,
      children:
          nonEmpty.map((s) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: taskStatusColor(s.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${taskStatusDisplayName(s.status)} · ${s.count}',
                  style: DashboardTokens.bodySm,
                ),
              ],
            );
          }).toList(),
    );
  }
}

// ── Task row (compact, list-friendly) ────────────────────────────────────

class TaskRow extends StatelessWidget {
  final TaskSummary task;
  final VoidCallback? onTap;
  final bool showPrinter;
  final bool showDueDate;
  final Widget? trailing;

  const TaskRow({
    super.key,
    required this.task,
    this.onTap,
    this.showPrinter = false,
    this.showDueDate = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final overdue =
        task.dueDate != null &&
        DateTime.now().isAfter(task.dueDate!) &&
        task.status != 'completed';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashboardTokens.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DashboardTokens.space12,
          vertical: DashboardTokens.space8,
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: DashboardTokens.space12),
              decoration: BoxDecoration(
                color: taskStatusColor(task.status),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: DashboardTokens.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.projectName,
                    style: DashboardTokens.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showPrinter && task.printerName != null) ...[
              Icon(
                Icons.print_outlined,
                size: 13,
                color: DashboardTokens.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(task.printerName!, style: DashboardTokens.caption),
              const SizedBox(width: DashboardTokens.space16),
            ],
            if (task.unreadCount > 0) ...[
              _UnreadPill(count: task.unreadCount),
              const SizedBox(width: DashboardTokens.space12),
            ],
            if (showDueDate && task.dueDate != null)
              Text(
                _formatDueDate(task.dueDate!),
                style: DashboardTokens.bodySm.copyWith(
                  color:
                      overdue
                          ? DashboardTokens.danger
                          : DashboardTokens.textSecondary,
                  fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            if (trailing != null) ...[
              const SizedBox(width: DashboardTokens.space12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final diff =
        DateTime(
          date.year,
          date.month,
          date.day,
        ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${-diff}d overdue';
    if (diff <= 7) return 'In ${diff}d';
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }
}

class _UnreadPill extends StatelessWidget {
  final int count;
  const _UnreadPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DashboardTokens.info,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A vertically-stacked list of tasks inside a card, with a header count
/// and an empty state fallback.
class TaskListCard extends StatelessWidget {
  final String title;
  final List<TaskSummary> tasks;
  final String emptyMessage;
  final bool showPrinter;
  final int maxVisible;
  final void Function(TaskSummary)? onTaskTap;

  const TaskListCard({
    super.key,
    required this.title,
    required this.tasks,
    this.emptyMessage = 'Nothing here right now',
    this.showPrinter = false,
    this.maxVisible = 6,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final visible = tasks.take(maxVisible).toList();
    final overflow = tasks.length - visible.length;

    return DashboardCard(
      padding: const EdgeInsets.symmetric(vertical: DashboardTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DashboardTokens.space16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: DashboardTokens.cardTitle),
                Text('${tasks.length}', style: DashboardTokens.caption),
              ],
            ),
          ),
          const SizedBox(height: DashboardTokens.space8),
          if (visible.isEmpty)
            DashboardEmptyState(message: emptyMessage)
          else ...[
            ...visible.map(
              (t) => TaskRow(
                task: t,
                showPrinter: showPrinter,
                onTap: onTaskTap != null ? () => onTaskTap!(t) : null,
              ),
            ),
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.only(
                  left: DashboardTokens.space16,
                  top: DashboardTokens.space4,
                ),
                child: Text('+ $overflow more', style: DashboardTokens.bodySm),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Status group (collapsible-style section, non-collapsible in dashboard) ─

class StatusGroupList extends StatelessWidget {
  final List<StatusGroup<TaskSummary>> groups;
  final String emptyMessage;
  final void Function(TaskSummary)? onTaskTap;

  const StatusGroupList({
    super.key,
    required this.groups,
    this.emptyMessage = 'No tasks in this stage right now',
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return DashboardCard(child: DashboardEmptyState(message: emptyMessage));
    }

    return Column(
      children:
          groups.map((group) {
            return Padding(
              padding: const EdgeInsets.only(bottom: DashboardTokens.space16),
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
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: taskStatusColor(group.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: DashboardTokens.space8),
                          Text(
                            taskStatusDisplayName(group.status),
                            style: DashboardTokens.cardTitle,
                          ),
                          const Spacer(),
                          Text(
                            '${group.items.length}',
                            style: DashboardTokens.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DashboardTokens.space8),
                    ...group.items.map(
                      (t) => TaskRow(
                        task: t,
                        onTap: onTaskTap != null ? () => onTaskTap!(t) : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

// ── Printer chip / status grid item ──────────────────────────────────────

class PrinterTile extends StatelessWidget {
  final PrinterSummary printer;
  final VoidCallback? onTap;

  const PrinterTile({super.key, required this.printer, this.onTap});

  Color get _statusColor {
    switch (printer.status) {
      case 'active':
        return printer.currentTaskId != null
            ? DashboardTokens.info
            : DashboardTokens.success;
      case 'maintenance':
        return DashboardTokens.warning;
      case 'offline':
        return DashboardTokens.textTertiary;
      case 'error':
        return DashboardTokens.danger;
      default:
        return DashboardTokens.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashboardTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(DashboardTokens.space16),
        decoration: BoxDecoration(
          color: DashboardTokens.surface,
          borderRadius: BorderRadius.circular(DashboardTokens.radiusMd),
          border: Border.all(color: DashboardTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(printer.statusLabel, style: DashboardTokens.caption),
              ],
            ),
            const SizedBox(height: DashboardTokens.space8),
            Text(
              printer.nickname,
              style: DashboardTokens.cardTitle,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              printer.name,
              style: DashboardTokens.caption,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DashboardTokens.space12),
            if (printer.currentTaskName != null) ...[
              Text(
                'Running',
                style: DashboardTokens.caption.copyWith(
                  color: DashboardTokens.info,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                printer.currentTaskName!,
                style: DashboardTokens.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (printer.utilizationPct / 100).clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: DashboardTokens.surfaceSunken,
                  valueColor: AlwaysStoppedAnimation(_statusColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
