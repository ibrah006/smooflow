import 'package:smooflow/core/models/stock_transaction.dart';

extension StockTransactionListExtension on List<StockTransaction> {
  double get totalQuantity {
    return fold(0.0, (sum, item) => sum + item.quantity);
  }
}