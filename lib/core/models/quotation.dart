import 'package:smooflow/core/models/quotation_line_item.dart';
import 'package:smooflow/screens/desktop/accounts_management_screen.dart';

class Quotation {
  late final String id;
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

  DateTime updatedAt;

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
    required this.updatedAt,
  });

  Quotation.create({
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
  }) : updatedAt = DateTime.now();

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'number': number,
    'status': status.name,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'clientName': clientName,
    'clientAddress': clientAddress,
    'fromCompanyName': fromCompanyName,
    'fromCompanyAddress': fromCompanyAddress,
    'termsConditions': termsConditions,
    'vatPercentage': vatPercentage,
    'lineItems': lineItems.map((i) => i.toJson()).toList(),
  };

  factory Quotation.fromJson(Map<String, dynamic> json) => Quotation(
    id: json['id'],
    projectId: json['projectId'],
    number: json['number'],
    status: QuotationStatus.values.firstWhere((e) => e.name == json['status']),
    notes: json['notes'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    clientName: json['clientName'],
    clientAddress: json['clientAddress'],
    fromCompanyName: json['fromCompanyName'],
    fromCompanyAddress: json['fromCompanyAddress'],
    termsConditions: json['termsConditions'],
    vatPercentage: (json['vatPercentage'] as num).toDouble(),
    lineItems:
        (json['lineItems'] as List)
            .map((i) => QuotationLineItem.fromJson(i))
            .toList(),
  );
}
