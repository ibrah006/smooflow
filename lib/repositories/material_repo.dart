import 'dart:convert';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/stock_transaction.dart';
import 'package:smooflow/notifiers/material_notifier.dart';
import 'package:smooflow/data/material_stats.dart';

class MaterialRepo {
  Future<List<MaterialModel>> getAllMaterials() async {
    final res = await ApiClient.http.get('/material/materials');
    if (res.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(res.body);
      return jsonData.map((e) => MaterialModel.fromJson(e)).toList();
    } else {
      print(
        "ERROR fetching materials STATUS ${res.statusCode}, body: ${res.body}",
      );
      throw Exception('Failed to load materials: ${res.body}');
    }
  }

  Future<MaterialModel> createMaterial(MaterialModel material) async {
    final res = await ApiClient.http.post(
      '/material/materials',
      body: material.toCreateJson(),
    );
    if (res.statusCode == 201) {
      return MaterialModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to create material: ${res.body}');
    }
  }

  Future<List<MaterialModel>> createMaterials(
    List<MaterialModel> materials,
  ) async {
    final res = await ApiClient.http.post<List>(
      '/material/materials',
      body: (materials.map((m) => m.toCreateJson())).toList(),
    );
    if (res.statusCode == 201) {
      return (jsonDecode(res.body) as List).map((materialRaw) {
        return MaterialModel.fromJson(materialRaw as Map<String, dynamic>);
      }).toList();
    } else {
      throw Exception('Failed to create materials: ${res.body}');
    }
  }

  Future<MaterialModel> updateMaterial(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await ApiClient.http.put('/material/materials/$id', body: data);
    if (res.statusCode == 200) {
      return MaterialModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to update material: ${res.body}');
    }
  }

  Future<void> deleteMaterial(String id) async {
    final res = await ApiClient.http.delete('/material/materials/$id');
    if (res.statusCode != 204) {
      throw Exception('Failed to delete material: ${res.body}');
    }
  }

  Future<List<StockTransaction>> getMaterialTransactions(
    String materialId, {
    int limit = 50,
    TransactionType? type
  }) async {
    final res = await ApiClient.http.get(
      '/material/materials/$materialId/transactions?limit=$limit${type!=null? '&type=${transactionTypeToString(type)}' : ''}',
    );
    if (res.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(res.body);
      return jsonData.map((e) => StockTransaction.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch transactions: ${res.body}');
    }
  }

  Future<List<StockTransaction>> getTransactions({int limit = 50}) async {
    final res = await ApiClient.http.get('/material/transactions');
    if (res.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(res.body);
      return jsonData.map((e) => StockTransaction.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch transactions: ${res.body}');
    }
  }

  Future<MaterialModel> getMaterialById(String materialId) async {
    final res = await ApiClient.http.get('/material/materials/$materialId');

    if (res.statusCode == 200) {
      return MaterialModel.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Material not found: ${res.body}');
    }
  }

  Future<StockTransaction> stockIn(
    String materialId,
    double quantity, {
    String? notes,
  }) async {
    final res = await ApiClient.http.post(
      '/material/materials/$materialId/stock-in',

      body: {'quantity': quantity, 'notes': notes},
    );
    if (res.statusCode == 201) {
      return StockTransaction.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Stock in failed: ${res.body}');
    }
  }

  Future<StockTransaction> stockOut(
    String barcode,
    double quantity, {
    String? notes,
    String? projectId,
  }) async {
    final res = await ApiClient.http.post(
      '/material/materials/$barcode/stock-out',
      body: {'quantity': quantity, 'notes': notes, 'projectId': projectId},
    );
    if (res.statusCode == 201) {
      return StockTransaction.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Stock out failed: ${res.body}');
    }
  }

  Future<List<MaterialModel>> getLowStockMaterials() async {
    final res = await ApiClient.http.get(
      '/material/materials/alerts/low-stock',
    );
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

  // TODO: Going to need Stock transaction and the material associated with it returned from this function
  Future<MaterialResponse> getTransactionByBarcode(String barcode) async {
    final res = await ApiClient.http.get(
      '/material/transactions/barcode/$barcode',
    );
    if (res.statusCode == 200) {
      // return MaterialResponse
      final body = jsonDecode(res.body);
      return MaterialResponse(
        material: MaterialModel.fromJson(body["material"]),
        stockTransaction: StockTransaction.fromJson(body),
      );
    } else {
      throw Exception('Transaction not found: ${res.body}');
    }
  }

  Future<MaterialModel> getMaterialByMaterialBarcode(String barcode) async {
    final res = await ApiClient.http.get(
      '/material/materials/barcode/$barcode',
    );
    if (res.statusCode == 200) {
      // return MaterialResponse
      final body = jsonDecode(res.body);
      return MaterialModel.fromJson(body["material"]);
    } else {
      throw Exception('Material not found: ${res.body}');
    }
  }

  Future<StockPercentageResult> getStockPercentage() async {
    final res = await ApiClient.http.get('/material/stock-percentage');
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return StockPercentageResult.fromJson(body);
    } else {
      throw Exception('Failed to fetch stock percentage: ${res.body}');
    }
  }
}
