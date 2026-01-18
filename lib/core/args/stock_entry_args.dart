import 'package:flutter/cupertino.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/stock_transaction.dart';

class StockEntryArgs {
  late final bool isStockIn;

  StockEntryArgs.stockIn({Key? key, MaterialModel? material})
    : projectId = null {
      if (material != null) {
        this.material = material;
      }
    }

  late final MaterialModel material;
  late final StockTransaction transaction;
  final String? projectId;

  StockEntryArgs.stockOut({
    Key? key,
    required this.material,
    required this.transaction,
    required this.projectId,
  });
}
