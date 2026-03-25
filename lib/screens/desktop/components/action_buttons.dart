// These two small button widgets (below) replace the FilledButton.icon:
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
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
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class GhostActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const GhostActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  State<GhostActionButton> createState() => _GhostActionButtonState();
}

class _GhostActionButtonState extends State<GhostActionButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: _hovered ? widget.color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(_T.r),
          border: Border.all(
            color: _hovered ? widget.color.withOpacity(0.4) : _T.slate200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 13,
              color: _hovered ? widget.color : _T.slate500,
            ),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _hovered ? widget.color : _T.slate500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class GreenActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled; // Added isEnabled property
  final bool loading; // Added loading property

  const GreenActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true, // Default value set to true
    this.loading = false, // Default value set to false
  });

  @override
  State<GreenActionButton> createState() => _GreenActionButtonState();
}

class _GreenActionButtonState extends State<GreenActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor:
        widget.enabled && !widget.loading
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
    onEnter: (_) {
      if (widget.enabled && !widget.loading) setState(() => _hovered = true);
    },
    onExit: (_) {
      if (widget.enabled && !widget.loading) setState(() => _hovered = false);
    },
    child: GestureDetector(
      onTap: widget.enabled && !widget.loading ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              widget.enabled
                  ? (widget.loading
                      ? _T.green.withOpacity(0.7) // Loading state color
                      : (_hovered ? const Color(0xFF059669) : _T.green))
                  : Colors.grey, // Disabled color
          borderRadius: BorderRadius.circular(_T.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children:
              widget.loading
                  ? [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ]
                  : [
                    Icon(
                      widget.icon,
                      size: 14,
                      color:
                          widget.enabled
                              ? Colors.white
                              : Colors.grey[400], // Disabled icon color
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        color:
                            widget.enabled
                                ? Colors.white
                                : Colors.grey[400], // Disabled text color
                      ),
                    ),
                  ],
        ),
      ),
    ),
  );
}
