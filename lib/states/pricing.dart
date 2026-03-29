import 'package:smooflow/core/models/pricing.dart';

class PricingState {
  final List<Pricing> pricingData;
  final bool isLoading;
  final String? error;

  const PricingState({
    this.pricingData = const [],
    this.isLoading = false,
    this.error,
  });

  PricingState copyWith({
    List<Pricing>? pricingData,
    bool? isLoading,
    String? error,
  }) {
    return PricingState(
      pricingData: pricingData ?? this.pricingData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  PricingCosts getPricing({required String description, String? clientId}) {
    try {
      final pricing = pricingData.firstWhere(
        (pricing) => description.toLowerCase().trim().toLowerCase().contains(
          pricing.description.toLowerCase().trim(),
        ),
      );

      final customPricing =
          (pricing.clientPrices[clientId] ?? pricing.defaultPricing) ??
          PricingCosts.zero();

      return customPricing;
    } catch (e) {
      return PricingCosts.zero();
    }
  }
}
