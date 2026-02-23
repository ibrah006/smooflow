// ─────────────────────────────────────────────────────────────────────────────
// PROJECT CHIP ROW
// Scrollable horizontal row of small project chips — tap to select
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:smooflow/core/models/project.dart';

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

class ProjectChipRow extends StatelessWidget {
  final List<Project> projects;
  final String? selectedId;
  final void Function(String) onChanged;
  final bool disabled;

  const ProjectChipRow({
    required this.projects,
    required this.selectedId,
    required this.onChanged,
    required this.disabled
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: 244,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROJECT',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _T.slate400,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 5,       // horizontal spacing
            runSpacing: 5,    // vertical spacing
            children: projects.map((p) {
              final isActive = p.id == selectedId;

              return ColorFiltered(
                colorFilter: disabled? ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]) : ColorFilter.mode(Colors.transparent, BlendMode.color),
                child: GestureDetector(
                  onTap: disabled? null : () => onChanged(p.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? p.color.withOpacity(0.12)
                          : _T.slate50,
                      border: Border.all(
                        color: isActive
                            ? p.color.withOpacity(0.5)
                            : _T.slate200,
                        width: isActive ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 👈 important
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: isActive ? 7 : 6,
                          height: isActive ? 7 : 6,
                          decoration: BoxDecoration(
                            color: p.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color:
                                isActive ? p.color : _T.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );


  }
}
