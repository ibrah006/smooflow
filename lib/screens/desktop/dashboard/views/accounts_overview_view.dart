// lib/screens/desktop/dashboard/views/accounts_overview_view.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/accounts_overview.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';

class AccountsOverviewView extends StatelessWidget {
  final AccountsOverview data;
  const AccountsOverviewView({super.key, required this.data});

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final accent = DashboardTokens.accountsAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── KPI row ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: KpiStat(
                label: 'OUTSTANDING',
                value: _money(data.invoices.totalAmountDue),
                icon: Icons.receipt_long_outlined,
                accentColor:
                    data.invoices.totalAmountDue > 0
                        ? DashboardTokens.danger
                        : accent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'OVERDUE INVOICES',
                value: '${data.invoices.overdue.length}',
                icon: Icons.error_outline,
                accentColor:
                    data.invoices.overdue.isNotEmpty
                        ? DashboardTokens.warning
                        : accent,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'COLLECTED THIS MONTH',
                value: _money(data.payments.thisMonthTotal),
                icon: Icons.payments_outlined,
                accentColor: DashboardTokens.success,
              ),
            ),
            const SizedBox(width: DashboardTokens.space16),
            Expanded(
              child: KpiStat(
                label: 'QUOTES PENDING',
                value: '${data.quotations.totalPendingCount}',
                icon: Icons.description_outlined,
                accentColor: accent,
              ),
            ),
          ],
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Invoice status breakdown ────────────────────────────────────
        const DashboardSectionHeader(title: 'Invoices by Status'),
        DashboardCard(
          child:
              data.invoices.statusCounts.isEmpty
                  ? const DashboardEmptyState(message: 'No invoices yet')
                  : Column(
                    children:
                        data.invoices.statusCounts.map((s) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: DashboardTokens.space8,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 130,
                                  child: Text(
                                    s.displayStatus,
                                    style: DashboardTokens.bodyMd.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value:
                                          data.invoices.statusCounts.isEmpty
                                              ? 0
                                              : s.count /
                                                  data.invoices.statusCounts
                                                      .map((e) => e.count)
                                                      .reduce(
                                                        (a, b) => a > b ? a : b,
                                                      ),
                                      minHeight: 6,
                                      backgroundColor:
                                          DashboardTokens.surfaceSunken,
                                      valueColor: AlwaysStoppedAnimation(
                                        _statusColor(s.status),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: DashboardTokens.space16),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${s.count}',
                                    style: DashboardTokens.bodySm,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: DashboardTokens.space12),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    _money(s.totalAmount),
                                    style: DashboardTokens.bodySm.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Two-column: Overdue + Recent invoices ────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _OverdueInvoicesSection(data: data)),
            const SizedBox(width: DashboardTokens.space24),
            Expanded(child: _RecentInvoicesSection(data: data)),
          ],
        ),

        const SizedBox(height: DashboardTokens.space32),

        // ── Two column: Payments by method + Quotations ──────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _PaymentsByMethodSection(data: data)),
            const SizedBox(width: DashboardTokens.space24),
            Expanded(child: _QuotationsSection(data: data)),
          ],
        ),

        const SizedBox(height: DashboardTokens.space24),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return DashboardTokens.success;
      case 'overdue':
        return DashboardTokens.danger;
      case 'partially_paid':
        return DashboardTokens.warning;
      case 'sent':
        return DashboardTokens.info;
      case 'cancelled':
        return DashboardTokens.textTertiary;
      default:
        return DashboardTokens.accountsAccent;
    }
  }
}

class _OverdueInvoicesSection extends StatelessWidget {
  final AccountsOverview data;
  const _OverdueInvoicesSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(title: 'Overdue Invoices'),
        DashboardCard(
          padding: const EdgeInsets.symmetric(
            vertical: DashboardTokens.space12,
          ),
          child:
              data.invoices.overdue.isEmpty
                  ? const DashboardEmptyState(
                    message: 'No overdue invoices — nice work',
                    icon: Icons.thumb_up_outlined,
                  )
                  : Column(
                    children:
                        data.invoices.overdue.take(6).map((inv) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DashboardTokens.space16,
                              vertical: DashboardTokens.space8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inv.invoiceNumber,
                                        style: DashboardTokens.bodyMd.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        inv.clientName,
                                        style: DashboardTokens.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${inv.amountDue.toStringAsFixed(2)}',
                                      style: DashboardTokens.bodyMd.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${inv.daysOverdue}d overdue',
                                      style: DashboardTokens.caption.copyWith(
                                        color: DashboardTokens.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }
}

class _RecentInvoicesSection extends StatelessWidget {
  final AccountsOverview data;
  const _RecentInvoicesSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(title: 'Recently Issued'),
        DashboardCard(
          padding: const EdgeInsets.symmetric(
            vertical: DashboardTokens.space12,
          ),
          child:
              data.invoices.recentlyIssued.isEmpty
                  ? const DashboardEmptyState(
                    message: 'No invoices issued recently',
                  )
                  : Column(
                    children:
                        data.invoices.recentlyIssued.take(6).map((inv) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DashboardTokens.space16,
                              vertical: DashboardTokens.space8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        inv.invoiceNumber,
                                        style: DashboardTokens.bodyMd.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        inv.clientName,
                                        style: DashboardTokens.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${inv.totalAmount.toStringAsFixed(2)}',
                                  style: DashboardTokens.bodyMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }
}

class _PaymentsByMethodSection extends StatelessWidget {
  final AccountsOverview data;
  const _PaymentsByMethodSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(title: 'Payments This Month'),
        DashboardCard(
          child:
              data.payments.byMethod.isEmpty
                  ? const DashboardEmptyState(
                    message: 'No payments recorded yet this month',
                  )
                  : Column(
                    children:
                        data.payments.byMethod.map((p) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: DashboardTokens.space8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  p.displayMethod,
                                  style: DashboardTokens.bodyMd,
                                ),
                                Text(
                                  '\$${p.total.toStringAsFixed(2)}',
                                  style: DashboardTokens.bodyMd.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }
}

class _QuotationsSection extends StatelessWidget {
  final AccountsOverview data;
  const _QuotationsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(title: 'Quotations'),
        DashboardCard(
          padding: const EdgeInsets.symmetric(
            vertical: DashboardTokens.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.quotations.pendingResponse.isEmpty &&
                  data.quotations.recentlyAccepted.isEmpty)
                const DashboardEmptyState(
                  message: 'No quotations awaiting action',
                )
              else ...[
                if (data.quotations.pendingResponse.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardTokens.space16,
                    ),
                    child: Text(
                      'Pending response',
                      style: DashboardTokens.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: DashboardTokens.space4),
                  ...data.quotations.pendingResponse
                      .take(4)
                      .map(
                        (q) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DashboardTokens.space16,
                            vertical: DashboardTokens.space4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${q.number} — ${q.clientName}',
                                  style: DashboardTokens.bodyMd,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${q.daysSinceSent}d',
                                style: DashboardTokens.bodySm.copyWith(
                                  color:
                                      q.isStale
                                          ? DashboardTokens.warning
                                          : DashboardTokens.textSecondary,
                                  fontWeight:
                                      q.isStale
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
                if (data.quotations.recentlyAccepted.isNotEmpty) ...[
                  const SizedBox(height: DashboardTokens.space8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardTokens.space16,
                    ),
                    child: Text(
                      'Recently accepted',
                      style: DashboardTokens.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: DashboardTokens.space4),
                  ...data.quotations.recentlyAccepted
                      .take(4)
                      .map(
                        (q) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DashboardTokens.space16,
                            vertical: DashboardTokens.space4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${q.number} — ${q.clientName}',
                                  style: DashboardTokens.bodyMd,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '\$${q.total.toStringAsFixed(2)}',
                                style: DashboardTokens.bodySm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: DashboardTokens.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
