import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/data/material_stats.dart';

class MaterialState {
  final List<MaterialModel> materials;
  final bool isLoading;
  final String? errorMessage;
  List<StockTransaction> transactions;
  final StockPercentageResult? stockStats;

  MaterialState({
    this.materials = const [],
    this.transactions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.stockStats,
  });

  MaterialState copyWith({
    List<MaterialModel>? materials,
    List<StockTransaction>? transactions,
    MaterialModel? material,
    bool? isLoading,
    String? errorMessage,
    StockTransaction? transaction,
    StockPercentageResult? stockStats,
  }) {
    final temp = List<StockTransaction>.from(this.transactions);

    temp.addAll(transactions ?? []);

    // toSet will ensure there are no duplicates (by ID comparison)
    transactions = temp.toSet().toList();

    if (transaction != null) {
      transactions.removeWhere((transac) => transac.id == transaction.id);
      transactions.add(transaction);
    }

    materials = List.from(materials ?? this.materials);
    if (material != null) {
      materials.removeWhere((mat) => mat.id == material.id);
      materials.add(material);
    }

    return MaterialState(
      materials: materials,
      transactions: transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      stockStats: stockStats ?? this.stockStats,
    );
  }

  List<MaterialModel> byStatus({bool isLow = false, bool isCritical = false}) {
    return !isLow && !isCritical?
      materials
      : materials.where((material)=> (isLow && material.isLowStock) || (isCritical && material.isCriticalStock)).toList();
  }

  int countByStatus({bool isLow = false, bool isCritical = false}) {
    return byStatus(isLow: isLow, isCritical: isCritical).length;
  }

  List<StockTransaction> byMaterial(String materialId) {
    return transactions.where((transaction) {
      return transaction.materialId == materialId;
    }).toList();
  }
}