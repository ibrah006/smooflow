// lib/core/models/dashboard/overview_response.dart
import 'dart:convert';
import 'package:smooflow/core/models/dashboard/admin_overview.dart';
import 'package:smooflow/core/models/dashboard/design_overview.dart';
import 'package:smooflow/core/models/dashboard/production_overview.dart';
import 'package:smooflow/core/models/dashboard/accounts_overview.dart';
import 'package:smooflow/core/models/dashboard/minimal_overview.dart';

class OverviewResponse {
  final String role;
  final DateTime generatedAt;

  /// Role-specific payload — only one of these will be non-null
  /// based on the user's role returned by the API.
  final AdminOverview? admin;
  final DesignOverview? design;
  final ProductionOverview? production;
  final AccountsOverview? accounts;
  final MinimalOverview? minimal;

  OverviewResponse({
    required this.role,
    required this.generatedAt,
    this.admin,
    this.design,
    this.production,
    this.accounts,
    this.minimal,
  });

  /// Decodes a JSON string into an [OverviewResponse].
  ///
  /// Parses the role from the JSON, then conditionally decodes only the
  /// section matching that role. This avoids trying to deserialize empty/null
  /// sections and keeps null checks tight in the UI layer.
  factory OverviewResponse.fromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    final role = json['role'] as String? ?? '';
    final generatedAt = DateTime.parse(json['generatedAt'] as String);

    AdminOverview? admin;
    DesignOverview? design;
    ProductionOverview? production;
    AccountsOverview? accounts;
    MinimalOverview? minimal;

    switch (role.toLowerCase()) {
      case 'admin':
        if (json['admin'] != null) {
          admin = AdminOverview.fromJson(json['admin'] as Map<String, dynamic>);
        }
        break;

      case 'design':
        if (json['design'] != null) {
          design = DesignOverview.fromJson(
            json['design'] as Map<String, dynamic>,
          );
        }
        break;

      case 'production':
        if (json['production'] != null) {
          production = ProductionOverview.fromJson(
            json['production'] as Map<String, dynamic>,
          );
        }
        break;

      case 'accounts':
        if (json['accounts'] != null) {
          accounts = AccountsOverview.fromJson(
            json['accounts'] as Map<String, dynamic>,
          );
        }
        break;

      default:
        if (json['minimal'] != null) {
          minimal = MinimalOverview.fromJson(
            json['minimal'] as Map<String, dynamic>,
          );
        }
        break;
    }

    return OverviewResponse(
      role: role,
      generatedAt: generatedAt,
      admin: admin,
      design: design,
      production: production,
      accounts: accounts,
      minimal: minimal,
    );
  }

  /// Convenience getter: returns the active payload for this role.
  ///
  /// Useful in the UI layer to avoid null-checking multiple sections.
  /// Example: `final overview = response.payload as AdminOverview;`
  Object? get payload => admin ?? design ?? production ?? accounts ?? minimal;
}
