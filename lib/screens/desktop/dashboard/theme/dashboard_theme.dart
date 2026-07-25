// lib/screens/desktop/dashboard/dashboard_theme.dart
//
// Design tokens for the overview dashboard. Centralizing these keeps every
// role-specific screen visually consistent while letting each role carry
// its own accent identity.

import 'package:flutter/material.dart';

class DashboardTokens {
  DashboardTokens._();

  // ── Base neutrals (shared across all roles) ─────────────────────────────
  static const Color canvas = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSunken = Color(0xFFF1F3F6);
  static const Color border = Color(0xFFE4E7EC);
  static const Color textPrimary = Color(0xFF1A1F29);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textTertiary = Color(0xFF98A2B3);

  // ── Semantic status colors (shared) ─────────────────────────────────────
  static const Color success = Color(0xFF12B76A);
  static const Color warning = Color(0xFFF79009);
  static const Color danger = Color(0xFFF04438);
  static const Color info = Color(0xFF2E90FA);

  // ── Role accent identities ──────────────────────────────────────────────
  // Each role dashboard is tinted so the room "feels" different at a glance —
  // Admin: command-center indigo. Design: creative violet.
  // Production: printer-floor amber. Accounts: ledger emerald.
  static const Color adminAccent = Color(0xFF4F46E5);
  static const Color designAccent = Color(0xFF9333EA);
  static const Color productionAccent = Color(0xFFE8720C);
  static const Color accountsAccent = Color(0xFF059669);
  static const Color minimalAccent = Color(0xFF475467);

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

  static Color accentSoftFor(String role) => accentFor(role).withOpacity(0.10);

  // ── Spacing scale ────────────────────────────────────────────────────────
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;

  // ── Radii ────────────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  // ── Type scale ───────────────────────────────────────────────────────────
  static const TextStyle kpiNumber = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.1,
    color: textPrimary,
  );

  static const TextStyle kpiNumberSm = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.1,
    color: textPrimary,
  );

  static const TextStyle sectionEyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: textTertiary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textTertiary,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: textPrimary,
  );

  // ── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

/// Status color mapping for TaskStatus (frontend enum) — used for pipeline
/// strip segments, badges, and status dots throughout the dashboard.
Color taskStatusColor(String status) {
  switch (status) {
    case 'pending':
      return const Color(0xFF98A2B3);
    case 'designing':
      return const Color(0xFF9333EA);
    case 'waitingApproval':
      return const Color(0xFFF79009);
    case 'clientApproved':
      return const Color(0xFF7C3AED);
    case 'waitingPrinting':
      return const Color(0xFFF97316);
    case 'printing':
      return const Color(0xFFE8720C);
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
      return const Color(0xFF12B76A);
    case 'blocked':
      return const Color(0xFFF04438);
    case 'paused':
      return const Color(0xFF98A2B3);
    case 'revision':
      return const Color(0xFFF04438);
    default:
      return const Color(0xFF98A2B3);
  }
}

/// Converts camelCase TaskStatus enum values to display labels,
/// mirroring the frontend TaskStatusExt.displayName logic.
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
