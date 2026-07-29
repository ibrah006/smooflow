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

/// Active filter state: selected statuses and priorities.
class TaskFilterState {
  final Set<String> statuses; // empty = show all
  final Set<int> priorities; // empty = show all (0=normal, 1=high, 2=urgent)

  const TaskFilterState({Set<String>? statuses, Set<int>? priorities})
    : statuses = statuses ?? const {},
      priorities = priorities ?? const {};

  bool get isActive => statuses.isNotEmpty || priorities.isNotEmpty;

  TaskFilterState copyWith({Set<String>? statuses, Set<int>? priorities}) =>
      TaskFilterState(
        statuses: statuses ?? this.statuses,
        priorities: priorities ?? this.priorities,
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
                  onFilterChange:
                      (updated) => setState(() => _overlayFilter = updated),
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
                      '${widget.filter.statuses.length + widget.filter.priorities.length}',
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

/// Filter panel — status and priority toggles, reset button.
class _TaskFilterPanel extends StatelessWidget {
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

  // Task statuses (design scope: up to waitingPrinting)
  static const List<(String, String)> designStatusOptions = [
    ('pending', 'Initialized'),
    ('designing', 'Designing'),
    ('waitingApproval', 'Waiting Approval'),
    ('clientApproved', 'Client Approved'),
    ('waitingPrinting', 'Waiting Printing'),
  ];

  // Production statuses
  static const List<(String, String)> productionStatusOptions = [
    ('printing', 'Printing'),
    ('printingCompleted', 'Printing Completed'),
    ('finishing', 'Finishing'),
    ('productionCompleted', 'Production Completed'),
    ('waitingDelivery', 'Waiting Delivery'),
    ('delivery', 'Delivery'),
    ('delivered', 'Delivered'),
  ];

  // All statuses
  static const List<(String, String)> allStatusOptions = [
    ('pending', 'Initialized'),
    ('designing', 'Designing'),
    ('waitingApproval', 'Waiting Approval'),
    ('clientApproved', 'Client Approved'),
    ('waitingPrinting', 'Waiting Printing'),
    ('printing', 'Printing'),
    ('printingCompleted', 'Printing Completed'),
    ('finishing', 'Finishing'),
    ('productionCompleted', 'Production Completed'),
    ('waitingDelivery', 'Waiting Delivery'),
    ('delivery', 'Delivery'),
    ('delivered', 'Delivered'),
    ('blocked', 'Blocked'),
    ('paused', 'Paused'),
    ('revision', 'Revision'),
  ];

  static const List<(int, String)> priorityOptions = [
    (0, 'Normal'),
    (1, 'High'),
    (2, 'Urgent'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_T.rLg),
      child: Container(
        width: 340,
        constraints: const BoxConstraints(maxHeight: 600),
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
                        onTap: onReset,
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _T.slate500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          allStatusOptions.map((entry) {
                            final (status, label) = entry;
                            final selected = filter.statuses.contains(status);
                            return _FilterToggleChip(
                              label: label,
                              selected: selected,
                              onTap:
                                  () => onFilterChange(
                                    filter.toggleStatus(status),
                                  ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PRIORITY',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _T.slate500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          priorityOptions.map((entry) {
                            final (priority, label) = entry;
                            final selected = filter.priorities.contains(
                              priority,
                            );
                            return _FilterToggleChip(
                              label: label,
                              selected: selected,
                              onTap:
                                  () => onFilterChange(
                                    filter.togglePriority(priority),
                                  ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single filter toggle chip — soft-badge recipe.
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
