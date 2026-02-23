// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY RADIO ROW
// Three side-by-side pill buttons — visually distinct per priority level
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:smooflow/enums/task_priority.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Brand
  static const blue       = Color(0xFF2563EB);
  static const blueHover  = Color(0xFF1D4ED8);
  static const blue100    = Color(0xFFDBEAFE);
  static const blue50     = Color(0xFFEFF6FF);
  static const teal       = Color(0xFF38BDF8);

  // Semantic
  static const green      = Color(0xFF10B981);
  static const green50    = Color(0xFFECFDF5);
  static const amber      = Color(0xFFF59E0B);
  static const amber50    = Color(0xFFFEF3C7);
  static const red        = Color(0xFFEF4444);
  static const red50      = Color(0xFFFEE2E2);
  static const purple     = Color(0xFF8B5CF6);
  static const purple50   = Color(0xFFF3E8FF);

  // Neutrals
  static const slate50    = Color(0xFFF8FAFC);
  static const slate100   = Color(0xFFF1F5F9);
  static const slate200   = Color(0xFFE2E8F0);
  static const slate300   = Color(0xFFCBD5E1);
  static const slate400   = Color(0xFF94A3B8);
  static const slate500   = Color(0xFF64748B);
  static const ink        = Color(0xFF0F172A);
  static const ink2       = Color(0xFF1E293B);
  static const ink3       = Color(0xFF334155);
  static const white      = Colors.white;

  // Dimensions
  static const sidebarW  = 220.0;
  static const topbarH   = 52.0;
  static const detailW   = 400.0;

  // Radius
  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class PriorityRadioRow extends StatelessWidget {
  final TaskPriority selected;
  final void Function(TaskPriority) onChanged;
  final bool disabled;

  const PriorityRadioRow({
    required this.selected,
    required this.onChanged,
    required this.disabled
  });

  static const _options = [
    (TaskPriority.normal, 'Normal',  _T.slate500, _T.slate100, _T.slate200,  Icons.remove_rounded),
    (TaskPriority.high,   'High',    _T.amber,    _T.amber50,  Color(0xFFFCD34D), Icons.keyboard_arrow_up_rounded),
    (TaskPriority.urgent, 'Urgent',  _T.red,      _T.red50,    Color(0xFFFCA5A5), Icons.keyboard_double_arrow_up_rounded),
  ];

  Widget _pill({
    required TaskPriority priority,
    required bool isActive,
    required Color bgColor,
    required Color borderColor,
    required Color fgColor,
    required IconData icon,
    required String label
  }) {

    final widget = GestureDetector(
      onTap: () => disabled? null : onChanged(priority),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? bgColor : _T.slate50,
          border: Border.all(
            color: isActive ? borderColor : _T.slate200,
            width: isActive ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(_T.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 👈 critical
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? fgColor : Colors.transparent,
                border: Border.all(
                  color: isActive ? fgColor : _T.slate300,
                  width: 1.5,
                ),
              ),
              child: isActive
                  ? Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 5),
            Icon(
              icon,
              size: 11,
              color: isActive ? fgColor : _T.slate400,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isActive ? fgColor : _T.slate500,
              ),
            ),
          ],
        ),
      ),
    );

    return disabled? ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]),
      child: widget
    ) : widget;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 244,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRIORITY',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _T.slate400,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 5,      // horizontal spacing
            runSpacing: 5,   // vertical spacing
            children: _options.map((opt) {
              final (priority, label, fgColor, bgColor, borderColor, icon) = opt;
              final isActive = selected == priority;

              return _pill(priority: priority, isActive: isActive, bgColor: bgColor, borderColor: borderColor, fgColor: fgColor, icon: icon, label: label);
            }).toList(),
          ),
        ],
      ),
    );
  }
}