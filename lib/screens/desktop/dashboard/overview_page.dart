// lib/screens/desktop/dashboard/overview_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/dashboard/overview_response.dart';
import 'package:smooflow/providers/dashboard_provider.dart';
import 'package:smooflow/screens/desktop/dashboard/components/dashboard_components.dart';
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
      color: DashTheme.slate50,
      child: overviewAsync.when(
        data: (response) => _OverviewContent(response: response),
        loading: () => const _OverviewLoading(),
        error:
            (err, stack) => DashErrorState(
              message: '$err',
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
      color: DashTheme.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OverviewHeader(response: response),
              const SizedBox(height: 22),
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
    return DashEmptyState(
      title: 'No dashboard configured',
      subtitle: 'This role doesn\'t have an overview set up yet',
      icon: Icons.dashboard_customize_outlined,
    );
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
        return 'Overview';
      case 'design':
        return 'Design Queue';
      case 'production':
        return 'Production Floor';
      case 'accounts':
        return 'Accounts';
      default:
        return 'Overview';
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final accent = DashTheme.accentFor(response.role);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 30,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_greeting · $_roleLabel',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: DashTheme.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Updated ${_formatTime(response.generatedAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: DashTheme.slate400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
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
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: DashTheme.blue,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Loading your overview…',
            style: TextStyle(
              fontSize: 13,
              color: DashTheme.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
