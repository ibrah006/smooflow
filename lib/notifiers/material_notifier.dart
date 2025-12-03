import 'package:smooflow/models/material.dart';
import 'package:smooflow/models/stock_transaction.dart';
import '../repositories/material_repo.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaterialNotifier extends StateNotifier<MaterialState> {
  final MaterialRepo _repo;

  MaterialNotifier(this._repo) : super(const MaterialState());

  // Fetch all materials
  Future<void> fetchMaterials() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final materials = await _repo.getAllMaterials();
      state = state.copyWith(materials: materials, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Creates new material if it doesn't already exist
  // NOT material item name are not case-sensitive within organization
  Future<MaterialModel> createMaterial(MaterialModel material) async {
    state = state.copyWith(isLoading: true);
    // Check to see if it already exists
    try {
      final existingMaterial = state.materials.firstWhere(
        (m) => m.name.toLowerCase() == material.name.toLowerCase(),
      );
      // Material already exists - creation aborted
      return existingMaterial;
    } catch (e) {
      // Material doesn't exist in memory
      // Can still call the create material endpoint because it will only be created if it doesn't exist already
      try {
        final newMaterial = await _repo.createMaterial(material);
        final updatedList = [...state.materials, newMaterial];
        state = state.copyWith(materials: updatedList, isLoading: false);

        return newMaterial;
      } catch (e) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
        rethrow;
      }
    }
  }

  Future<List<MaterialModel>> createMaterials(
    List<MaterialModel> materials,
  ) async {
    state = state.copyWith(isLoading: true);
    // TODO: Do this in the backend
    // Check to see if it already exists
    try {
      // Material already exists - removed from create materials list
    } catch (e) {
      // Material doesn't exist in memory
      // Can still call the create material endpoint because it will only be created if it doesn't exist already
    }

    try {
      final newMaterials = await _repo.createMaterials(materials);
      // Converting from set, because set will ensure there are no duplicates
      final updatedList = {...state.materials, ...newMaterials}.toList();
      // Assuming db does not return duplicates
      state = state.copyWith(materials: updatedList, isLoading: false);

      return updatedList;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // Update material
  Future<void> updateMaterial(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedMaterial = await _repo.updateMaterial(id, data);
      final updatedList =
          state.materials.map((m) => m.id == id ? updatedMaterial : m).toList();
      state = state.copyWith(materials: updatedList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Delete material
  Future<void> deleteMaterial(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.deleteMaterial(id);
      final updatedList = state.materials.where((m) => m.id != id).toList();
      state = state.copyWith(materials: updatedList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Fetch low stock materials
  Future<void> fetchLowStockMaterials() async {
    state = state.copyWith(isLoading: true);
    try {
      final materials = await _repo.getLowStockMaterials();
      state = state.copyWith(materials: materials, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Stock In
  Future<StockTransaction> stockIn(
    String materialId,
    double quantity, {
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);
    // try {
    final transaction = await _repo.stockIn(materialId, quantity, notes: notes);
    state = state.copyWith(isLoading: false, transaction: transaction);

    try {
      state
          .materials
          .firstWhere((material) => material.id == materialId)
          .currentStock += quantity;
    } catch (e) {
      // The corresponding material doesn't exist in memory
    }

    return transaction;
    // } catch (e) {
    //   state = state.copyWith(isLoading: false, errorMessage: e.toString());
    //   rethrow;
    // }
  }

  // Stock Out
  Future<StockTransaction> stockOut(
    String barcode,
    double quantity, {
    String? notes,
    String? projectId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final transaction = await _repo.stockOut(
        barcode,
        quantity,
        notes: notes,
        projectId: projectId,
      );
      state = state.copyWith(isLoading: false, transaction: transaction);

      try {
        state
            .materials
            .firstWhere((material) => material.id == transaction.materialId)
            .currentStock -= quantity;
      } catch (e) {
        // The corresponding material doesn't exist in memory
      }

      return transaction;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<MaterialModel> getMaterialById(
    String materialId, {
    String? onErrorMessage,
  }) async {
    try {
      // check local memory
      return state.materials.firstWhere(
        (material) => material.id == materialId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: true);
      try {
        final material = await _repo.getMaterialById(materialId);

        state = state.copyWith(isLoading: false, material: material);
        return material;
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: onErrorMessage ?? e.toString(),
        );
        rethrow;
      }
    }
  }

  // Fetch material transaction history
  Future<void> fetchMaterialTransactions(
    String materialId, {
    int limit = 50,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final transactions = await _repo.getMaterialTransactions(
        materialId,
        limit: limit,
      );
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Fetch all transactions for current organization
  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true);
    try {
      final transactions = await _repo.getTransactions();

      print("transactions: $transactions");

      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<MaterialModel> fetchMaterialByMaterialBarcode(
    String materialBarcode,
  ) async {
    try {
      return state.materials.firstWhere((m) => m.barcode == materialBarcode);
    } catch (e) {
      // Not found in memory
      state = state.copyWith(isLoading: true);

      try {
        final material = await _repo.getMaterialByMaterialBarcode(
          materialBarcode,
        );
        state = state.copyWith(material: material, isLoading: false);

        return material;
      } catch (e) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
        rethrow;
      }
    }
  }

  // Get transaction by barcode
  Future<MaterialResponse> fetchMaterialResponseByBarcode(
    String barcode,
  ) async {
    try {
      final transactionInMemory = state.transactions.firstWhere(
        (transaction) => transaction.barcode == barcode,
      );

      // Make sure the corresponding Material exists in memory as well
      MaterialModel material = await getMaterialById(
        transactionInMemory.materialId,
        onErrorMessage:
            "Failed to get Material info for the Stock Transaction. Please Retry",
      );
      // try {
      //   state.materials.firstWhere(
      //     (material) => material.id == transactionInMemory.materialId,
      //   );
      // } catch (e) {
      //   // Material doesn't exist in memory
      //   try {
      //     material = await getMaterialById(
      //       transactionInMemory.materialId,
      //       onErrorMessage:
      //           "Failed to get Material info for the Stock Transaction. Please Retry",
      //     );

      //     // Update memory about this material
      //     // state = state.copyWith(isLoading: false, material: material);
      //   } catch (e) {
      //     // Was able to get transaction but not able to get material, retrying should fix
      //     // state = state.copyWith(
      //     //   isLoading: false,
      //     //   errorMessage:
      //     //       "Failed to get Material info for the Stock Transaction. Please Retry",
      //     // );
      //     rethrow;
      //   }
      // }

      return MaterialResponse(
        material: material,
        stockTransaction: transactionInMemory,
      );
    } catch (e) {
      // Not found in memory
    }
    // Proceed to find that in database
    state = state.copyWith(isLoading: true);
    // try {
    final materialResponse = await _repo.getTransactionByBarcode(barcode);
    state = state.copyWith(
      transaction: materialResponse.stockTransaction,
      material: materialResponse.material,
      isLoading: false,
    );

    return materialResponse;
    // } catch (e) {
    //   state = state.copyWith(isLoading: false, errorMessage: e.toString());

    //   rethrow;
    // }
  }
}

class MaterialState {
  final List<MaterialModel> materials;
  final bool isLoading;
  final String? errorMessage;
  final List<StockTransaction> transactions;

  const MaterialState({
    this.materials = const [],
    this.transactions = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  MaterialState copyWith({
    List<MaterialModel>? materials,
    List<StockTransaction>? transactions,
    MaterialModel? material,
    bool? isLoading,
    String? errorMessage,
    StockTransaction? transaction,
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
    );
  }

  List<StockTransaction> byMaterial(String materialId) {
    return transactions.where((transaction) {
      return transaction.materialId == materialId;
    }).toList();
  }
}

class MaterialResponse {
  final MaterialModel material;
  final StockTransaction stockTransaction;
  // For a specific project
  MaterialResponse({required this.material, required this.stockTransaction});
}
