import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/websocket_clients/quotation_websocket.dart';
import 'package:smooflow/core/models/quotation.dart';
import 'package:smooflow/core/repositories/quotation_repo.dart';

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

final quotationListProvider =
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
    _client.on('quotation:created', (data) {
      final newQuotation = Quotation.fromJson(data);
      state = [newQuotation, ...state];
    });
    _client.on('quotation:updated', (data) {
      final updated = Quotation.fromJson(data);
      state = state.map((q) => q.id == updated.id ? updated : q).toList();
    });
    _client.on('quotation:deleted', (data) {
      state = state.where((q) => q.id != data['id']).toList();
    });
  }

  Future<void> fetchQuotations() async {
    final quotations = await _api.getQuotations();
    state = quotations;
  }

  Future<Quotation> createQuotation(Map<String, dynamic> data) async {
    final created = await _api.createQuotation(data);
    // WebSocket will add it, but we can optimistically update
    state = [created, ...state];
    return created;
  }

  Future<Quotation> updateQuotation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final updated = await _api.updateQuotation(id, data);
    state = state.map((q) => q.id == id ? updated : q).toList();
    return updated;
  }

  Future<void> deleteQuotation(String id) async {
    await _api.deleteQuotation(id);
    // WebSocket will remove it, but we can optimistically update
    state = state.where((q) => q.id != id).toList();
  }
}
