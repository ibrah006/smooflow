// ─────────────────────────────────────────────────────────────────────────────
// CONNECTION STATUS BANNER
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/websocket_clients/company_websocket.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — exact copy of _T from admin_desktop_dashboard.dart
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue       = Color(0xFF2563EB);
  static const blueHover  = Color(0xFF1D4ED8);
  static const blue100    = Color(0xFFDBEAFE);
  static const blue50     = Color(0xFFEFF6FF);
  static const teal       = Color(0xFF38BDF8);
  static const green      = Color(0xFF10B981);
  static const green50    = Color(0xFFECFDF5);
  static const amber      = Color(0xFFF59E0B);
  static const amber50    = Color(0xFFFEF3C7);
  static const red        = Color(0xFFEF4444);
  static const red50      = Color(0xFFFEE2E2);
  static const purple     = Color(0xFF8B5CF6);
  static const purple50   = Color(0xFFF3E8FF);
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
  static const sidebarW  = 220.0;
  static const topbarH   = 52.0;
  static const r         = 8.0;
  static const rLg       = 12.0;
  static const rXl       = 16.0;
}

class ConnectionStatusBanner extends StatelessWidget {
  final ConnectionStatus status;

  const ConnectionStatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == ConnectionStatus.connected) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _T.green50,
          borderRadius: BorderRadius.circular(_T.r),
          border: Border.all(color: _T.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync, size: 14, color: _T.green),
            const SizedBox(width: 6),
            Text(
              'Real-time updates active',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _T.green,
              ),
            ),
          ],
        ),
      );
    }

    if (status == ConnectionStatus.reconnecting || status == ConnectionStatus.connecting) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _T.amber50,
          borderRadius: BorderRadius.circular(_T.r),
          border: Border.all(color: _T.amber.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_T.amber),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Reconnecting...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _T.amber,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}