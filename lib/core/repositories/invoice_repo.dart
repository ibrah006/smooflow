// ─────────────────────────────────────────────────────────────────────────────
// lib/repositories/invoice_repository.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_database.dart';
import '../../core/models/invoice.dart';

const _uuid = Uuid();

class InvoiceRepository {
  final AppDatabase _db;

  InvoiceRepository(this._db);

  // ─── INVOICE NUMBER GENERATION ──────────────────────────────────────────
  Future<String> generateInvoiceNumber() async {
    final count = await _db.invoices.count().getSingle();
    final year = DateTime.now().year;
    return 'INV-$year-${(count + 1).toString().padLeft(4, '0')}';
  }

  // ─── CREATE / UPDATE ────────────────────────────────────────────────────

  Future<String> saveInvoice({
    String? id,
    required String clientId,
    required String clientName,
    String? clientEmail,
    String? clientAddress,
    String? clientTrn,
    required InvoiceStatus status,
    required DateTime issueDate,
    required DateTime dueDate,
    required double taxRate,
    required double discountAmount,
    required String organizationId,
    required String createdById,
    String? notes,
    String? terms,
    required List<LineItemForm> lineItems,
  }) async {
    final invoiceId = id ?? _uuid.v4();
    final invoiceNumber = id != null
        ? (await (_db.select(_db.invoices)..where((f) => f.id.equals(id))).getSingle()).invoiceNumber
        : await generateInvoiceNumber();

    final subtotal = lineItems.fold<double>(0, (s, i) => s + i.total);
    final taxAmount = subtotal * (taxRate / 100);
    final totalAmount = subtotal + taxAmount - discountAmount;

    // Get existing paid amount
    double amountPaid = 0;
    if (id != null) {
      final existing = await getInvoiceById(id);
      amountPaid = existing?.amountPaid ?? 0;
    }

    await _db.into(_db.invoices).insertOnConflictUpdate(InvoicesCompanion(
          id: Value(invoiceId),
          invoiceNumber: Value(invoiceNumber),
          clientId: Value(clientId),
          clientName: Value(clientName),
          clientEmail: Value(clientEmail),
          clientAddress: Value(clientAddress),
          clientTrn: Value(clientTrn),
          status: Value(status),
          issueDate: Value(issueDate),
          dueDate: Value(dueDate),
          subtotal: Value(subtotal),
          taxRate: Value(taxRate),
          taxAmount: Value(taxAmount),
          discountAmount: Value(discountAmount),
          totalAmount: Value(totalAmount),
          amountPaid: Value(amountPaid),
          amountDue: Value(totalAmount - amountPaid),
          notes: Value(notes),
          terms: Value(terms),
          organizationId: Value(organizationId),
          createdById: Value(createdById),
          updatedAt: Value(DateTime.now()),
        ));

    // Replace line items
    await (_db.delete(_db.invoiceLineItems)
          ..where((t) => t.invoiceId.equals(invoiceId)))
        .go();

    for (var i = 0; i < lineItems.length; i++) {
      final item = lineItems[i];
      await _db.into(_db.invoiceLineItems).insert(InvoiceLineItemsCompanion(
            id: Value(item.id),
            invoiceId: Value(invoiceId),
            description: Value(item.description),
            unit: Value(item.unit),
            quantity: Value(item.quantity),
            unitPrice: Value(item.unitPrice),
            total: Value(item.total),
            sortOrder: Value(i),
          ));
    }

    return invoiceId;
  }

  // ─── READ ────────────────────────────────────────────────────────────────

  Future<InvoiceModel?> getInvoiceById(String id) async {
    final invoice =
        await (_db.select(_db.invoices)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    if (invoice == null) return null;

    final items = await (_db.select(_db.invoiceLineItems)
          ..where((t) => t.invoiceId.equals(id))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();

    final payments = await (_db.select(_db.payments)
          ..where((t) => t.invoiceId.equals(id))
          ..orderBy([(t) => OrderingTerm(expression: t.paidAt, mode: OrderingMode.desc)]))
        .get();

    return InvoiceModel(invoice: invoice, lineItems: items, payments: payments);
  }

  Stream<List<Invoice>> watchInvoices({InvoiceStatus? status, String? search}) {
    final query = _db.select(_db.invoices);
    query.orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    return query.watch().map((list) {
      var filtered = list;
      if (status != null) {
        filtered = filtered.where((i) => i.status == status).toList();
      }
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        filtered = filtered
            .where((i) =>
                i.invoiceNumber.toLowerCase().contains(q) ||
                i.clientName.toLowerCase().contains(q))
            .toList();
      }
      return filtered;
    });
  }

  Future<List<Invoice>> getOverdueInvoices() async {
    final all = await _db.select(_db.invoices).get();
    final now = DateTime.now();
    return all
        .where((i) =>
            i.status != InvoiceStatus.paid &&
            i.status != InvoiceStatus.cancelled &&
            i.dueDate.isBefore(now))
        .toList();
  }

  // ─── STATUS UPDATES ──────────────────────────────────────────────────────

  Future<void> updateStatus(String id, InvoiceStatus status) async {
    await (_db.update(_db.invoices)..where((t) => t.id.equals(id)))
        .write(InvoicesCompanion(
      status: Value(status),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> deleteInvoice(String id) async {
    await (_db.delete(_db.invoices)..where((t) => t.id.equals(id))).go();
  }

  Future<void> bulkUpdateStatus(List<String> ids, InvoiceStatus status) async {
    for (final id in ids) {
      await updateStatus(id, status);
    }
  }

  // ─── STATS ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    final all = await _db.select(_db.invoices).get();
    final now = DateTime.now();

    final totalOutstanding = all
        .where((i) => i.status != InvoiceStatus.paid && i.status != InvoiceStatus.cancelled)
        .fold<double>(0, (s, i) => s + i.amountDue);

    final totalOverdue = all
        .where((i) =>
            i.status != InvoiceStatus.paid &&
            i.status != InvoiceStatus.cancelled &&
            i.dueDate.isBefore(now))
        .fold<double>(0, (s, i) => s + i.amountDue);

    final totalPaidThisMonth = all
        .where((i) =>
            i.status == InvoiceStatus.paid &&
            i.updatedAt.month == now.month &&
            i.updatedAt.year == now.year)
        .fold<double>(0, (s, i) => s + i.amountPaid);

    final drafts = all.where((i) => i.status == InvoiceStatus.draft).length;

    return {
      'totalOutstanding': totalOutstanding,
      'totalOverdue': totalOverdue,
      'totalPaidThisMonth': totalPaidThisMonth,
      'draftCount': drafts,
      'invoiceCount': all.length,
    };
  }
}