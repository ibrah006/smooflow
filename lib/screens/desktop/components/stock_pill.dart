// ─────────────────────────────────────────────────────────────────────────────
// MISC SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class StockPill extends StatelessWidget {
  final String label;
  final Color color, bg;
  final bool collapsed;
  const StockPill({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
    this.collapsed = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        if (!collapsed) ...[
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ],
    ),
  );
}
