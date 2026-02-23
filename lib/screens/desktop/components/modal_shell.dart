// ── Modal Shell ───────────────────────────────────────────────────────────────
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

class ModalShell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, saveLabel;
  final VoidCallback onClose;
  final VoidCallback? onSave;   // nullable so caller can disable during async
  final Widget child;

  const ModalShell({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle, required this.saveLabel,
    required this.onClose, required this.onSave, required this.child,
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: _T.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.rXl)),
    elevation: 24,
    child: SizedBox(
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w800, color: _T.ink, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: _T.slate500)),
              ])),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                  child: const Icon(Icons.close, size: 13, color: _T.slate400),
                ),
              ),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(22, 18, 22, 0), child: child),
          const SizedBox(height: 14),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _T.slate200))),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.slate500)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSave,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: onSave != null ? _T.blue : _T.slate300,
                    borderRadius: BorderRadius.circular(_T.r),
                  ),
                  child: Text(saveLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ],
      ),
    ),
  );
}