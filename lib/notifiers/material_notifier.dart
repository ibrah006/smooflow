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

  // Create new material
  Future<void> createMaterial(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      final newMaterial = await _repo.createMaterial(data);
      final updatedList = [...state.materials, newMaterial];
      state = state.copyWith(materials: updatedList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
  Future<void> stockIn(
    String materialId,
    double quantity, {
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.stockIn(materialId, quantity, notes: notes);
      await fetchMaterials();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Stock Out
  Future<void> stockOut(
    String materialId,
    double quantity, {
    String? notes,
    String? projectId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.stockOut(
        materialId,
        quantity,
        notes: notes,
        projectId: projectId,
      );
      await fetchMaterials();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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

  // Get transaction by barcode
  Future<void> fetchTransactionByBarcode(String barcode) async {
    state = state.copyWith(isLoading: true);
    try {
      final transaction = await _repo.getTransactionByBarcode(barcode);
      state = state.copyWith(transactions: [transaction], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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
    bool? isLoading,
    String? errorMessage,
  }) {
    return MaterialState(
      materials: materials ?? this.materials,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
