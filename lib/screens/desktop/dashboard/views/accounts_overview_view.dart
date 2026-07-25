// lib/screens/desktop/dashboard/views/accounts_overview_view.dart

import 'package:flutter/material.dart';
import 'package:smooflow/core/models/dashboard/accounts_overview.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';

class AccountsOverviewView extends StatelessWidget {
  final AccountsOverview data;
  const AccountsOverviewView({super.key, required this.data});

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final accent = DashTheme.accountsAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DashKpiTile(
                label: 'Outstanding',
                value: _money(data.invoices.totalAmountDue),
                icon: Icons.receipt_long_outlined,
                accent: accent,
                alert: data.invoices.totalAmountDue > 0,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Overdue invoices',
                value: '${data.invoices.overdue.length}',
                icon: Icons.error_outline,
                accent: accent,
                alert: data.invoices.overdue.isNotEmpty,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Collected this month',
                value: _money(data.payments.thisMonthTotal),
                icon: Icons.payments_outlined,
                accent: DashTheme.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DashKpiTile(
                label: 'Quotes pending',
                value: '${data.quotations.totalPendingCount}',
                icon: Icons.description_outlined,
                accent: accent,
              ),
            ),
          ],
        ),

        const SizedBox(height: 26),

        const DashSectionHeader(title: 'Invoices by Status'),
        DashCard(
          child:
              data.invoices.statusCounts.isEmpty
                  ? const DashEmptyState(
                    title: 'No invoices yet',
                    subtitle: 'Invoices you create will appear here',
                    icon: Icons.receipt_outlined,
                  )
                  : Column(
                    children:
                        data.invoices.statusCounts.map((s) {
                          final maxVal = data.invoices.statusCounts
                              .map((e) => e.count)
                              .reduce((a, b) => a > b ? a : b);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    s.displayStatus,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: DashTheme.ink3,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: s.count / maxVal,
                                      minHeight: 6,
                                      backgroundColor: DashTheme.slate100,
                                      valueColor: AlwaysStoppedAnimation(
                                        _statusColor(s.status),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    '${s.count}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: DashTheme.slate400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 84,
                                  child: Text(
                                    _money(s.totalAmount),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: DashTheme.ink2,
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

        const SizedBox(height: 26),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _OverdueInvoicesSection(data: data)),
            const SizedBox(width: 20),
            Expanded(child: _RecentInvoicesSection(data: data)),
          ],
        ),

        const SizedBox(height: 26),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _PaymentsByMethodSection(data: data)),
            const SizedBox(width: 20),
            Expanded(child: _QuotationsSection(data: data)),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return DashTheme.green;
      case 'overdue':
        return DashTheme.red;
      case 'partially_paid':
        return DashTheme.amber;
      case 'sent':
        return DashTheme.blue;
      case 'cancelled':
        return DashTheme.slate400;
      default:
        return DashTheme.accountsAccent;
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
        DashSectionHeader(
          title: 'Overdue Invoices',
          count: data.invoices.overdue.length,
          accent: DashTheme.red,
        ),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child:
              data.invoices.overdue.isEmpty
                  ? const DashEmptyState(
                    title: 'Nothing overdue',
                    subtitle: 'All invoices are within terms',
                    icon: Icons.thumb_up_outlined,
                  )
                  : Column(
                    children:
                        data.invoices.overdue.take(6).map((inv) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
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
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: DashTheme.ink3,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        inv.clientName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: DashTheme.slate400,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${inv.amountDue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: DashTheme.ink2,
                                      ),
                                    ),
                                    Text(
                                      '${inv.daysOverdue}d overdue',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: DashTheme.red,
                                        fontWeight: FontWeight.w700,
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
        const DashSectionHeader(title: 'Recently Issued'),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child:
              data.invoices.recentlyIssued.isEmpty
                  ? const DashEmptyState(
                    title: 'Nothing issued recently',
                    subtitle: 'New invoices will show up here',
                    icon: Icons.description_outlined,
                  )
                  : Column(
                    children:
                        data.invoices.recentlyIssued.take(6).map((inv) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
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
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: DashTheme.ink3,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        inv.clientName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: DashTheme.slate400,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${inv.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: DashTheme.ink2,
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
        const DashSectionHeader(title: 'Payments This Month'),
        DashCard(
          child:
              data.payments.byMethod.isEmpty
                  ? const DashEmptyState(
                    title: 'No payments yet',
                    subtitle: 'Payments recorded this month will appear here',
                    icon: Icons.payments_outlined,
                  )
                  : Column(
                    children:
                        data.payments.byMethod.map((p) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  p.displayMethod,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: DashTheme.ink3,
                                  ),
                                ),
                                Text(
                                  '\$${p.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: DashTheme.ink2,
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
    final hasAny =
        data.quotations.pendingResponse.isNotEmpty ||
        data.quotations.recentlyAccepted.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashSectionHeader(title: 'Quotations'),
        DashCard(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child:
              !hasAny
                  ? const DashEmptyState(
                    title: 'Nothing pending',
                    subtitle: 'No quotations awaiting action',
                    icon: Icons.description_outlined,
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.quotations.pendingResponse.isNotEmpty) ...[
                        const DashLabelChip(
                          label: 'PENDING RESPONSE',
                          color: DashTheme.amber,
                        ),
                        const SizedBox(height: 6),
                        ...data.quotations.pendingResponse
                            .take(4)
                            .map(
                              (q) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${q.number} — ${q.clientName}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: DashTheme.ink3,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${q.daysSinceSent}d',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            q.isStale
                                                ? DashTheme.amber
                                                : DashTheme.slate400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                      if (data.quotations.recentlyAccepted.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const DashLabelChip(
                          label: 'RECENTLY ACCEPTED',
                          color: DashTheme.green,
                        ),
                        const SizedBox(height: 6),
                        ...data.quotations.recentlyAccepted
                            .take(4)
                            .map(
                              (q) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${q.number} — ${q.clientName}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: DashTheme.ink3,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '\$${q.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: DashTheme.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
        ),
      ],
    );
  }
}
