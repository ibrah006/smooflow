// providers/pricing_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/models/pricing.dart';
import 'package:smooflow/core/repositories/pricing_repo.dart';
import 'package:smooflow/core/api/websocket_clients/pricing_websocket.dart';
import 'package:smooflow/states/pricing_state.dart';

// final pricingNotifierProvider =
//     StateNotifierProvider<PricingNotifier, List<Pricing>>((ref) {
//       return PricingNotifier();
//     });

// Provider for getting pricing by ID
// final pricingByIdProvider = Provider.family<Pricing?, String>((ref, id) {
//   final pricingList = ref.watch(pricingNotifierProvider);
//   try {
//     return pricingList.firstWhere((p) => p.id == id);
//   } catch (e) {
//     return null;
//   }
// });

// Provider for getting pricing by description (unique within organization)
// final pricingByDescriptionProvider = Provider.family<Pricing?, String>((
//   ref,
//   description,
// ) {
//   final pricingList = ref.watch(pricingNotifierProvider);
//   try {
//     return pricingList.firstWhere(
//       (p) => p.description.toLowerCase() == description.toLowerCase(),
//     );
//   } catch (e) {
//     return null;
//   }
// });

// Provider for getting client-specific pricing
// final clientPricingProvider =
//     Provider.family<PricingCosts, ({String pricingId, String clientId})>((
//       ref,
//       params,
//     ) {
//       final pricing = ref.watch(pricingByIdProvider(params.pricingId));
//       if (pricing == null) {
//         return const PricingCosts(printCost: 0, applicationCost: 0);
//       }
//       return pricing.getPricingForClient(params.clientId);
//     });

final pricingWebSocketClientProvider = Provider<PricingWebSocketClient>((ref) {
  final client = PricingWebSocketClient();

  client.connect();

  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

final pricingConnectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final client = ref.watch(pricingWebSocketClientProvider);
  return client.connectionStatus;
});

final pricingChangesStreamProvider = StreamProvider<PricingChangeEvent>((ref) {
  final client = ref.watch(pricingWebSocketClientProvider);
  return client.pricingChanges;
});

final pricingStateProvider =
    StateNotifierProvider<PricingNotifier, PricingState>((ref) {
      final client = ref.watch(pricingWebSocketClientProvider);
      return PricingNotifier(client);
    });

class PricingNotifier extends StateNotifier<PricingState> {
  final PricingWebSocketClient _client;

  final PricingRepo _api = PricingRepo();

  PricingNotifier(this._client) : super(const PricingState()) {
    _initialize();
  }

  void _initialize() {
    _client.pricingChanges.listen((event) {
      // Handle pricing changes
      // ...existing code...
    });

    _client.errors.listen((error) {
      state = state.copyWith(error: error, isLoading: false);
    });
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Fetch all pricing items for organization
  Future<void> fetchPricing(String organizationId) async {
    try {
      final pricing = await _api.getPricing();
      state = state.copyWith(pricingData: pricing);
    } catch (e) {
      rethrow;
    }
  }

  // Create new pricing item
  Future<Pricing> createPricing(Pricing pricing) async {
    try {
      final created = await _api.createPricing(pricing);
      state = state.copyWith(pricingData: [...state.pricingData, created]);
      return created;
    } catch (e) {
      rethrow;
    }
  }

  // Update pricing item
  Future<Pricing> updatePricing(Pricing pricing) async {
    try {
      final updated = await _api.updatePricing(pricing);
      state = state.copyWith(
        pricingData:
            state.pricingData
                .map((p) => p.id == updated.id ? updated : p)
                .toList(),
      );
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  // Delete pricing item
  Future<void> deletePricing(String id) async {
    try {
      await _api.deletePricing(id);
      state = state.copyWith(
        pricingData: state.pricingData.where((p) => p.id != id).toList(),
      );
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
      state = state.copyWith(
        pricingData:
            state.pricingData
                .map((p) => p.id == updated.id ? updated : p)
                .toList(),
      );
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  // Remove client-specific pricing
  Future<Pricing> removeClientPricing(String pricingId, String clientId) async {
    try {
      final updated = await _api.removeClientPricing(pricingId, clientId);
      state = state.copyWith(
        pricingData:
            state.pricingData
                .map((p) => p.id == updated.id ? updated : p)
                .toList(),
      );
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
      state = state.copyWith(
        pricingData:
            state.pricingData
                .map((p) => p.id == updated.id ? updated : p)
                .toList(),
      );
      return updated;
    } catch (e) {
      rethrow;
    }
  }
}
