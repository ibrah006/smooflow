import 'dart:convert';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/models/material.dart';
import 'package:smooflow/models/stock_transaction.dart';

class MaterialRepo {
  Future<List<MaterialModel>> getAllMaterials() async {
    final res = await ApiClient.http.get('/materials');
    if (res.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(res.body);
      return jsonData.map((e) => MaterialModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load materials: ${res.body}');
    }
  }

  Future<MaterialModel> createMaterial(Map<String, dynamic> data) async {
    final res = await ApiClient.http.post('/materials', body: data);
    if (res.statusCode == 201) {
      return MaterialModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to create material: ${res.body}');
    }
  }

  Future<MaterialModel> updateMaterial(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await ApiClient.http.put('/materials/$id', body: data);
    if (res.statusCode == 200) {
      return MaterialModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to update material: ${res.body}');
    }
  }

  Future<void> deleteMaterial(String id) async {
    final res = await ApiClient.http.delete('/materials/$id');
    if (res.statusCode != 204) {
      throw Exception('Failed to delete material: ${res.body}');
    }
  }

  Future<List<StockTransaction>> getMaterialTransactions(
    String materialId, {
    int limit = 50,
  }) async {
    final res = await ApiClient.http.get(
      '/materials/$materialId/transactions?limit=$limit',
    );
    if (res.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(res.body);
      return jsonData.map((e) => StockTransaction.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch transactions: ${res.body}');
    }
  }

  Future<StockTransaction> stockIn(
    String materialId,
    double quantity, {
    String? notes,
  }) async {
    final res = await ApiClient.http.post(
      '/materials/$materialId/stock-in',

      body: {'quantity': quantity, 'notes': notes},
    );
    if (res.statusCode == 201) {
      return StockTransaction.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Stock in failed: ${res.body}');
    }
  }

  Future<StockTransaction> stockOut(
    String materialId,
    double quantity, {
    String? notes,
    String? projectId,
  }) async {
    final res = await ApiClient.http.post(
      '/materials/$materialId/stock-out',
      body: {'quantity': quantity, 'notes': notes, 'projectId': projectId},
    );
    if (res.statusCode == 201) {
      return StockTransaction.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Stock out failed: ${res.body}');
    }
  }

  Future<List<MaterialModel>> getLowStockMaterials() async {
    final res = await ApiClient.http.get('/materials/alerts/low-stock');
    if (res.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(res.body);
      return jsonData.map((e) => MaterialModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch low stock materials: ${res.body}');
    }
  }

  Future<List<StockTransaction>> getProjectMaterialUsage(
    String projectId,
  ) async {
    final res = await ApiClient.http.get('/projects/$projectId/materials');
    if (res.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(res.body);
      return jsonData.map((e) => StockTransaction.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch project material usage: ${res.body}');
    }
  }

  Future<StockTransaction> getTransactionByBarcode(String barcode) async {
    final res = await ApiClient.http.get('/transactions/barcode/$barcode');
    if (res.statusCode == 200) {
      return StockTransaction.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Transaction not found: ${res.body}');
    }
  }
}
