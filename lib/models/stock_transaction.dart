import 'package:smooflow/models/material.dart';

/// Enum for transaction type — matches backend
enum TransactionType { stockIn, stockOut, adjustment }

TransactionType transactionTypeFromString(String type) {
  switch (type) {
    case 'stock_in':
      return TransactionType.stockIn;
    case 'stock_out':
      return TransactionType.stockOut;
    case 'adjustment':
      return TransactionType.adjustment;
    default:
      throw Exception('Unknown transaction type: $type');
  }
}

String transactionTypeToString(TransactionType type) {
  switch (type) {
    case TransactionType.stockIn:
      return 'stock_in';
    case TransactionType.stockOut:
      return 'stock_out';
    case TransactionType.adjustment:
      return 'adjustment';
  }
}

/// Represents a stock transaction in the system.
class StockTransaction {
  final String id;
  final String materialId;
  final TransactionType type;
  final double quantity;
  final double balanceAfter;
  final String? barcode;
  final String? notes;
  final String? projectId;
  final String createdById;
  final DateTime createdAt;
  final String? taskId;
  final bool committed;

  const StockTransaction({
    required this.id,
    required this.materialId,
    required this.type,
    required this.quantity,
    required this.balanceAfter,
    required this.createdById,
    required this.createdAt,
    this.barcode,
    this.notes,
    this.projectId,
    this.taskId,
    required this.committed
  });

  // To ensure toSet gives no duplicates
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;
  @override
  int get hashCode => id.hashCode;

  /// Factory constructor to parse from backend JSON
  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id'],
      materialId: json['materialId'],
      type: transactionTypeFromString(json['type']),
      quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
      balanceAfter: double.tryParse(json['balanceAfter'].toString()) ?? 0.0,
      barcode: json['barcode'],
      notes: json['notes'],
      projectId: json['projectId'],
      createdById: json['createdById'],
      createdAt: DateTime.parse(json['createdAt']),
      taskId: json['taskId'],
      committed: json['committed']
    );
  }

  /// Convert object to JSON for sending to backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materialId': materialId,
      'type': transactionTypeToString(type),
      'quantity': quantity,
      'balanceAfter': balanceAfter,
      'barcode': barcode,
      'notes': notes,
      'projectId': projectId,
      'createdById': createdById,
      'createdAt': createdAt.toIso8601String(),
      'taskId': taskId
    };
  }

  /// Creates a copy with updated fields
  StockTransaction copyWith({
    String? id,
    String? materialId,
    TransactionType? type,
    double? quantity,
    double? balanceAfter,
    String? barcode,
    String? notes,
    String? projectId,
    String? createdById,
    DateTime? createdAt,
    MaterialModel? material,
    String? taskId
  }) {
    return StockTransaction(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      barcode: barcode ?? this.barcode,
      notes: notes ?? this.notes,
      projectId: projectId ?? this.projectId,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      taskId: taskId,
      committed: committed,
    );
  }
}
