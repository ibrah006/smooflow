// providers/pricing_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/pricing.dart';
import 'package:smooflow/core/repositories/pricing_repo.dart';

final pricingNotifierProvider =
    StateNotifierProvider<PricingNotifier, List<Pricing>>((ref) {
      return PricingNotifier();
    });

// Provider for getting pricing by ID
final pricingByIdProvider = Provider.family<Pricing?, String>((ref, id) {
  final pricingList = ref.watch(pricingNotifierProvider);
  try {
    return pricingList.firstWhere((p) => p.id == id);
  } catch (e) {
    return null;
  }
});

// Provider for getting pricing by description (unique within organization)
final pricingByDescriptionProvider = Provider.family<Pricing?, String>((
  ref,
  description,
) {
  final pricingList = ref.watch(pricingNotifierProvider);
  try {
    return pricingList.firstWhere(
      (p) => p.description.toLowerCase() == description.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
});

// Provider for getting client-specific pricing
final clientPricingProvider =
    Provider.family<PricingCosts, ({String pricingId, String clientId})>((
      ref,
      params,
    ) {
      final pricing = ref.watch(pricingByIdProvider(params.pricingId));
      if (pricing == null) {
        return const PricingCosts(printCost: 0, applicationCost: 0);
      }
      return pricing.getPricingForClient(params.clientId);
    });

class PricingNotifier extends StateNotifier<List<Pricing>> {
  PricingNotifier() : super([]);

  final _api = PricingRepo();

  // Fetch all pricing items for organization
  Future<void> fetchPricing(String organizationId) async {
    try {
      final pricing = await _api.getPricing();
      state = pricing;
    } catch (e) {
      rethrow;
    }
  }

  // Create new pricing item
  Future<Pricing> createPricing(Pricing pricing) async {
    try {
      final created = await _api.createPricing(pricing);
      state = [...state, created];
      return created;
    } catch (e) {
      rethrow;
    }
  }

  // Update pricing item
  Future<Pricing> updatePricing(Pricing pricing) async {
    try {
      final updated = await _api.updatePricing(pricing);
      state = state.map((p) => p.id == updated.id ? updated : p).toList();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  // Delete pricing item
  Future<void> deletePricing(String id) async {
    try {
      await _api.deletePricing(id);
      state = state.where((p) => p.id != id).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Set client-specific pricing
  Future<Pricing> setClientPricing(
    String pricingId,
    String clientId,
    PricingCosts costs,
  ) async {
    try {
      final updated = await _api.setClientPricing(pricingId, clientId, costs);
      state = state.map((p) => p.id == updated.id ? updated : p).toList();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  // Remove client-specific pricing
  Future<Pricing> removeClientPricing(String pricingId, String clientId) async {
    try {
      final updated = await _api.removeClientPricing(pricingId, clientId);
      state = state.map((p) => p.id == updated.id ? updated : p).toList();
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  // Bulk set client pricing
  Future<Pricing> bulkSetClientPricing(
    String pricingId,
    Map<String, PricingCosts> clientPricingMap,
  ) async {
    try {
      final updated = await _api.bulkSetClientPricing(
        pricingId,
        clientPricingMap,
      );
      state = state.map((p) => p.id == updated.id ? updated : p).toList();
      return updated;
    } catch (e) {
      rethrow;
    }
  }
}
