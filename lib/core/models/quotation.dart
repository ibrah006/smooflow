import 'package:smooflow/core/models/quotation_line_item.dart';
import 'package:smooflow/screens/desktop/accounts_management_screen.dart';

class Quotation {
  final String id;
  final String projectId;
  List<QuotationLineItem> lineItems;
  QuotationStatus status;
  String notes;
  final DateTime createdAt;
  final String number;
  double vatPercentage;
  String clientName;
  String clientAddress;
  String fromCompanyName;
  String fromCompanyAddress;
  String termsConditions;

  double get total => lineItems.fold(0, (s, i) => s + i.amount);

  Quotation({
    required this.id,
    required this.projectId,
    required this.lineItems,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.number,
    this.vatPercentage = 5.0,
    required this.clientName,
    required this.clientAddress,
    required this.fromCompanyName,
    required this.fromCompanyAddress,
    required this.termsConditions,
  });
}
