// core/models/pricing.dart
import 'package:smooflow/core/models/organization.dart';

class PricingCosts {
  final double printCost;
  final double applicationCost;

  const PricingCosts({required this.printCost, required this.applicationCost});

  factory PricingCosts.zero() => PricingCosts(printCost: 0, applicationCost: 0);

  // Convenience factory for different service types
  factory PricingCosts.onlyPrint(double cost) =>
      PricingCosts(printCost: cost, applicationCost: 0);

  factory PricingCosts.onlyInstallation(double cost) =>
      PricingCosts(printCost: 0, applicationCost: cost);

  factory PricingCosts.both(double printCost, double applicationCost) =>
      PricingCosts(printCost: printCost, applicationCost: applicationCost);

  // Check service availability
  bool get hasPrintService => printCost > 0;
  bool get hasApplicationService => applicationCost > 0;

  // Total cost for both services
  double get totalCost => printCost + applicationCost;

  Map<String, dynamic> toJson() => {
    'printCost': printCost,
    'applicationCost': applicationCost,
  };

  factory PricingCosts.fromJson(Map<String, dynamic> json) => PricingCosts(
    printCost: (json['printCost'] as num).toDouble(),
    applicationCost: (json['applicationCost'] as num).toDouble(),
  );
}

class Pricing {
  final String id;
  final String description;
  final String organizationId;
  final Organization? organization;
  final Map<String, PricingCosts> clientPrices;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pricing({
    required this.id,
    required this.description,
    required this.organizationId,
    this.organization,
    required this.clientPrices,
    required this.createdAt,
    required this.updatedAt,
  });

  PricingCosts? get defaultPricing {
    return clientPrices["default"];
  }

  factory Pricing.create({
    required String description,
    required String organizationId,
    Map<String, PricingCosts> clientPrices = const {},
  }) {
    final now = DateTime.now();
    return Pricing(
      id: '',
      description: description,
      organizationId: organizationId,
      clientPrices: clientPrices,
      createdAt: now,
      updatedAt: now,
    );
  }

  // To ensure toSet gives no duplicates
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pricing && runtimeType == other.runtimeType && id == other.id;
  @override
  int get hashCode => id.hashCode;

  // Helper to get pricing for a specific client
  PricingCosts getPricingForClient(String clientId) {
    // Return client-specific pricing if exists, otherwise default
    return clientPrices[clientId] ??
        clientPrices['default'] ??
        const PricingCosts(printCost: 0, applicationCost: 0);
  }

  // Helper to check if client has custom pricing
  bool hasCustomPricing(String clientId) => clientPrices.containsKey(clientId);

  // Helper to get all clients with custom pricing (excluding default)
  List<String> get clientsWithCustomPricing =>
      clientPrices.keys.where((key) => key != 'default').toList();

  // Helper to set client pricing
  Pricing copyWithClientPricing(String clientId, PricingCosts costs) {
    final newPrices = Map<String, PricingCosts>.from(clientPrices);
    newPrices[clientId] = costs;
    return Pricing(
      id: id,
      description: description,
      organizationId: organizationId,
      organization: organization,
      clientPrices: newPrices,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper to remove client pricing (revert to default)
  Pricing removeClientPricing(String clientId) {
    final newPrices = Map<String, PricingCosts>.from(clientPrices);
    newPrices.remove(clientId);
    return Pricing(
      id: id,
      description: description,
      organizationId: organizationId,
      organization: organization,
      clientPrices: newPrices,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper to update default pricing
  Pricing copyWithDefaultPricing(PricingCosts costs) {
    return copyWithClientPricing('default', costs);
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'organizationId': organizationId,
    'clientPrices': clientPrices.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Pricing.fromJson(Map<String, dynamic> json) => Pricing(
    id: json['id'],
    description: json['description'],
    organizationId: json['organizationId'],
    organization:
        json['organization'] != null
            ? Organization.fromJson(json['organization'])
            : null,
    clientPrices:
        (json['clientPrices'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, PricingCosts.fromJson(value)),
        ) ??
        {},
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
