// ─────────────────────────────────────────────────────────────────────────────
// screens/desktop/accounts_dashboard_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/app_database.dart';
import 'package:smooflow/screens/desktop/components/invoice_status_badge.dart';
import '../../providers/accounts_providers.dart';
import 'components/kpi_card.dart';

class AccountsDashboardScreen extends ConsumerWidget {
  const AccountsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final recentInvoices = ref.watch(invoicesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            const SizedBox(height: 28),

            // ── KPI CARDS ──────────────────────────────────────────────────
            stats.when(
              loading: () => const _KpiSkeleton(),
              error: (e, _) => Text('Error: $e'),
              data: (data) => Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      label: 'Outstanding',
                      value: _aed(data['totalOutstanding']),
                      icon: Icons.receipt_long_outlined,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFDBEAFE),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KpiCard(
                      label: 'Overdue',
                      value: _aed(data['totalOverdue']),
                      icon: Icons.warning_amber_outlined,
                      iconColor: const Color(0xFFEF4444),
                      iconBg: const Color(0xFFFEE2E2),
                      valueColor: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KpiCard(
                      label: 'Paid This Month',
                      value: _aed(data['totalPaidThisMonth']),
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFECFDF5),
                      valueColor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KpiCard(
                      label: 'Drafts',
                      value: '${data['draftCount']}',
                      icon: Icons.edit_note_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: const Color(0xFFFEF3C7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── QUICK ACTIONS ──────────────────────────────────────────────
            _SectionTitle('Quick Actions'),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickAction(
                  label: 'New Invoice',
                  icon: Icons.add_circle_outline,
                  color: const Color(0xFF2563EB),
                  onTap: () {}//('/accounts/invoices/create'),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  label: 'Record Payment',
                  icon: Icons.payments_outlined,
                  color: const Color(0xFF10B981),
                  onTap: () {}//('/accounts/payments'),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  label: 'View All Invoices',
                  icon: Icons.list_alt_outlined,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {}//('/accounts/invoices'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── RECENT INVOICES ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle('Recent Invoices'),
                TextButton(
                  onPressed: () {},// context.go('/accounts/invoices'),
                  child: const Text('View all →',
                      style: TextStyle(color: Color(0xFF2563EB))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            recentInvoices.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (invoices) {
                final recent = invoices.take(6).toList();
                if (recent.isEmpty) {
                  return _EmptyState(
                    message: 'No invoices yet',
                    onAction: () {},//context.go('/accounts/invoices/create'),
                    actionLabel: 'Create your first invoice',
                  );
                }
                return _RecentInvoicesTable(invoices: recent);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _aed(dynamic value) {
    final v = (value as num?)?.toDouble() ?? 0.0;
    return 'AED ${v.toStringAsFixed(2)}';
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${months[now.month]} ${now.day}, ${now.year}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Accounts Dashboard',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SECTION TITLE ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)));
}

// ─── QUICK ACTION ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── RECENT INVOICES TABLE ───────────────────────────────────────────────────

class _RecentInvoicesTable extends StatelessWidget {
  final List<Invoice> invoices;
  const _RecentInvoicesTable({required this.invoices});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: const [
                Expanded(flex: 2, child: _ColHeader('Invoice #')),
                Expanded(flex: 3, child: _ColHeader('Client')),
                Expanded(flex: 2, child: _ColHeader('Due Date')),
                Expanded(flex: 2, child: _ColHeader('Amount')),
                Expanded(flex: 2, child: _ColHeader('Status')),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ...invoices.asMap().entries.map((e) {
            final i = e.value;
            final isLast = e.key == invoices.length - 1;
            return Column(
              children: [
                InkWell(
                  onTap: () {},
                      //context.go('/accounts/invoices/${i.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(i.invoiceNumber,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB))),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(i.clientName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF0F172A))),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_formatDate(i.dueDate),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B))),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                              'AED ${i.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A))),
                        ),
                        Expanded(
                          flex: 2,
                          child: InvoiceStatusBadge(status: i.status),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _ColHeader extends StatelessWidget {
  final String label;
  const _ColHeader(this.label);
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.5));
}

// ─── EMPTY STATE ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 40, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel,
                  style: const TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── KPI SKELETON ─────────────────────────────────────────────────────────────

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        4,
        (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// screens/desktop/components/kpi_card.dart
// ─────────────────────────────────────────────────────────────────────────────

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color? valueColor;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: valueColor ?? const Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}