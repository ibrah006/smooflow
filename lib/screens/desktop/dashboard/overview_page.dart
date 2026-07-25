// lib/screens/desktop/dashboard/overview_page.dart
//
// Entry point for the dashboard. Watches dashboardOverviewProvider and
// dispatches to the correct role-specific view. Handles loading/error
// states once here so individual role screens can assume good data.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/dashboard/overview_response.dart';
import 'package:smooflow/providers/dashboard_provider.dart';
import 'package:smooflow/screens/desktop/dashboard/dashboard_theme.dart';
import 'package:smooflow/screens/desktop/dashboard/views/admin_overview_view.dart';
import 'package:smooflow/screens/desktop/dashboard/views/design_overview_view.dart';
import 'package:smooflow/screens/desktop/dashboard/views/production_overview_view.dart';
import 'package:smooflow/screens/desktop/dashboard/views/accounts_overview_view.dart';
import 'package:smooflow/screens/desktop/dashboard/views/minimal_overview_view.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    return Container(
      color: DashboardTokens.canvas,
      child: overviewAsync.when(
        data: (response) => _OverviewContent(response: response),
        loading: () => const _OverviewLoading(),
        error:
            (err, stack) => _OverviewError(
              error: err,
              onRetry: () => ref.invalidate(dashboardOverviewProvider),
            ),
      ),
    );
  }
}

class _OverviewContent extends ConsumerWidget {
  final OverviewResponse response;
  const _OverviewContent({required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardOverviewProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: DashboardTokens.space32,
          vertical: DashboardTokens.space24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OverviewHeader(response: response),
              const SizedBox(height: DashboardTokens.space24),
              _buildRoleView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleView() {
    if (response.admin != null) return AdminOverviewView(data: response.admin!);
    if (response.design != null)
      return DesignOverviewView(data: response.design!);
    if (response.production != null)
      return ProductionOverviewView(data: response.production!);
    if (response.accounts != null)
      return AccountsOverviewView(data: response.accounts!);
    if (response.minimal != null)
      return MinimalOverviewView(data: response.minimal!);
    return const _OverviewEmptyRole();
  }
}

class _OverviewHeader extends StatelessWidget {
  final OverviewResponse response;
  const _OverviewHeader({required this.response});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _roleLabel {
    switch (response.role.toLowerCase()) {
      case 'admin':
        return 'Admin Overview';
      case 'design':
        return 'Design Overview';
      case 'production':
        return 'Production Overview';
      case 'accounts':
        return 'Accounts Overview';
      default:
        return 'Overview';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = DashboardTokens.accentFor(response.role);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_greeting, style: DashboardTokens.bodySm),
            const SizedBox(height: DashboardTokens.space4),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: DashboardTokens.space12),
                Text(_roleLabel, style: DashboardTokens.pageTitle),
              ],
            ),
          ],
        ),
        Text(
          'Updated ${_formatTime(response.generatedAt)}',
          style: DashboardTokens.caption,
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}

class _OverviewLoading extends StatelessWidget {
  const _OverviewLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: DashboardTokens.space16),
          Text('Loading your overview…', style: DashboardTokens.bodySm),
        ],
      ),
    );
  }
}

class _OverviewError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _OverviewError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 32,
            color: DashboardTokens.textTertiary,
          ),
          const SizedBox(height: DashboardTokens.space12),
          Text(
            'Couldn\'t load the dashboard',
            style: DashboardTokens.cardTitle,
          ),
          const SizedBox(height: DashboardTokens.space4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              '$error',
              style: DashboardTokens.bodySm,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: DashboardTokens.space16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _OverviewEmptyRole extends StatelessWidget {
  const _OverviewEmptyRole();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No dashboard is configured for this role yet.',
        style: DashboardTokens.bodySm,
      ),
    );
  }
}
