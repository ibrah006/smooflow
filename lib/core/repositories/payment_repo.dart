// ─────────────────────────────────────────────────────────────────────────────
// lib/repositories/payment_repository.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:drift/drift.dart';
import 'package:smooflow/core/app_database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class PaymentRepository {
  final AppDatabase _db;

  PaymentRepository(this._db);

  Future<String> _generateReceiptNumber() async {
    final count = await _db.payments.count().getSingle();
    final year = DateTime.now().year;
    return 'REC-$year-${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<Payment> recordPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    String? reference,
    String? notes,
    DateTime? paidAt,
  }) async {
    final receiptNumber = await _generateReceiptNumber();
    final id = _uuid.v4();
    final paymentDate = paidAt ?? DateTime.now();

    await _db.into(_db.payments).insert(PaymentsCompanion(
          id: Value(id),
          invoiceId: Value(invoiceId),
          receiptNumber: Value(receiptNumber),
          amount: Value(amount),
          method: Value(method),
          reference: Value(reference),
          notes: Value(notes),
          paidAt: Value(paymentDate),
        ));

    // Update invoice amountPaid and amountDue
    final invoice =
        await (_db.select(_db.invoices)..where((t) => t.id.equals(invoiceId)))
            .getSingle();

    final allPayments = await (_db.select(_db.payments)
          ..where((t) => t.invoiceId.equals(invoiceId)))
        .get();

    final totalPaid = allPayments.fold<double>(0, (s, p) => s + p.amount);
    final amountDue = invoice.totalAmount - totalPaid;

    InvoiceStatus newStatus;
    if (amountDue <= 0) {
      newStatus = InvoiceStatus.paid;
    } else if (totalPaid > 0) {
      newStatus = InvoiceStatus.partiallyPaid;
    } else {
      newStatus = invoice.status;
    }

    await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId)))
        .write(InvoicesCompanion(
      amountPaid: Value(totalPaid),
      amountDue: Value(amountDue < 0 ? 0 : amountDue),
      status: Value(newStatus),
      updatedAt: Value(DateTime.now()),
    ));

    return (await (_db.select(_db.payments)..where((t) => t.id.equals(id)))
        .getSingle());
  }

  Future<List<Payment>> getPaymentsForInvoice(String invoiceId) async {
    return (_db.select(_db.payments)
          ..where((t) => t.invoiceId.equals(invoiceId))
          ..orderBy([(t) => OrderingTerm(expression: t.paidAt, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<List<Payment>> watchAllPayments() {
    return (_db.select(_db.payments)
          ..orderBy([(t) => OrderingTerm(expression: t.paidAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<void> deletePayment(String paymentId) async {
    final payment = await (_db.select(_db.payments)
          ..where((t) => t.id.equals(paymentId)))
        .getSingle();

    await (_db.delete(_db.payments)..where((t) => t.id.equals(paymentId))).go();

    // Recalculate invoice
    final allPayments = await (_db.select(_db.payments)
          ..where((t) => t.invoiceId.equals(payment.invoiceId)))
        .get();

    final invoice = await (_db.select(_db.invoices)
          ..where((t) => t.id.equals(payment.invoiceId)))
        .getSingle();

    final totalPaid = allPayments.fold<double>(0, (s, p) => s + p.amount);
    final amountDue = invoice.totalAmount - totalPaid;

    InvoiceStatus newStatus;
    if (totalPaid <= 0) {
      newStatus = InvoiceStatus.sent;
    } else if (amountDue > 0) {
      newStatus = InvoiceStatus.partiallyPaid;
    } else {
      newStatus = InvoiceStatus.paid;
    }

    await (_db.update(_db.invoices)..where((t) => t.id.equals(payment.invoiceId)))
        .write(InvoicesCompanion(
      amountPaid: Value(totalPaid),
      amountDue: Value(amountDue < 0 ? 0 : amountDue),
      status: Value(newStatus),
      updatedAt: Value(DateTime.now()),
    ));
  }
}