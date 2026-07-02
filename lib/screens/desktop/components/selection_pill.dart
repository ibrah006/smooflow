import 'package:flutter/material.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/screens/printers_management_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Brand
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const teal = Color(0xFF38BDF8);

  // Semantic
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);

  // Neutrals
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

  // Dimensions
  static const sidebarW = 220.0;
  static const topbarH = 52.0;
  static const detailW = 400.0;

  // Radius
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class SelectionPill<T> extends StatelessWidget {
  // final TaskPriority priority;

  final List<(T value, Color color, Color bg)> values;
  final T currentValue;
  const SelectionPill({
    required this.currentValue,
    required this.values,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final item = values.firstWhere((value) => value.$1 == currentValue);

    var title = item.$1.toString().split('.').last;
    title = title[0].capitalize() + title.substring(1);

    return Wrap(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: item.$3,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: item.$2,
            ),
          ),
        ),
      ],
    );
  }
}
