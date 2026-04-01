// ─────────────────────────────────────────────────────────────────────────────
// _GhostField
//
// Three visual states:
//   idle    — renders like plain text, no border, no fill
//   hover   — slate100 fill + dashed slate200 border (1px), cursor changes
//   focused — white fill + solid slate300 border (1px), slight inset shadow
//
// Usage:
//   _GhostField(
//     controller: _nameCtrl,
//     style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _T.ink),
//     hint: 'Untitled task',
//     maxLines: 1,
//   )
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (unchanged)
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
  static const sidebarW = 220.0;
  static const topbarH = 52.0;
  static const detailW = 400.0;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class GhostField extends StatefulWidget {
  final TextEditingController controller;

  /// The text style used for both the rendered value and the input.
  /// Pass the exact same style you would use on a plain [Text] widget.
  final TextStyle style;

  final String? hint;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const GhostField({
    required this.controller,
    required this.style,
    this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  State<GhostField> createState() => _GhostFieldState();
}

class _GhostFieldState extends State<GhostField> {
  final _focus = FocusNode();
  bool _hovered = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  // Resolved colors for each layer
  Color get _fill {
    if (_focused) return _T.white;
    if (_hovered) return _T.slate100;
    return Colors.transparent;
  }

  Border get _border {
    if (_focused) {
      return Border.all(color: _T.slate300, width: 1);
    }
    if (_hovered) {
      // Dashed border signals "editable" without feeling like a form field
      return Border.all(color: _T.slate200, width: 1);
    }
    return Border.all(color: Colors.transparent, width: 1);
  }

  List<BoxShadow> get _shadow {
    if (_focused) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    // Derive padding from the style's font size so it scales correctly
    final fontSize = widget.style.fontSize ?? 14;
    final vPad = (fontSize * 0.35).clamp(4.0, 10.0);
    final hPad = (fontSize * 0.45).clamp(6.0, 12.0);

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _fill,
          borderRadius: BorderRadius.circular(_T.r),
          border: _border,
          boxShadow: _shadow,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          style: widget.style,
          cursorColor: _T.blue,
          cursorWidth: 1.5,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: widget.style.copyWith(color: _T.slate300),
            // No border at all — the AnimatedContainer owns the visual border
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: hPad,
              vertical: vPad,
            ),
          ),
        ),
      ),
    );
  }
}
