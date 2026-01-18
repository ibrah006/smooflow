import 'package:flutter/widgets.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/stock_transaction.dart';

class StockDetailsArgs {
  final StockTransaction transaction;
  final String materialType;
  final MeasureType measureType;

  @Deprecated("for stock out, temporary")
  /// only for stock out
  final String? barcode;

  const StockDetailsArgs(
    this.transaction, {
    Key? key,
    required this.materialType,
    required this.measureType,
    required this.barcode,
  });
}
