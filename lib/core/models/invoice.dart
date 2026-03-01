// ─────────────────────────────────────────────────────────────────────────────
// lib/models/invoice_model.dart
// ─────────────────────────────────────────────────────────────────────────────
import '../../core/app_database.dart';

class InvoiceModel {
  final Invoice invoice;
  final List<InvoiceLineItem> lineItems;
  final List<Payment> payments;

  const InvoiceModel({
    required this.invoice,
    required this.lineItems,
    required this.payments,
  });

  double get subtotal =>
      lineItems.fold(0, (sum, item) => sum + item.total);

  double get taxAmount => subtotal * (invoice.taxRate / 100);

  double get totalAmount => subtotal + taxAmount - invoice.discountAmount;

  double get amountPaid =>
      payments.fold(0, (sum, p) => sum + p.amount);

  double get amountDue => totalAmount - amountPaid;

  bool get isFullyPaid => amountDue <= 0;

  bool get isPartiallyPaid => amountPaid > 0 && amountDue > 0;

  bool get isOverdue =>
      invoice.status != InvoiceStatus.paid &&
      invoice.status != InvoiceStatus.cancelled &&
      DateTime.now().isAfter(invoice.dueDate);

  InvoiceModel copyWith({
    Invoice? invoice,
    List<InvoiceLineItem>? lineItems,
    List<Payment>? payments,
  }) {
    return InvoiceModel(
      invoice: invoice ?? this.invoice,
      lineItems: lineItems ?? this.lineItems,
      payments: payments ?? this.payments,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/models/line_item_form.dart
// Mutable form model used in create/edit screens
// ─────────────────────────────────────────────────────────────────────────────
class LineItemForm {
  String id;
  String description;
  String unit;
  double quantity;
  double unitPrice;

  LineItemForm({
    required this.id,
    this.description = '',
    this.unit = '',
    this.quantity = 1,
    this.unitPrice = 0,
  });

  double get total => quantity * unitPrice;

  LineItemForm copyWith({
    String? description,
    String? unit,
    double? quantity,
    double? unitPrice,
  }) {
    return LineItemForm(
      id: id,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}