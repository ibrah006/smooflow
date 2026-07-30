import 'package:flutter/material.dart';

class _T {
  static const blue = Color(0xFF2563EB);
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;
  static const r = 6.0;
  static const rLg = 12.0;

  static final shadowLg = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 20,
    offset: const Offset(0, 6),
  );
  static final shadowSm = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 4,
    offset: const Offset(0, 1),
  );
}

/// Active filter state.
///
/// `statuses` still holds every raw status string (including 'blocked' and
/// 'revision') so downstream filtering logic that already reads
/// `filter.statuses` keeps working unchanged. `overdueOnly` and
/// `incompleteOnly` are separate booleans because "overdue" (due-date based)
/// and "incomplete" (not yet delivered) aren't statuses in their own right.
class TaskFilterState {
  final Set<String> statuses; // empty = show all
  final Set<int> priorities; // empty = show all (0=normal, 1=high, 2=urgent)
  final bool overdueOnly;
  final bool incompleteOnly;

  const TaskFilterState({
    Set<String>? statuses,
    Set<int>? priorities,
    this.overdueOnly = false,
    this.incompleteOnly = false,
  }) : statuses = statuses ?? const {},
       priorities = priorities ?? const {};

  bool get isActive =>
      statuses.isNotEmpty ||
      priorities.isNotEmpty ||
      overdueOnly ||
      incompleteOnly;

  /// Total number of independently-toggled filters, used for the badge count.
  int get activeCount =>
      statuses.length +
      priorities.length +
      (overdueOnly ? 1 : 0) +
      (incompleteOnly ? 1 : 0);

  bool get isBlocked => statuses.contains('blocked');
  bool get isRevision => statuses.contains('revision');

  TaskFilterState copyWith({
    Set<String>? statuses,
    Set<int>? priorities,
    bool? overdueOnly,
    bool? incompleteOnly,
  }) => TaskFilterState(
    statuses: statuses ?? this.statuses,
    priorities: priorities ?? this.priorities,
    overdueOnly: overdueOnly ?? this.overdueOnly,
    incompleteOnly: incompleteOnly ?? this.incompleteOnly,
  );

  TaskFilterState toggleStatus(String status) {
    final updated = Set<String>.from(statuses);
    if (updated.contains(status)) {
      updated.remove(status);
    } else {
      updated.add(status);
    }
    return copyWith(statuses: updated);
  }

  TaskFilterState togglePriority(int priority) {
    final updated = Set<int>.from(priorities);
    if (updated.contains(priority)) {
      updated.remove(priority);
    } else {
      updated.add(priority);
    }
    return copyWith(priorities: updated);
  }

  TaskFilterState toggleOverdue() => copyWith(overdueOnly: !overdueOnly);

  TaskFilterState toggleIncomplete() =>
      copyWith(incompleteOnly: !incompleteOnly);

  TaskFilterState toggleBlocked() => toggleStatus('blocked');

  TaskFilterState toggleRevision() => toggleStatus('revision');

  TaskFilterState reset() => const TaskFilterState();
}

/// Filter button matching _ColumnPickerButton's chrome and animations.
class TaskFilterButton extends StatefulWidget {
  final TaskFilterState filter;
  final void Function(TaskFilterState) onFilter;

  const TaskFilterButton({required this.filter, required this.onFilter});

  @override
  State<TaskFilterButton> createState() => _TaskFilterButtonState();
}

class _TaskFilterButtonState extends State<TaskFilterButton>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;
  late TaskFilterState _overlayFilter;

  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 190),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ac,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.05),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _overlayFilter = widget.filter;
  }

  @override
  void didUpdateWidget(TaskFilterButton old) {
    super.didUpdateWidget(old);
    _overlayFilter = widget.filter;
    if (_open) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? _overlay?.markNeedsBuild() : null,
      );
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _ac.dispose();
    super.dispose();
  }

  void _toggle() => _open ? _close() : _show();

  void _show() {
    _overlayFilter = widget.filter;
    setState(() => _open = true);
    _overlay = _buildOverlay();
    Overlay.of(context).insert(_overlay!);
    _ac.forward(from: 0);
  }

  Future<void> _close() async {
    await _ac.reverse();
    _removeOverlay();
    if (mounted) setState(() => _open = false);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _updateOverlayFilter(TaskFilterState updated) {
    _overlayFilter = updated;
    _overlay?.markNeedsBuild();
  }

  OverlayEntry _buildOverlay() => OverlayEntry(
    builder:
        (_) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 6),
              child: AnimatedBuilder(
                animation: _ac,
                builder:
                    (_, child) => FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(position: _slide, child: child),
                    ),
                child: _TaskFilterPanel(
                  filter: _overlayFilter,
                  onFilterChange: _updateOverlayFilter,
                  onApply: (filter) {
                    widget.onFilter(filter);
                    _close();
                  },
                  onReset: () {
                    widget.onFilter(const TaskFilterState());
                    _close();
                  },
                ),
              ),
            ),
          ],
        ),
  );

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:
                  _open
                      ? _T.slate100
                      : (widget.filter.isActive ? _T.blue50 : _T.white),
              border: Border.all(
                color:
                    _open
                        ? _T.slate300
                        : (widget.filter.isActive
                            ? _T.blue.withOpacity(0.3)
                            : _T.slate200),
              ),
              borderRadius: BorderRadius.circular(_T.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_outlined,
                  size: 14,
                  color:
                      _open || widget.filter.isActive ? _T.blue : _T.slate400,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _open || widget.filter.isActive ? _T.blue : _T.ink3,
                  ),
                ),
                if (widget.filter.isActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _T.blue,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${widget.filter.activeCount}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 190),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: _T.slate400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter panel.
///
/// Layout, top to bottom:
///   1. Header ("Filter tasks" + Reset)
///   2. Quick filters — the common, single-tap cases (Overdue, Incomplete,
///      Blocked, In Revision) as recognizable icon cards.
///   3. Priority — a compact row of severity chips.
///   4. Status (advanced) — collapsed by default, grouped by phase, for the
///      rare case someone wants to filter to a specific pipeline step.
///   5. Footer — Clear all / Apply, so edits are previewed and only take
///      effect on Apply (nothing changes on the board until you commit).
class _TaskFilterPanel extends StatefulWidget {
  final TaskFilterState filter;
  final void Function(TaskFilterState) onFilterChange;
  final void Function(TaskFilterState) onApply;
  final VoidCallback onReset;

  const _TaskFilterPanel({
    required this.filter,
    required this.onFilterChange,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_TaskFilterPanel> createState() => _TaskFilterPanelState();
}

class _TaskFilterPanelState extends State<_TaskFilterPanel> {
  bool _statusExpanded = false;

  // Design-phase statuses.
  static const List<(String, String)> designStatusOptions = [
    ('pending', 'Initialized'),
    ('designing', 'Designing'),
    ('waitingApproval', 'Waiting Approval'),
    ('clientApproved', 'Client Approved'),
    ('waitingPrinting', 'Waiting Printing'),
  ];

  // Production-phase statuses.
  static const List<(String, String)> productionStatusOptions = [
    ('printing', 'Printing'),
    ('printingCompleted', 'Printing Completed'),
    ('finishing', 'Finishing'),
    ('productionCompleted', 'Production Completed'),
    ('waitingDelivery', 'Waiting Delivery'),
    ('delivery', 'Delivery'),
    ('delivered', 'Delivered'),
  ];

  // Everything else. 'blocked' and 'revision' are deliberately excluded here
  // — they already have dedicated quick-filter cards above.
  static const List<(String, String)> otherStatusOptions = [
    ('paused', 'Paused'),
  ];

  static const List<(int, String)> priorityOptions = [
    (0, 'Normal'),
    (1, 'High'),
    (2, 'Urgent'),
  ];

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_T.rLg),
      child: Container(
        width: 368,
        constraints: const BoxConstraints(maxHeight: 620),
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(_T.rLg),
          border: Border.all(color: _T.slate200),
          boxShadow: [_T.shadowLg, _T.shadowSm],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _T.slate100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter tasks',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _T.ink2,
                    ),
                  ),
                  if (filter.isActive)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: widget.onReset,
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _T.blue,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('QUICK FILTERS'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickFilterCard(
                            icon: Icons.schedule_rounded,
                            label: 'Overdue',
                            caption: 'Past due date',
                            accent: _T.red,
                            accentTint: _T.red50,
                            selected: filter.overdueOnly,
                            onTap:
                                () => widget.onFilterChange(
                                  filter.toggleOverdue(),
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickFilterCard(
                            icon: Icons.pending_actions_rounded,
                            label: 'Incomplete',
                            caption: 'Not yet delivered',
                            accent: _T.blue,
                            accentTint: _T.blue50,
                            selected: filter.incompleteOnly,
                            onTap:
                                () => widget.onFilterChange(
                                  filter.toggleIncomplete(),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickFilterCard(
                            icon: Icons.block_rounded,
                            label: 'Blocked',
                            caption: 'Needs attention',
                            accent: _T.red,
                            accentTint: _T.red50,
                            selected: filter.isBlocked,
                            onTap:
                                () => widget.onFilterChange(
                                  filter.toggleBlocked(),
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickFilterCard(
                            icon: Icons.rate_review_rounded,
                            label: 'In Revision',
                            caption: 'Being reworked',
                            accent: _T.amber,
                            accentTint: _T.amber.withOpacity(0.12),
                            selected: filter.isRevision,
                            onTap:
                                () => widget.onFilterChange(
                                  filter.toggleRevision(),
                                ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    _sectionLabel('PRIORITY'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          priorityOptions.map((entry) {
                            final (priority, label) = entry;
                            return _PriorityChip(
                              label: label,
                              priority: priority,
                              selected: filter.priorities.contains(priority),
                              onTap:
                                  () => widget.onFilterChange(
                                    filter.togglePriority(priority),
                                  ),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 14),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap:
                            () => setState(
                              () => _statusExpanded = !_statusExpanded,
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Text(
                                _statusExpanded
                                    ? 'Hide status filters'
                                    : 'More status filters',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _T.slate500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _statusExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 160),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: _T.slate400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 180),
                      crossFadeState:
                          _statusExpanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                      firstChild: Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _statusGroup(
                              'Design Phase',
                              designStatusOptions,
                              filter,
                            ),
                            const SizedBox(height: 14),
                            _statusGroup(
                              'Production Phase',
                              productionStatusOptions,
                              filter,
                            ),
                            const SizedBox(height: 14),
                            _statusGroup('Other', otherStatusOptions, filter),
                          ],
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _T.slate100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (filter.isActive)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: widget.onReset,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Clear all',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _T.slate500,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => widget.onApply(filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _T.blue,
                          borderRadius: BorderRadius.circular(_T.r),
                        ),
                        child: Text(
                          filter.isActive
                              ? 'Apply filters (${filter.activeCount})'
                              : 'Apply filters',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: _T.slate500,
      letterSpacing: 0.3,
    ),
  );

  Widget _statusGroup(
    String title,
    List<(String, String)> options,
    TaskFilterState filter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _T.slate400,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options.map((entry) {
                final (status, label) = entry;
                final selected = filter.statuses.contains(status);
                return _FilterToggleChip(
                  label: label,
                  selected: selected,
                  onTap:
                      () => widget.onFilterChange(filter.toggleStatus(status)),
                );
              }).toList(),
        ),
      ],
    );
  }
}

/// A recognizable, tappable "quick filter" card — icon in a tinted circle,
/// a label, a short caption, and a trailing check when active. Sized for a
/// two-column desktop grid.
class _QuickFilterCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final Color accent;
  final Color accentTint;
  final bool selected;
  final VoidCallback onTap;

  const _QuickFilterCard({
    required this.icon,
    required this.label,
    required this.caption,
    required this.accent,
    required this.accentTint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? accentTint : _T.white,
            borderRadius: BorderRadius.circular(_T.rLg),
            border: Border.all(
              color: selected ? accent.withOpacity(0.35) : _T.slate200,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? accent.withOpacity(0.16) : _T.slate100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: selected ? accent : _T.slate400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? _T.ink : _T.ink3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _T.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: selected ? 1 : 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Priority chip with a small severity dot (grey/amber/red) so priority
/// reads at a glance without needing to parse the label.
class _PriorityChip extends StatelessWidget {
  final String label;
  final int priority;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  Color get _dotColor => switch (priority) {
    2 => _T.red,
    1 => _T.amber,
    _ => _T.slate400,
  };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? _T.blue : _T.slate100,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? _T.blue.withOpacity(0.3) : _T.slate200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : _dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _T.ink3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single filter toggle chip — soft-badge recipe. Used for the granular,
/// grouped status lists under "More status filters".
class _FilterToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? _T.blue : _T.slate100,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? _T.blue.withOpacity(0.3) : _T.slate200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? _T.blue : _T.ink3,
            ),
          ),
        ),
      ),
    );
  }
}
