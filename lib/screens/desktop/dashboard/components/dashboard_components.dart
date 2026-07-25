// lib/screens/desktop/dashboard/widgets/dashboard_widgets.dart
//
// Every recipe here is copied from task_list_view.dart, not reinvented:
//   - counter pill        -> _StatusSectionHeader's task-count chip
//   - empty state          -> _EmptyState (icon-in-box + title + subtitle)
//   - error state           -> _ErrorState (same shape, red variant)
//   - hover-reveal button   -> _StatusSectionHeader's add-task button
//   - chevron               -> AnimatedRotation 0 / -0.25turns, 200ms
//   - soft badge/chip       -> color.withOpacity(0.1) bg + 0.3 border
//   - card surface          -> white, slate200 border, shadowSm/Md, r/rLg
//   - row height rhythm     -> _kRowHeight (46) reused for list rows

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/dashboard_models.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';

const double kDashRowHeight = 46.0;

// ── Section header (eyebrow-free — matches task list's direct title style) ─

/// Section title row. task_list_view doesn't use uppercase eyebrows for its
/// section headers (status pills use sentence case, w700, ink2, -0.1 letter
/// spacing) — matching that instead of inventing an eyebrow convention.
class DashSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color? accent;

  const DashSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DashTheme.ink2,
              letterSpacing: -0.1,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            DashCounterPill(count: count!, accent: accent),
          ],
        ],
      ),
    );
  }
}

/// The exact counter-pill recipe from _StatusSectionHeader: rounded-99,
/// slate200 bg, slate500 w700 10px text. Optionally tinted by an accent.
class DashCounterPill extends StatelessWidget {
  final int count;
  final Color? accent;

  const DashCounterPill({super.key, required this.count, this.accent});

  @override
  Widget build(BuildContext context) {
    final tinted = accent != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: tinted ? DashTheme.accentSoft(accent!) : DashTheme.slate200,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: tinted ? accent : DashTheme.slate500,
        ),
      ),
    );
  }
}

// ── Card surface ─────────────────────────────────────────────────────────

class DashCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;

  const DashCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DashTheme.white,
        borderRadius: BorderRadius.circular(DashTheme.rLg),
        border: Border.all(color: DashTheme.slate200),
        boxShadow: [elevated ? DashTheme.shadowMd : DashTheme.shadowSm],
      ),
      child: child,
    );
  }
}

// ── Empty / error states — copied from _EmptyState / _ErrorState ─────────

class DashEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? tint;

  const DashEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = tint ?? DashTheme.slate400;
    final bgColor =
        tint != null ? DashTheme.accentSoft(tint!) : DashTheme.slate100;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DashTheme.ink3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: DashTheme.slate400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DashErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const DashErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: DashTheme.red50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 28,
              color: DashTheme.red,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Failed to load dashboard',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DashTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: DashTheme.slate500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DashTheme.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI tile ─────────────────────────────────────────────────────────────
//
// Not present verbatim in task_list_view (it has no KPI concept), so this
// is new — but built strictly from existing tokens: card surface recipe,
// soft-badge icon chip, ink/slate type scale, tight negative letter-spacing
// on the big number to match the title's -0.1..-0.3 convention.

class DashKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool alert;

  const DashKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = alert ? DashTheme.red : accent;
    return DashCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: DashTheme.accentSoft(color),
                  borderRadius: BorderRadius.circular(DashTheme.r),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              if (alert)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: DashTheme.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.05,
              color: DashTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: DashTheme.slate500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pipeline strip — signature element, built from status colors + pills ──

class PipelineStrip extends StatelessWidget {
  final List<TaskStatusCount> statusCounts;
  final void Function(String status)? onSegmentTap;

  const PipelineStrip({
    super.key,
    required this.statusCounts,
    this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = statusCounts.fold<int>(0, (sum, s) => sum + s.count);
    final nonEmpty = statusCounts.where((s) => s.count > 0).toList();

    if (total == 0 || nonEmpty.isEmpty) {
      return Container(
        height: 38,
        decoration: BoxDecoration(
          color: DashTheme.slate100,
          borderRadius: BorderRadius.circular(DashTheme.r),
        ),
        alignment: Alignment.center,
        child: const Text(
          'No active tasks in the pipeline',
          style: TextStyle(fontSize: 12, color: DashTheme.slate400),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(DashTheme.r),
      child: SizedBox(
        height: 38,
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
                            flex > 55
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

class PipelineLegend extends StatelessWidget {
  final List<TaskStatusCount> statusCounts;
  const PipelineLegend({super.key, required this.statusCounts});

  @override
  Widget build(BuildContext context) {
    final nonEmpty = statusCounts.where((s) => s.count > 0).toList();
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children:
          nonEmpty.map((s) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: taskStatusColor(s.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${taskStatusDisplayName(s.status)} · ${s.count}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DashTheme.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }
}

// ── Task row ──────────────────────────────────────────────────────────────
//
// Built at kDashRowHeight (46 — same rhythm as _kRowHeight), hover-tinted
// with the app's exact hoverBg/hoverBorder, status dot instead of a full
// column, due-date chip using the same soft-badge recipe.

class DashTaskRow extends StatefulWidget {
  final TaskSummary task;
  final VoidCallback? onTap;
  final bool showPrinter;
  final Widget? trailing;

  const DashTaskRow({
    super.key,
    required this.task,
    this.onTap,
    this.showPrinter = false,
    this.trailing,
  });

  @override
  State<DashTaskRow> createState() => _DashTaskRowState();
}

class _DashTaskRowState extends State<DashTaskRow> {
  bool _hovered = false;

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

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final overdue =
        task.dueDate != null &&
        DateTime.now().isAfter(task.dueDate!) &&
        task.status != 'completed';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: kDashRowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hovered ? DashTheme.hoverBg : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: DashTheme.colDivider, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 11),
                decoration: BoxDecoration(
                  color: taskStatusColor(task.status),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DashTheme.ink3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.projectName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: DashTheme.slate400,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.showPrinter && task.printerName != null) ...[
                const Icon(
                  Icons.print_outlined,
                  size: 13,
                  color: DashTheme.slate400,
                ),
                const SizedBox(width: 4),
                Text(
                  task.printerName!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: DashTheme.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              if (task.unreadCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DashTheme.blue,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${task.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (task.dueDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: overdue ? DashTheme.red50 : DashTheme.slate100,
                    borderRadius: BorderRadius.circular(99),
                    border:
                        overdue
                            ? Border.all(color: DashTheme.red.withOpacity(0.3))
                            : null,
                  ),
                  child: Text(
                    _formatDueDate(task.dueDate!),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: overdue ? DashTheme.red : DashTheme.slate500,
                    ),
                  ),
                ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Card wrapping a titled list of task rows, with the counter-pill header
/// and empty state baked in.
class DashTaskListCard extends StatelessWidget {
  final String title;
  final List<TaskSummary> tasks;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final bool showPrinter;
  final int maxVisible;
  final Color? accent;
  final void Function(TaskSummary)? onTaskTap;

  const DashTaskListCard({
    super.key,
    required this.title,
    required this.tasks,
    this.emptyTitle = 'Nothing here',
    this.emptySubtitle = 'This list is clear for now',
    this.emptyIcon = Icons.inbox_outlined,
    this.showPrinter = false,
    this.maxVisible = 6,
    this.accent,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final visible = tasks.take(maxVisible).toList();
    final overflow = tasks.length - visible.length;

    return DashCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DashTheme.ink2,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 8),
                DashCounterPill(count: tasks.length, accent: accent),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (visible.isEmpty)
            DashEmptyState(
              title: emptyTitle,
              subtitle: emptySubtitle,
              icon: emptyIcon,
              tint: accent,
            )
          else ...[
            ...visible.map(
              (t) => DashTaskRow(
                task: t,
                showPrinter: showPrinter,
                onTap: onTaskTap != null ? () => onTaskTap!(t) : null,
              ),
            ),
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 8),
                child: Text(
                  '+ $overflow more',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DashTheme.slate400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Status group section — collapsible header matching _StatusSectionHeader ─

class DashStatusGroupSection extends StatefulWidget {
  final StatusGroup<TaskSummary> group;
  final void Function(TaskSummary)? onTaskTap;
  final bool initiallyExpanded;

  const DashStatusGroupSection({
    super.key,
    required this.group,
    this.onTaskTap,
    this.initiallyExpanded = true,
  });

  @override
  State<DashStatusGroupSection> createState() => _DashStatusGroupSectionState();
}

class _DashStatusGroupSectionState extends State<DashStatusGroupSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final color = taskStatusColor(widget.group.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DashCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  height: kDashRowHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: DashTheme.slate50,
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(DashTheme.rLg),
                      bottom:
                          _expanded
                              ? Radius.zero
                              : const Radius.circular(DashTheme.rLg),
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0.0 : -0.25,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: DashTheme.slate600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        taskStatusDisplayName(widget.group.status),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: DashTheme.ink2,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DashCounterPill(
                        count: widget.group.items.length,
                        accent: color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState:
                  _expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
              firstChild: Column(
                children:
                    widget.group.items
                        .map(
                          (t) => DashTaskRow(
                            task: t,
                            onTap:
                                widget.onTaskTap != null
                                    ? () => widget.onTaskTap!(t)
                                    : null,
                          ),
                        )
                        .toList(),
              ),
              secondChild: const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class DashStatusGroupList extends StatelessWidget {
  final List<StatusGroup<TaskSummary>> groups;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(TaskSummary)? onTaskTap;

  const DashStatusGroupList({
    super.key,
    required this.groups,
    this.emptyTitle = 'Nothing queued',
    this.emptySubtitle = 'No tasks in this stage right now',
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return DashCard(
        child: DashEmptyState(title: emptyTitle, subtitle: emptySubtitle),
      );
    }
    return Column(
      children:
          groups
              .map(
                (g) => DashStatusGroupSection(group: g, onTaskTap: onTaskTap),
              )
              .toList(),
    );
  }
}

// ── Printer tile ──────────────────────────────────────────────────────────

class DashPrinterTile extends StatelessWidget {
  final PrinterSummary printer;
  final VoidCallback? onTap;

  const DashPrinterTile({super.key, required this.printer, this.onTap});

  Color get _statusColor {
    switch (printer.status) {
      case 'active':
        return printer.currentTaskId != null ? DashTheme.blue : DashTheme.green;
      case 'maintenance':
        return DashTheme.amber;
      case 'offline':
        return DashTheme.slate400;
      case 'error':
        return DashTheme.red;
      default:
        return DashTheme.slate400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashTheme.rLg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DashTheme.white,
          borderRadius: BorderRadius.circular(DashTheme.rLg),
          border: Border.all(color: DashTheme.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DashTheme.accentSoft(color),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: DashTheme.accentBorder(color)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        printer.statusLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              printer.nickname,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: DashTheme.ink2,
                letterSpacing: -0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              printer.name,
              style: const TextStyle(
                fontSize: 11,
                color: DashTheme.slate400,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (printer.currentTaskName != null) ...[
              Text(
                'RUNNING',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: DashTheme.blue,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                printer.currentTaskName!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DashTheme.ink3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (printer.utilizationPct / 100).clamp(0, 1),
                  minHeight: 4,
                  backgroundColor: DashTheme.slate100,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Soft label chip — for "AWAITING CLIENT", "MISSING SPEC" style tags ────

class DashLabelChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const DashLabelChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
