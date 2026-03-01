// ─────────────────────────────────────────────────────────────────────────────
// screens/desktop/components/invoice_status_badge.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:smooflow/core/app_database.dart';

class InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const InvoiceStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: config.text),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _config(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return _BadgeConfig(
          label: 'Draft',
          bg: const Color(0xFFF1F5F9),
          dot: const Color(0xFF94A3B8),
          text: const Color(0xFF64748B),
        );
      case InvoiceStatus.sent:
        return _BadgeConfig(
          label: 'Sent',
          bg: const Color(0xFFDBEAFE),
          dot: const Color(0xFF2563EB),
          text: const Color(0xFF2563EB),
        );
      case InvoiceStatus.paid:
        return _BadgeConfig(
          label: 'Paid',
          bg: const Color(0xFFECFDF5),
          dot: const Color(0xFF10B981),
          text: const Color(0xFF10B981),
        );
      case InvoiceStatus.partiallyPaid:
        return _BadgeConfig(
          label: 'Partial',
          bg: const Color(0xFFF3E8FF),
          dot: const Color(0xFF8B5CF6),
          text: const Color(0xFF8B5CF6),
        );
      case InvoiceStatus.overdue:
        return _BadgeConfig(
          label: 'Overdue',
          bg: const Color(0xFFFEE2E2),
          dot: const Color(0xFFEF4444),
          text: const Color(0xFFEF4444),
        );
      case InvoiceStatus.cancelled:
        return _BadgeConfig(
          label: 'Cancelled',
          bg: const Color(0xFFF1F5F9),
          dot: const Color(0xFFCBD5E1),
          text: const Color(0xFF94A3B8),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color bg, dot, text;
  const _BadgeConfig(
      {required this.label,
      required this.bg,
      required this.dot,
      required this.text});
}