// lib/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/dashboard/overview_response.dart';
import 'package:smooflow/core/repositories/dashboard_repo.dart';

final dashboardOverviewProvider = FutureProvider<OverviewResponse>((ref) async {
  return await DashboardRepository.overview();
});
