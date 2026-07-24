// lib/repositories/dashboard_repository.dart
import 'package:http/http.dart' as http;
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/dashboard/overview_response.dart';

/// Repository for dashboard-related API endpoints.
///
/// Handles all dashboard data fetching and decoding. Centralizes
/// dashboard API calls in one place for easy maintenance and testing.
class DashboardRepository {
  DashboardRepository._();

  /// Fetches the role-scoped dashboard overview.
  ///
  /// Returns an [OverviewResponse] containing:
  /// - Role identifier from the API
  /// - Generated timestamp
  /// - A section matching the user's role (admin, design, production, accounts, minimal)
  ///
  /// Throws on network error or decode failure.
  static Future<OverviewResponse> overview() async {
    try {
      final response = await ApiClient.http.get('/dashboard/overview');

      if (response.statusCode == 200) {
        return OverviewResponse.fromJson(response.body);
      } else {
        throw Exception(
          'Failed to fetch dashboard overview: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Dashboard overview error: $e');
    }
  }

  // Future endpoints (placeholder):
  // - tasksByProject()
  // - printerUtilization()
  // - materialForecast()
  // - projectFinancialsSummary()
}
