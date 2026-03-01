// ─────────────────────────────────────────────────────────────────────────────
// lib/providers/accounts_providers.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/app_database.dart';
import 'package:smooflow/core/models/invoice.dart';
import 'package:smooflow/core/repositories/invoice_repo.dart';
import 'package:smooflow/core/repositories/payment_repo.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─── CORE PROVIDERS ──────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(ref.watch(appDatabaseProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(appDatabaseProvider));
});

// ─── INVOICE LIST ─────────────────────────────────────────────────────────────

final invoiceFilterProvider = StateProvider<InvoiceStatus?>((ref) => null);
final invoiceSearchProvider = StateProvider<String>((ref) => '');

final invoicesStreamProvider = StreamProvider<List<Invoice>>((ref) {
  final repo = ref.watch(invoiceRepositoryProvider);
  final status = ref.watch(invoiceFilterProvider);
  final search = ref.watch(invoiceSearchProvider);
  return repo.watchInvoices(status: status, search: search);
});

// ─── INVOICE DETAIL ───────────────────────────────────────────────────────────

final invoiceDetailProvider =
    FutureProvider.family<InvoiceModel?, String>((ref, id) async {
  return ref.watch(invoiceRepositoryProvider).getInvoiceById(id);
});

// ─── DASHBOARD STATS ─────────────────────────────────────────────────────────

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(invoiceRepositoryProvider).getDashboardStats();
});

// ─── PAYMENTS STREAM ─────────────────────────────────────────────────────────

final paymentsStreamProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(paymentRepositoryProvider).watchAllPayments();
});

// ─── INVOICE FORM NOTIFIER ───────────────────────────────────────────────────
// Holds the mutable state of the create/edit invoice form

class InvoiceFormState {
  final String? editingId;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientAddress;
  final String clientTrn;
  final DateTime issueDate;
  final DateTime dueDate;
  final double taxRate;
  final double discountAmount;
  final String notes;
  final String terms;
  final List<LineItemForm> lineItems;
  final bool isSaving;
  final String? errorMessage;

  const InvoiceFormState({
    this.editingId,
    this.clientId = '',
    this.clientName = '',
    this.clientEmail = '',
    this.clientAddress = '',
    this.clientTrn = '',
    DateTime? issueDate,
    DateTime? dueDate,
    this.taxRate = 5.0,
    this.discountAmount = 0,
    this.notes = '',
    this.terms = 'Payment is due within 30 days of the invoice date.',
    List<LineItemForm>? lineItems,
    this.isSaving = false,
    this.errorMessage,
  })  : issueDate = issueDate ?? const _Now(),
        dueDate = dueDate ?? const _Now30(),
        lineItems = lineItems ?? const [];

  double get subtotal => lineItems.fold(0, (s, i) => s + i.total);
  double get taxAmount => subtotal * (taxRate / 100);
  double get totalAmount => subtotal + taxAmount - discountAmount;

  InvoiceFormState copyWith({
    String? editingId,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? clientAddress,
    String? clientTrn,
    DateTime? issueDate,
    DateTime? dueDate,
    double? taxRate,
    double? discountAmount,
    String? notes,
    String? terms,
    List<LineItemForm>? lineItems,
    bool? isSaving,
    String? errorMessage,
  }) {
    return InvoiceFormState(
      editingId: editingId ?? this.editingId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientAddress: clientAddress ?? this.clientAddress,
      clientTrn: clientTrn ?? this.clientTrn,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      taxRate: taxRate ?? this.taxRate,
      discountAmount: discountAmount ?? this.discountAmount,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      lineItems: lineItems ?? this.lineItems,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

// Helpers for default dates (can't call DateTime.now() in const)
class _Now implements DateTime {
  const _Now();
  // Dart won't let us extend DateTime in const — use factory below
  @override
  noSuchMethod(i) => super.noSuchMethod(i);
}

class _Now30 implements DateTime {
  const _Now30();
  @override
  noSuchMethod(i) => super.noSuchMethod(i);
}

// ─── ACTUAL NOTIFIER ─────────────────────────────────────────────────────────

class InvoiceFormNotifier extends StateNotifier<InvoiceFormState> {
  final InvoiceRepository _repo;
  final String organizationId;
  final String createdById;

  InvoiceFormNotifier(this._repo, this.organizationId, this.createdById)
      : super(InvoiceFormState(
          issueDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 30)),
          lineItems: [
            LineItemForm(id: const Uuid().v4()),
          ],
        ));

  // Load existing invoice for editing
  Future<void> loadInvoice(InvoiceModel model) async {
    state = InvoiceFormState(
      editingId: model.invoice.id,
      clientId: model.invoice.clientId,
      clientName: model.invoice.clientName,
      clientEmail: model.invoice.clientEmail ?? '',
      clientAddress: model.invoice.clientAddress ?? '',
      clientTrn: model.invoice.clientTrn ?? '',
      issueDate: model.invoice.issueDate,
      dueDate: model.invoice.dueDate,
      taxRate: model.invoice.taxRate,
      discountAmount: model.invoice.discountAmount,
      notes: model.invoice.notes ?? '',
      terms: model.invoice.terms ?? '',
      lineItems: model.lineItems
          .map((i) => LineItemForm(
                id: i.id,
                description: i.description,
                unit: i.unit ?? '',
                quantity: i.quantity,
                unitPrice: i.unitPrice,
              ))
          .toList(),
    );
  }

  void updateClient({
    required String id,
    required String name,
    String email = '',
    String address = '',
    String trn = '',
  }) {
    state = state.copyWith(
      clientId: id,
      clientName: name,
      clientEmail: email,
      clientAddress: address,
      clientTrn: trn,
    );
  }

  void updateField({
    DateTime? issueDate,
    DateTime? dueDate,
    double? taxRate,
    double? discountAmount,
    String? notes,
    String? terms,
  }) {
    state = state.copyWith(
      issueDate: issueDate,
      dueDate: dueDate,
      taxRate: taxRate,
      discountAmount: discountAmount,
      notes: notes,
      terms: terms,
    );
  }

  void addLineItem() {
    final items = [...state.lineItems, LineItemForm(id: _uuid.v4())];
    state = state.copyWith(lineItems: items);
  }

  void updateLineItem(int index, LineItemForm updated) {
    final items = [...state.lineItems];
    items[index] = updated;
    state = state.copyWith(lineItems: items);
  }

  void removeLineItem(int index) {
    final items = [...state.lineItems]..removeAt(index);
    state = state.copyWith(lineItems: items);
  }

  void reorderLineItems(int oldIndex, int newIndex) {
    final items = [...state.lineItems];
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = state.copyWith(lineItems: items);
  }

  Future<String?> saveDraft() => _save(InvoiceStatus.draft);

  Future<String?> sendInvoice() => _save(InvoiceStatus.sent);

  Future<String?> _save(InvoiceStatus status) async {
    if (state.clientName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please select or enter a client.');
      return null;
    }
    if (state.lineItems.isEmpty ||
        state.lineItems.every((i) => i.description.trim().isEmpty)) {
      state = state.copyWith(errorMessage: 'Add at least one line item.');
      return null;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final id = await _repo.saveInvoice(
        id: state.editingId,
        clientId: state.clientId,
        clientName: state.clientName,
        clientEmail: state.clientEmail,
        clientAddress: state.clientAddress,
        clientTrn: state.clientTrn,
        status: status,
        issueDate: state.issueDate,
        dueDate: state.dueDate,
        taxRate: state.taxRate,
        discountAmount: state.discountAmount,
        organizationId: organizationId,
        createdById: createdById,
        notes: state.notes,
        terms: state.terms,
        lineItems: state.lineItems,
      );
      state = state.copyWith(isSaving: false, editingId: id);
      return id;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return null;
    }
  }
}

final invoiceFormProvider = StateNotifierProvider.autoDispose
    .family<InvoiceFormNotifier, InvoiceFormState, Map<String, String>>(
        (ref, params) {
  return InvoiceFormNotifier(
    ref.watch(invoiceRepositoryProvider),
    params['organizationId'] ?? '',
    params['userId'] ?? '',
  );
});

// ─── BULK SELECTION ──────────────────────────────────────────────────────────

final selectedInvoicesProvider = StateProvider<Set<String>>((ref) => {});