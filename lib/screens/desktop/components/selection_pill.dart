import 'package:flutter/material.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/screens/printers_management_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
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

  static const sidebarW = 220.0;
  static const topbarH = 52.0;
  static const detailW = 400.0;

  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class SelectionPill<T> extends StatefulWidget {
  final List<(T value, Color color, Color bg)> values;
  final T currentValue;
  final ValueChanged<T>?
  onChanged; // Added callback to support selection changes

  const SelectionPill({
    required this.currentValue,
    required this.values,
    this.onChanged,
    super.key,
  });

  @override
  State<SelectionPill<T>> createState() => _SelectionPillState<T>();
}

class _SelectionPillState<T> extends State<SelectionPill<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;
  bool _isOpen = false;

  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _closeDropdown();
    _animationController.dispose();
    super.dispose();
  }

  String _formatTitle(T val) {
    var title = val.toString().split('.').last;
    if (title.isEmpty) return '';
    return title[0].toUpperCase() + title.substring(1);
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    setState(() => _isOpen = true);
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              // Dismiss target when clicking anywhere outside the popup menu
              GestureDetector(
                onTap: _closeDropdown,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 4),
                child: Material(
                  color: Colors.transparent,
                  child: SizeTransition(
                    sizeFactor: _expandAnimation,
                    axisAlignment: -1.0,
                    child: FadeTransition(
                      opacity: _expandAnimation,
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _T.white,
                          borderRadius: BorderRadius.circular(_T.r),
                          border: Border.all(color: _T.slate200),
                          boxShadow: [
                            BoxShadow(
                              color: _T.ink.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children:
                              widget.values.map((item) {
                                final isSelected =
                                    item.$1 == widget.currentValue;
                                return _DropdownItemRow(
                                  title: _formatTitle(item.$1),
                                  color: item.$2,
                                  bg: item.$3,
                                  isSelected: isSelected,
                                  onTap: () {
                                    widget.onChanged?.call(item.$1);
                                    _closeDropdown();
                                  },
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.values.firstWhere(
      (value) => value.$1 == widget.currentValue,
    );
    final String title = _formatTitle(item.$1);
    final showIcon = _isHovered || _isOpen;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: item.$3,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: _isOpen ? item.$2.withOpacity(0.3) : Colors.white,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: item.$2,
                  ),
                ),
                // Smooth horizontal expand/collapse for the left icon
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showIcon) ...[
                        const SizedBox(width: 3),
                        AnimatedRotation(
                          turns: _isOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 13,
                            color: item.$2.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// INNER DROPDOWN ITEM ROW
// ─────────────────────────────────────────────────────────────────────────────
class _DropdownItemRow extends StatefulWidget {
  final String title;
  final Color color;
  final Color bg;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownItemRow({
    required this.title,
    required this.color,
    required this.bg,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DropdownItemRow> createState() => _DropdownItemRowState();
}

class _DropdownItemRowState extends State<_DropdownItemRow> {
  bool _itemHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _itemHovered = true),
      onExit: (_) => setState(() => _itemHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _itemHovered ? _T.slate50 : Colors.white,
            borderRadius: BorderRadius.circular(_T.r - 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.bg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.isSelected)
                const Icon(Icons.check_rounded, size: 13, color: _T.blue),
            ],
          ),
        ),
      ),
    );
  }
}
