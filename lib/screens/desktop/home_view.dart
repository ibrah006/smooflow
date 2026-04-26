// ═════════════════════════════════════════════════════════════════════════════
// SMOOFLOW — HOME / DASHBOARD VIEW
// Desktop-optimised. Matches the inbox design system exactly.
// ═════════════════════════════════════════════════════════════════════════════
//
// Sections
//   1. _T                — design tokens (exact match with inbox)
//   2. HomeView          — root widget + staggered mount animation
//   3. _HomeTopBar       — greeting, date, quick-create button
//   4. _StatsRow         — four KPI cards (active / completed / review / overdue)
//   5. _MainGrid         — two-column body
//      ├ _MyTasksPanel   — left: scrollable task list grouped by priority
//      └ _RightColumn    — right: pipeline snapshot + mini activity feed
//   6. _PipelineSnapshot — stage funnel bar
//   7. _ActivityFeedPanel— compact recent-activity list
//   8. Shared small widgets (pill, avatar chip, hover card shell, etc.)
//
// Replace placeholder providers / models with your real ones.
// ═════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (verbatim from inbox_view.dart — single source of truth)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const teal = Color(0xFF38BDF8);
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);
  static const indigo = Color(0xFF6366F1);
  static const indigo50 = Color(0xFFEEF2FF);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
  static const topbarH = 60.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACEHOLDER DATA MODELS
// Replace with your real providers / models.
// ─────────────────────────────────────────────────────────────────────────────

class _TaskItem {
  final int id;
  final String name;
  final String stage; // TaskStatus.name
  final int priority; // 1=normal, 2=high, 3=urgent
  final DateTime? dueDate;
  final String? assigneeInitials;
  final Color? assigneeColor;

  const _TaskItem({
    required this.id,
    required this.name,
    required this.stage,
    required this.priority,
    this.dueDate,
    this.assigneeInitials,
    this.assigneeColor,
  });
}

class _ActivityItem {
  final String actorInitials;
  final Color actorColor;
  final String verb;
  final String taskName;
  final DateTime timestamp;
  final Color accent;

  const _ActivityItem({
    required this.actorInitials,
    required this.actorColor,
    required this.verb,
    required this.taskName,
    required this.timestamp,
    required this.accent,
  });
}

// ── Sample data (remove once wired to real providers) ───────────────────────
final _sampleTasks = <_TaskItem>[
  _TaskItem(
    id: 101,
    name: 'Wedding Invitation Suite',
    stage: 'review',
    priority: 3,
    dueDate: DateTime.now().add(const Duration(hours: 4)),
    assigneeInitials: 'AL',
    assigneeColor: const Color(0xFF6366F1),
  ),
  _TaskItem(
    id: 102,
    name: 'Corporate Letterhead Pack',
    stage: 'design',
    priority: 2,
    dueDate: DateTime.now().add(const Duration(hours: 9)),
    assigneeInitials: 'MR',
    assigneeColor: const Color(0xFF10B981),
  ),
  _TaskItem(
    id: 103,
    name: 'Product Catalogue Vol. 3',
    stage: 'printing',
    priority: 3,
    dueDate: DateTime.now().add(const Duration(hours: 2)),
    assigneeInitials: 'JT',
    assigneeColor: const Color(0xFFF59E0B),
  ),
  _TaskItem(
    id: 104,
    name: 'Event Banner 3m×1m',
    stage: 'approved',
    priority: 1,
    dueDate: DateTime.now().add(const Duration(days: 1)),
    assigneeInitials: 'CK',
    assigneeColor: const Color(0xFFEF4444),
  ),
  _TaskItem(
    id: 105,
    name: 'Loyalty Card Reprint',
    stage: 'submitted',
    priority: 1,
    dueDate: DateTime.now().add(const Duration(days: 2)),
  ),
  _TaskItem(
    id: 106,
    name: 'Restaurant Menu Update',
    stage: 'design',
    priority: 2,
    dueDate: DateTime.now().add(const Duration(days: 1)),
    assigneeInitials: 'AL',
    assigneeColor: const Color(0xFF6366F1),
  ),
  _TaskItem(
    id: 107,
    name: 'Flyer Batch — May Sale',
    stage: 'review',
    priority: 2,
    dueDate: DateTime.now().subtract(const Duration(hours: 3)),
    assigneeInitials: 'MR',
    assigneeColor: const Color(0xFF10B981),
  ),
];

final _sampleActivity = <_ActivityItem>[
  _ActivityItem(
    actorInitials: 'AL',
    actorColor: const Color(0xFF6366F1),
    verb: 'advanced',
    taskName: 'Wedding Invitation Suite',
    timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    accent: _T.green,
  ),
  _ActivityItem(
    actorInitials: 'JT',
    actorColor: const Color(0xFFF59E0B),
    verb: 'started print',
    taskName: 'Product Catalogue Vol. 3',
    timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
    accent: _T.blue,
  ),
  _ActivityItem(
    actorInitials: 'MR',
    actorColor: const Color(0xFF10B981),
    verb: 'commented on',
    taskName: 'Corporate Letterhead Pack',
    timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
    accent: _T.purple,
  ),
  _ActivityItem(
    actorInitials: 'CK',
    actorColor: const Color(0xFFEF4444),
    verb: 'approved',
    taskName: 'Event Banner 3m×1m',
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    accent: _T.green,
  ),
  _ActivityItem(
    actorInitials: 'AL',
    actorColor: const Color(0xFF6366F1),
    verb: 'moved back',
    taskName: 'Flyer Batch — May Sale',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    accent: _T.amber,
  ),
];

// Stage display meta (order matters — defines pipeline left-to-right)
const _stagesMeta = <Map<String, dynamic>>[
  {
    'name': 'submitted',
    'label': 'Submitted',
    'color': _T.slate400,
    'bg': _T.slate100,
  },
  {'name': 'design', 'label': 'Design', 'color': _T.indigo, 'bg': _T.indigo50},
  {'name': 'review', 'label': 'Review', 'color': _T.amber, 'bg': _T.amber50},
  {
    'name': 'approved',
    'label': 'Approved',
    'color': _T.green,
    'bg': _T.green50,
  },
  {'name': 'printing', 'label': 'Printing', 'color': _T.blue, 'bg': _T.blue50},
  {
    'name': 'completed',
    'label': 'Completed',
    'color': _T.purple,
    'bg': _T.purple50,
  },
];

// ═════════════════════════════════════════════════════════════════════════════
// HOME VIEW
// ═════════════════════════════════════════════════════════════════════════════
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _mountCtrl;

  @override
  void initState() {
    super.initState();
    _mountCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _mountCtrl.dispose();
    super.dispose();
  }

  /// Returns a staggered fade+slide animation for a given slot (0-based).
  Animation<double> _fade(int slot) => CurvedAnimation(
    parent: _mountCtrl,
    curve: Interval(slot * 0.08, (slot * 0.08) + 0.55, curve: Curves.easeOut),
  );

  @override
  Widget build(BuildContext context) {
    // Determine greeting from time of day
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12
            ? 'Good morning'
            : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final userName =
        LoginService.currentUser?.name?.split(' ').first ?? 'there';

    // Derive stats from sample data (wire to real provider later)
    final activeTasks =
        _sampleTasks.where((t) => t.stage != 'completed').length;
    final completedToday = 2; // placeholder
    final pendingReview = _sampleTasks.where((t) => t.stage == 'review').length;
    final overdueTasks =
        _sampleTasks.where((t) {
          return t.dueDate != null &&
              t.dueDate!.isBefore(DateTime.now()) &&
              t.stage != 'completed';
        }).length;

    return Container(
      color: _T.slate50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top bar ───────────────────────────────────────────────────────
          // FadeTransition(
          //   opacity: _fade(0),
          //   child: HomeTopBar(greeting: greeting, userName: userName),
          // ),

          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats row
                  FadeTransition(
                    opacity: _fade(1),
                    child: _StatsRow(
                      activeTasks: activeTasks,
                      completedToday: completedToday,
                      pendingReview: pendingReview,
                      overdueTasks: overdueTasks,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Main two-column grid
                  FadeTransition(
                    opacity: _fade(2),
                    child: _MainGrid(
                      tasks: _sampleTasks,
                      activity: _sampleActivity,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STATS ROW — four KPI cards
// ═════════════════════════════════════════════════════════════════════════════
class _StatsRow extends StatelessWidget {
  final int activeTasks;
  final int completedToday;
  final int pendingReview;
  final int overdueTasks;

  const _StatsRow({
    required this.activeTasks,
    required this.completedToday,
    required this.pendingReview,
    required this.overdueTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Active Tasks',
            value: '$activeTasks',
            icon: Icons.layers_outlined,
            accent: _T.blue,
            accentBg: _T.blue50,
            trend: '+2 this week',
            trendUp: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Completed Today',
            value: '$completedToday',
            icon: Icons.check_circle_outline_rounded,
            accent: _T.green,
            accentBg: _T.green50,
            trend: 'on track',
            trendUp: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Pending Review',
            value: '$pendingReview',
            icon: Icons.rate_review_outlined,
            accent: _T.amber,
            accentBg: _T.amber50,
            trend: 'needs attention',
            trendUp: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Overdue',
            value: '$overdueTasks',
            icon: Icons.warning_amber_rounded,
            accent: overdueTasks > 0 ? _T.red : _T.slate400,
            accentBg: overdueTasks > 0 ? _T.red50 : _T.slate100,
            trend: overdueTasks > 0 ? 'action required' : 'all clear',
            trendUp: overdueTasks == 0,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color accentBg;
  final String trend;
  final bool trendUp;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.accentBg,
    required this.trend,
    required this.trendUp,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rXl),
          border: Border.all(
            color: _hovered ? widget.accent.withOpacity(0.35) : _T.slate200,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  _hovered
                      ? widget.accent.withOpacity(0.08)
                      : const Color(0x080F172A),
              blurRadius: _hovered ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + label row
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _hovered ? widget.accent : widget.accentBg,
                    borderRadius: BorderRadius.circular(_T.r),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 17,
                    color: _hovered ? Colors.white : widget.accent,
                  ),
                ),
                const Spacer(),
                // Trend badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: widget.trendUp ? _T.green50 : _T.red50,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.trendUp
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 9,
                        color: widget.trendUp ? _T.green : _T.red,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.trend,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: widget.trendUp ? _T.green : _T.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Big number
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: _hovered ? widget.accent : _T.ink,
                height: 1,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: _T.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MAIN GRID — left (tasks) + right column
// ═════════════════════════════════════════════════════════════════════════════
class _MainGrid extends StatelessWidget {
  final List<_TaskItem> tasks;
  final List<_ActivityItem> activity;

  const _MainGrid({required this.tasks, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: My Tasks (wider) ─────────────────────────────────────────
        Expanded(flex: 58, child: _MyTasksPanel(tasks: tasks)),

        const SizedBox(width: 16),

        // ── Right column ───────────────────────────────────────────────────
        Expanded(
          flex: 42,
          child: Column(
            children: [
              _PipelineSnapshot(tasks: tasks),
              const SizedBox(height: 16),
              _ActivityFeedPanel(items: activity),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MY TASKS PANEL
// ═════════════════════════════════════════════════════════════════════════════
class _MyTasksPanel extends StatefulWidget {
  final List<_TaskItem> tasks;
  const _MyTasksPanel({required this.tasks});

  @override
  State<_MyTasksPanel> createState() => _MyTasksPanelState();
}

class _MyTasksPanelState extends State<_MyTasksPanel> {
  String _filter = 'all'; // 'all' | 'urgent' | 'overdue'

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final filtered =
        widget.tasks.where((t) {
          if (_filter == 'urgent') return t.priority == 3;
          if (_filter == 'overdue')
            return t.dueDate != null && t.dueDate!.isBefore(now);
          return true;
        }).toList();

    return _PanelShell(
      header: Row(
        children: [
          const _PanelIcon(
            icon: Icons.checklist_rounded,
            color: _T.blue,
            bg: _T.blue50,
          ),
          const SizedBox(width: 10),
          const Text(
            'My Tasks',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _T.ink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _T.blue50,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${filtered.length}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _T.blue,
              ),
            ),
          ),
          const Spacer(),
          // Filter chips
          _FilterChip(
            label: 'All',
            value: 'all',
            current: _filter,
            onTap: (v) => setState(() => _filter = v),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Urgent',
            value: 'urgent',
            current: _filter,
            onTap: (v) => setState(() => _filter = v),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Overdue',
            value: 'overdue',
            current: _filter,
            onTap: (v) => setState(() => _filter = v),
          ),
        ],
      ),
      child:
          filtered.isEmpty
              ? _EmptySlot(
                icon: Icons.task_alt_rounded,
                message: 'No tasks match this filter.',
              )
              : Column(
                children: [
                  for (int i = 0; i < filtered.length; i++) ...[
                    _TaskRow(
                      task: filtered[i],
                      isLast: i == filtered.length - 1,
                    ),
                  ],
                ],
              ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TASK ROW
// ─────────────────────────────────────────────────────────────────────────────
class _TaskRow extends StatefulWidget {
  final _TaskItem task;
  final bool isLast;

  const _TaskRow({required this.task, required this.isLast});

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _hovered = false;

  Color get _stageColor {
    for (final s in _stagesMeta) {
      if (s['name'] == widget.task.stage) return s['color'] as Color;
    }
    return _T.slate400;
  }

  Color get _stageBg {
    for (final s in _stagesMeta) {
      if (s['name'] == widget.task.stage) return s['bg'] as Color;
    }
    return _T.slate100;
  }

  String get _stageLabel {
    for (final s in _stagesMeta) {
      if (s['name'] == widget.task.stage) return s['label'] as String;
    }
    return widget.task.stage;
  }

  Color get _priorityColor {
    switch (widget.task.priority) {
      case 3:
        return _T.red;
      case 2:
        return _T.amber;
      default:
        return _T.slate400;
    }
  }

  bool get _isOverdue =>
      widget.task.dueDate != null &&
      widget.task.dueDate!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final t = widget.task;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        decoration: BoxDecoration(
          color: _hovered ? _T.slate50 : Colors.white,
          borderRadius: BorderRadius.circular(_T.r),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 11),
              child: Row(
                children: [
                  // Priority accent bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    width: 3,
                    height: 38,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color:
                          _hovered
                              ? _priorityColor
                              : _priorityColor.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Task name + due date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _hovered ? _T.blue : _T.ink2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (t.dueDate != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: _isOverdue ? _T.red : _T.slate400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDue(t.dueDate!),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _isOverdue ? _T.red : _T.slate400,
                                ),
                              ),
                              if (_isOverdue) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _T.red50,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'OVERDUE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: _T.red,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Stage pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _stageBg,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _stageColor.withOpacity(0.25)),
                    ),
                    child: Text(
                      _stageLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _stageColor,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Assignee avatar (or placeholder circle)
                  if (t.assigneeInitials != null)
                    AvatarWidget(
                      initials: t.assigneeInitials!,
                      color: t.assigneeColor ?? _T.ink3,
                      size: 26,
                    )
                  else
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _T.slate100,
                        shape: BoxShape.circle,
                        border: Border.all(color: _T.slate200, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: _T.slate300,
                      ),
                    ),

                  // Hover: open-in-new icon
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _hovered ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: _T.blue.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.isLast)
              const Divider(height: 1, indent: 15, color: _T.slate100),
          ],
        ),
      ),
    );
  }

  String _formatDue(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (_isOverdue) {
      final ago = now.difference(dt);
      if (ago.inHours < 24) return 'Due ${ago.inHours}h ago';
      return 'Due ${ago.inDays}d ago';
    }
    if (diff.inHours < 1) return 'Due in ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Due in ${diff.inHours}h';
    return 'Due in ${diff.inDays}d';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PIPELINE SNAPSHOT
// A horizontal funnel: one segment per stage, width = proportional task count
// ═════════════════════════════════════════════════════════════════════════════
class _PipelineSnapshot extends StatelessWidget {
  final List<_TaskItem> tasks;
  const _PipelineSnapshot({required this.tasks});

  @override
  Widget build(BuildContext context) {
    // Count tasks per stage
    final counts = <String, int>{};
    for (final s in _stagesMeta) {
      counts[s['name'] as String] =
          tasks.where((t) => t.stage == s['name']).length;
    }
    final total = tasks.isEmpty ? 1 : tasks.length;

    return _PanelShell(
      header: Row(
        children: [
          const _PanelIcon(
            icon: Icons.account_tree_outlined,
            color: _T.indigo,
            bg: _T.indigo50,
          ),
          const SizedBox(width: 10),
          const Text(
            'Pipeline',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _T.ink,
            ),
          ),
          const Spacer(),
          Text(
            '${tasks.length} tasks total',
            style: const TextStyle(
              fontSize: 12,
              color: _T.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Funnel bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (int i = 0; i < _stagesMeta.length; i++) ...[
                    Flexible(
                      flex: ((counts[_stagesMeta[i]['name']] ?? 0) /
                              total *
                              1000)
                          .round()
                          .clamp(1, 1000),
                      child: Container(
                        color: (_stagesMeta[i]['color'] as Color).withOpacity(
                          0.75,
                        ),
                      ),
                    ),
                    if (i < _stagesMeta.length - 1) const SizedBox(width: 2),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stage legend grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in _stagesMeta)
                _StageLegendChip(
                  label: s['label'] as String,
                  count: counts[s['name']] ?? 0,
                  color: s['color'] as Color,
                  bg: s['bg'] as Color,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageLegendChip extends StatefulWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;

  const _StageLegendChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
  });

  @override
  State<_StageLegendChip> createState() => _StageLegendChipState();
}

class _StageLegendChipState extends State<_StageLegendChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _hovered ? widget.color : widget.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _hovered ? widget.color : widget.color.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _hovered ? Colors.white : widget.color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color:
                    _hovered
                        ? Colors.white.withOpacity(0.25)
                        : widget.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.count}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _hovered ? Colors.white : widget.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ACTIVITY FEED PANEL
// ═════════════════════════════════════════════════════════════════════════════
class _ActivityFeedPanel extends StatelessWidget {
  final List<_ActivityItem> items;
  const _ActivityFeedPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      header: Row(
        children: [
          const _PanelIcon(
            icon: Icons.bolt_rounded,
            color: _T.amber,
            bg: _T.amber50,
          ),
          const SizedBox(width: 10),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _T.ink,
            ),
          ),
          const Spacer(),
          _TextButton(label: 'View all', onTap: () {}),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            _ActivityRow(item: items[i], isLast: i == items.length - 1),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatefulWidget {
  final _ActivityItem item;
  final bool isLast;
  const _ActivityRow({required this.item, required this.isLast});

  @override
  State<_ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<_ActivityRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final minutesAgo = DateTime.now().difference(item.timestamp).inMinutes;
    final timeLabel =
        minutesAgo < 1
            ? 'just now'
            : minutesAgo < 60
            ? '${minutesAgo}m ago'
            : '${(minutesAgo / 60).floor()}h ago';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? _T.slate50 : Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot + line
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: item.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!widget.isLast)
                          Container(
                            width: 1.5,
                            height: 28,
                            margin: const EdgeInsets.only(top: 3),
                            color: _T.slate200,
                          ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _T.ink2,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    item.actorInitials, // In real code: actorName
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: ' ${item.verb} ',
                                style: const TextStyle(color: _T.slate500),
                              ),
                              TextSpan(
                                text: item.taskName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _T.ink3,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _T.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: AvatarWidget(
                      initials: item.actorInitials,
                      color: item.actorColor,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.isLast)
              const SizedBox.shrink(), // line is handled by timeline column
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

/// Consistent card shell with a header slot and a body slot.
class _PanelShell extends StatelessWidget {
  final Widget header;
  final Widget child;

  const _PanelShell({required this.header, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate100)),
            ),
            child: header,
          ),
          // Body
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

/// Small rounded icon widget used in panel headers.
class _PanelIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;

  const _PanelIcon({required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 15, color: color),
    );
  }
}

/// Segmented filter chip.
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final void Function(String) onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = current == value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active ? _T.blue : _T.slate100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : _T.slate500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ghost text button (used for "View all" links).
class _TextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _TextButton({required this.label, required this.onTap});

  @override
  State<_TextButton> createState() => _TextButtonState();
}

class _TextButtonState extends State<_TextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _hovered ? _T.blue : _T.slate400,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_forward_rounded,
              size: 12,
              color: _hovered ? _T.blue : _T.slate300,
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty slot placeholder (used inside panels).
class _EmptySlot extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptySlot({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 28, color: _T.slate200),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12.5,
              color: _T.slate300,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
