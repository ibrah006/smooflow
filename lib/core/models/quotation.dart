import 'package:smooflow/core/models/quotation_line_item.dart';
import 'package:smooflow/screens/desktop/accounts_management_screen.dart';
import 'package:uuid/uuid.dart';

class Quotation {
  late final String _id, tempId;

  String get id {
    try {
      return _id;
    } catch (e) {
      // _id not initialized yet
      return tempId;
    }
  }

  initializeId(String id) {
    _id = id;
    _isLoading = false;
  }

  final String projectId;
  List<QuotationLineItem> lineItems;
  QuotationStatus status;
  String notes;
  final DateTime createdAt;
  String _number;

  String get number => _number;

  double vatPercentage;
  String clientName;
  String clientAddress;
  String fromCompanyName;
  String fromCompanyAddress;
  String termsConditions;

  DateTime updatedAt;

  double get total => lineItems.fold(0, (s, i) => s + i.amount);

  bool _isLoading;

  bool get isLoading => _isLoading;

  Quotation({
    required String id,
    required this.projectId,
    required this.lineItems,
    required this.status,
    required this.notes,
    required this.createdAt,
    required String number,
    this.vatPercentage = 5.0,
    required this.clientName,
    required this.clientAddress,
    required this.fromCompanyName,
    required this.fromCompanyAddress,
    required this.termsConditions,
    required this.updatedAt,
    bool isLoading = false,
  }) : _number = number,
       _id = id,
       _isLoading = isLoading;

  Quotation.create({
    required this.projectId,
    required this.lineItems,
    required this.status,
    required this.notes,
    required this.createdAt,
    required String number,
    this.vatPercentage = 5.0,
    required this.clientName,
    required this.clientAddress,
    required this.fromCompanyName,
    required this.fromCompanyAddress,
    required this.termsConditions,
  }) : _number = number,
       updatedAt = DateTime.now(),
       tempId = Uuid().v1(),
       _isLoading = true;

  Quotation update({
    required bool isLoading,
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
  }) {
    return this
      .._isLoading = isLoading
      .._number = number ?? _number
      ..status = status ?? this.status
      ..notes = notes ?? this.notes
      ..clientName = clientName ?? this.clientName
      ..clientAddress = clientAddress ?? this.clientAddress
      ..fromCompanyName = fromCompanyName ?? this.fromCompanyName
      ..fromCompanyAddress = fromCompanyAddress ?? this.fromCompanyAddress
      ..termsConditions = termsConditions ?? this.termsConditions
      ..vatPercentage = vatPercentage ?? this.vatPercentage
      ..lineItems = lineItems ?? this.lineItems;
  }

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

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'],
      projectId: json['projectId'],
      number: json['number'],
      status: QuotationStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      clientName: json['clientName'],
      clientAddress: json['clientAddress'],
      fromCompanyName: json['fromCompanyName'],
      fromCompanyAddress: json['fromCompanyAddress'],
      termsConditions: json['termsConditions'],
      vatPercentage: double.tryParse(json['vatPercentage']) ?? 0,
      lineItems:
          (json['lineItems'] as List)
              .map((i) => QuotationLineItem.fromJson(i))
              .toList(),
    );
  }
}
