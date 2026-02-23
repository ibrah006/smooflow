import 'package:flutter/material.dart';

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


class ModalField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  const ModalField({required this.label, required this.child, this.required = false});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _T.ink3)),
      if (required) const Text(' *', style: TextStyle(color: _T.red, fontSize: 12)),
    ]),
    const SizedBox(height: 6),
    child,
  ]);
}

class ModalInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const ModalInput({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    style: const TextStyle(fontSize: 13, color: _T.ink),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _T.slate400),
      filled: true, fillColor: _T.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.blue, width: 2)),
    ),
  );
}

class ModalTextarea extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const ModalTextarea({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    maxLines: 3,
    style: const TextStyle(fontSize: 13, color: _T.ink),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _T.slate400),
      filled: true, fillColor: _T.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.blue, width: 2)),
    ),
  );
}

class ModalDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const ModalDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    items: items,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 13, color: _T.ink),
    decoration: InputDecoration(
      filled: true, fillColor: _T.slate50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.slate200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r), borderSide: const BorderSide(color: _T.blue, width: 2)),
    ),
    dropdownColor: Colors.white,
    borderRadius: BorderRadius.circular(_T.r),
    icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: _T.slate400),
  );
}