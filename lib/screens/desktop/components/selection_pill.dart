import 'package:flutter/material.dart';

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
  final T initialValue;
  final List<(T value, Color color, Color bg)> values;
  final Future Function(T)? onChanged;

  const SelectionPill({
    required this.initialValue,
    required this.values,
    this.onChanged,
    super.key,
  });

  @override
  State<SelectionPill<T>> createState() => _SelectionPillState<T>();
}

class _SelectionPillState<T> extends State<SelectionPill<T>> {
  final LayerLink _layerLink = LayerLink();
  bool _isHovered = false;
  bool _isOpen = false;

  late T currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue; //[cite: 6]
  }

  String _formatTitle(T val) {
    var title = val.toString().split('.').last; //[cite: 6]
    if (title.isEmpty) return '';
    return title[0].toUpperCase() + title.substring(1); //[cite: 6]
  }

  void _toggleDropdown() {
    if (!_isOpen) {
      _showDropdown();
    }
  }

  void _showDropdown() async {
    setState(() => _isOpen = true);

    final T? selectedValue = await showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Dropdown',
      barrierColor:
          Colors.transparent, // Keeps background fully clickable and visible
      transitionDuration: const Duration(milliseconds: 200), //[cite: 6]
      pageBuilder: (context, animation, secondaryAnimation) {
        return CompositedTransformFollower(
          link: _layerLink, //[cite: 6]
          showWhenUnlinked: false, //[cite: 6]
          targetAnchor: Alignment.bottomLeft, //[cite: 6]
          followerAnchor: Alignment.topLeft, //[cite: 6]
          offset: const Offset(0, 4), //[cite: 6]
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 140, //[cite: 6]
                padding: const EdgeInsets.all(4), //[cite: 6]
                decoration: BoxDecoration(
                  color: _T.white, //[cite: 6]
                  borderRadius: BorderRadius.circular(_T.r), //[cite: 6]
                  border: Border.all(color: _T.slate200), //[cite: 6]
                  boxShadow: [
                    BoxShadow(
                      color: _T.ink.withOpacity(0.06), //[cite: 6]
                      blurRadius: 12, //[cite: 6]
                      offset: const Offset(0, 4), //[cite: 6]
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children:
                      widget.values.map((item) {
                        final isSelected = item.$1 == currentValue; //[cite: 6]
                        return _DropdownItemRow(
                          title: _formatTitle(item.$1), //[cite: 6]
                          color: item.$2, //[cite: 6]
                          bg: item.$3, //[cite: 6]
                          isSelected: isSelected, //[cite: 6]
                          onTap: () => Navigator.pop(context, item.$1),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic, //[cite: 6]
        );
        return SizeTransition(
          sizeFactor: curvedAnimation, //[cite: 6]
          axisAlignment: -1.0, //[cite: 6]
          child: FadeTransition(
            opacity: curvedAnimation, //[cite: 6]
            child: child,
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _isOpen = false);
    }

    // Process asynchronous lifecycle update callbacks safely on pop execution
    if (selectedValue != null && widget.onChanged != null) {
      setState(() => currentValue = selectedValue);
      await widget.onChanged!(selectedValue); //[cite: 6]
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.values.firstWhere(
      (value) => value.$1 == currentValue,
    ); //[cite: 6]
    final String title = _formatTitle(item.$1); //[cite: 6]
    final showIcon = _isHovered || _isOpen; //[cite: 6]

    return CompositedTransformTarget(
      link: _layerLink, //[cite: 6]
      child: MouseRegion(
        cursor: SystemMouseCursors.click, //[cite: 6]
        onEnter: (_) => setState(() => _isHovered = true), //[cite: 6]
        onExit: (_) => setState(() => _isHovered = false), //[cite: 6]
        child: GestureDetector(
          onTap: _toggleDropdown, //[cite: 6]
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150), //[cite: 6]
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 2.5,
            ), //[cite: 6]
            decoration: BoxDecoration(
              color: item.$3, //[cite: 6]
              borderRadius: BorderRadius.circular(99), //[cite: 6]
              border: Border.all(
                color:
                    _isOpen
                        ? item.$2.withOpacity(0.3)
                        : Colors.white, //[cite: 6]
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5, //[cite: 6]
                    fontWeight: FontWeight.w700, //[cite: 6]
                    color: item.$2, //[cite: 6]
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180), //[cite: 6]
                  curve: Curves.easeOutCubic, //[cite: 6]
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showIcon) ...[
                        const SizedBox(width: 3), //[cite: 6]
                        AnimatedRotation(
                          turns: _isOpen ? 0.5 : 0.0, //[cite: 6]
                          duration: const Duration(
                            milliseconds: 180,
                          ), //[cite: 6]
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 13, //[cite: 6]
                            color: item.$2.withOpacity(0.8), //[cite: 6]
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
      cursor: SystemMouseCursors.click, //[cite: 6]
      onEnter: (_) => setState(() => _itemHovered = true), //[cite: 6]
      onExit: (_) => setState(() => _itemHovered = false), //[cite: 6]
      child: GestureDetector(
        onTap: widget.onTap, //[cite: 6]
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), //[cite: 6]
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ), //[cite: 6]
          decoration: BoxDecoration(
            color: _itemHovered ? _T.slate50 : Colors.white, //[cite: 6]
            borderRadius: BorderRadius.circular(_T.r - 2), //[cite: 6]
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ), //[cite: 6]
                decoration: BoxDecoration(
                  color: widget.bg, //[cite: 6]
                  borderRadius: BorderRadius.circular(99), //[cite: 6]
                ),
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 10, //[cite: 6]
                    fontWeight: FontWeight.w700, //[cite: 6]
                    color: widget.color, //[cite: 6]
                  ),
                ),
              ),
              const Spacer(), //[cite: 6]
              if (widget.isSelected)
                const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: _T.blue,
                ), //[cite: 6]
            ],
          ),
        ),
      ),
    );
  }
}
