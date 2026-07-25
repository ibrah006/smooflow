// lib/screens/desktop/dashboard/dashboard_theme.dart
//
// This does NOT invent a parallel token system. It reuses `_T` — the same
// slate/blue/semantic palette, the same two radii (r=6, rLg=12), the same
// three-tier shadow system — already established in task_list_view.dart,
// and only adds what's genuinely new: four role-identity accent colors,
// following the exact "color + color.withOpacity(0.1) bg + 0.3 border"
// recipe _T's badges already use.
//
// If `_T` is later made non-private/shared (e.g. moved to its own file and
// exported), swap this file's copy for that import instead of keeping two
// definitions in sync by hand.

import 'package:flutter/material.dart';

class DashTheme {
  DashTheme._();

  // ── Reused verbatim from task_list_view.dart's _T ──────────────────────
  static const blue = Color(0xFF2563EB);
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue600 = Color(0xFF1D4ED8);
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);

  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);

  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;

  static const r = 6.0;
  static const rLg = 12.0;

  static const hoverBg = Color.fromARGB(255, 250, 250, 251);
  static const hoverBorder = Color.fromARGB(255, 189, 197, 207);

  static const priorityUrgent = Color(0xFFFF878A);
  static const priorityHigh = Color(0xFFFEA06A);
  static const priorityNormal = Color(0xFFF7BD51);

  static const colDivider = Color(0xFFEDF0F3);

  static final shadowSm = BoxShadow(
    color: Colors.black.withOpacity(0.02),
    blurRadius: 2,
    offset: const Offset(0, 1),
  );
  static final shadowMd = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 6,
    offset: const Offset(0, 2),
  );
  static final shadowLg = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  // ── New: role identity accents ──────────────────────────────────────────
  // Same recipe as _T's semantic colors (solid + .1 bg + .3 border), just
  // one new hue per role so each dashboard reads as "home" at a glance.
  static const adminAccent = Color(0xFF4F46E5); // indigo — command center
  static const designAccent = Color(0xFF9333EA); // violet — creative
  static const productionAccent = Color(0xFFE8720C); // amber-orange — floor
  static const accountsAccent = green; // reuse existing green, ledger-coded
  static const minimalAccent = slate500;

  static Color accentFor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return adminAccent;
      case 'design':
        return designAccent;
      case 'production':
        return productionAccent;
      case 'accounts':
        return accountsAccent;
      default:
        return minimalAccent;
    }
  }

  static Color accentSoft(Color c) => c.withOpacity(0.1);
  static Color accentBorder(Color c) => c.withOpacity(0.3);
}

/// Status color mapping for TaskStatus — matches how the task list view
/// would color these if it exposed a shared version. Kept centralized here
/// so the pipeline strip / status chips / task rows all agree.
Color taskStatusColor(String status) {
  switch (status) {
    case 'pending':
      return DashTheme.slate400;
    case 'designing':
      return DashTheme.purple;
    case 'waitingApproval':
      return DashTheme.amber;
    case 'clientApproved':
      return const Color(0xFF7C3AED);
    case 'waitingPrinting':
      return const Color(0xFFF97316);
    case 'printing':
      return DashTheme.productionAccent;
    case 'printingCompleted':
      return const Color(0xFFEA580C);
    case 'finishing':
      return const Color(0xFFD97706);
    case 'productionCompleted':
      return const Color(0xFF65A30D);
    case 'waitingDelivery':
      return const Color(0xFF0EA5E9);
    case 'delivery':
      return const Color(0xFF0284C7);
    case 'delivered':
      return const Color(0xFF0369A1);
    case 'waitingInstallation':
      return const Color(0xFF14B8A6);
    case 'installing':
      return const Color(0xFF0D9488);
    case 'completed':
      return DashTheme.green;
    case 'blocked':
      return DashTheme.red;
    case 'paused':
      return DashTheme.slate400;
    case 'revision':
      return DashTheme.red;
    default:
      return DashTheme.slate400;
  }
}

/// Mirrors TaskStatusExt.displayName from the frontend enum.
String taskStatusDisplayName(String status) {
  if (status == 'pending') return 'Initialized';
  if (status.isEmpty) return status;

  final spaced = status
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(
        RegExp(r'([A-Z]+)([A-Z][a-z])'),
        (m) => '${m[1]} ${m[2]}',
      );

  return spaced[0].toUpperCase() + spaced.substring(1);
}
