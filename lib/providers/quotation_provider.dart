import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/websocket_clients/quotation_websocket.dart';
import 'package:smooflow/core/models/quotation.dart';
import 'package:smooflow/core/models/quotation_line_item.dart';
import 'package:smooflow/core/repositories/quotation_repo.dart';
import 'package:smooflow/screens/desktop/accounts_management_screen.dart';

// final quotationApiProvider = Provider((ref) => QuotationRepo());

final quotationWebSocketClientProvider = Provider<QuotationWebSocketClient>((
  ref,
) {
  final client = QuotationWebSocketClient();

  client.connect();

  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

final quotationConnectionStatusProvider = StreamProvider<ConnectionStatus>((
  ref,
) {
  final client = ref.watch(quotationWebSocketClientProvider);
  return client.connectionStatus;
});

final quotationChangesStreamProvider = StreamProvider<QuotationChangeEvent>((
  ref,
) {
  final client = ref.watch(quotationWebSocketClientProvider);
  return client.quotationChanges;
});

final quotationNotifierProvider =
    StateNotifierProvider<QuotationNotifier, List<Quotation>>((ref) {
      return QuotationNotifier(ref.read(quotationWebSocketClientProvider));
    });

class QuotationNotifier extends StateNotifier<List<Quotation>> {
  final QuotationRepo _api = QuotationRepo();

  final QuotationWebSocketClient _client;

  QuotationNotifier(this._client) : super([]) {
    _initialize();
  }

  void _initialize() {
    _client.quotationChanges.listen((event) {
      switch (event.type) {
        case QuotationChangeType.created:
          // If already exists in local memory (if this create was initiated in the same device)
          // Best practice is to remove it because calling quotation.id
          // will return temporary id for quotations that were just created
          // until the quotation is initialized in server,
          // after which the actual quotation id is returned
          final quotationIndex = state.indexWhere(
            (q) => q.number == event.quotation.number,
          );

          if (quotationIndex != -1) state.removeAt(quotationIndex);

          state.insert(0, event.quotation);
          state = [...state];
          break;
        case QuotationChangeType.updated:
          print("update event: ${event.quotation.toJson()}");
          state =
              state.map((q) {
                if (q.id == event.quotation.id) {
                  return event.quotation;
                }
                return q;
              }).toList();
          break;
        case QuotationChangeType.deleted:
          state = state.where((p) => p.id == event.quotation.id).toList();
      }
    });

    _client.errors.listen((error) {
      // state = state.copyWith(error: error, isLoading: false);
    });
  }

  Future<List<Quotation>> fetchQuotations() async {
    final quotations = await _api.getQuotations();
    state = quotations;

    return state;
  }

  Future<Quotation> createQuotation(Quotation data) async {
    final created = await _api.createQuotation(data.toJson());
    // WebSocket will add it, but we can optimistically update
    // state = [created, ...state];
    return created;
  }

  Future<Quotation> updateQuotation(
    String id, {
    String? number,
    QuotationStatus? status,
    String? notes,
    String? clientName,
    String? clientAddress,
    String? fromCompanyName,
    String? fromCompanyAddress,
    String? termsConditions,
    double? vatPercentage,
    List<QuotationLineItem>? lineItems,
  }) async {
    // Build the payload dynamically
    final Map<String, dynamic> payload = {};

    state =
        {
          state.firstWhere((q) => q.id == id).update(isLoading: true),
          ...state,
        }.toList();

    if (number != null) payload['number'] = number;
    if (status != null)
      payload['status'] = status.name; // or whatever API expects
    if (notes != null) payload['notes'] = notes;
    if (clientName != null) payload['clientName'] = clientName;
    if (clientAddress != null) payload['clientAddress'] = clientAddress;
    if (fromCompanyName != null) payload['fromCompanyName'] = fromCompanyName;
    if (fromCompanyAddress != null)
      payload['fromCompanyAddress'] = fromCompanyAddress;
    if (termsConditions != null) payload['termsConditions'] = termsConditions;
    if (vatPercentage != null) payload['vatPercentage'] = vatPercentage;
    if (lineItems != null)
      payload['lineItems'] = lineItems.map((e) => e.toJson()).toList();

    final updated = await _api.updateQuotation(id, payload);

    // Update local state if needed
    // state = state.map((q) => q.id == id ? updated : q).toList();

    return updated;
  }

  Future<void> deleteQuotation(String id) async {
    await _api.deleteQuotation(id);
    // WebSocket will remove it, but we can optimistically update
    // state = state.where((q) => q.id != id).toList();
  }
}
