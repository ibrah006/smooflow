import 'dart:convert';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/data/production_report_details.dart';
import '../models/printer.dart';

import 'package:http/http.dart' as http;

class PrinterRepo {
  PrinterRepo();

  // --------------------------------------------------
  // GET /printers
  // --------------------------------------------------
  Future<List<Printer>> getPrinters() async {
    final res = await ApiClient.http.get('/printers');

    print("fetch printers response body: ${res.statusCode}");

    return (jsonDecode(res.body) as List).map((e) => Printer.fromJson(e)).toList();
  }

  // --------------------------------------------------
  // GET /printers/:id
  // --------------------------------------------------
  Future<Printer> getPrinter(String id) async {
    final res = await ApiClient.http.get('/printers/$id');
    return Printer.fromJson(res.body as Map<String, dynamic>);
  }

  // --------------------------------------------------
  // POST /printers
  // --------------------------------------------------
  Future<Printer> createPrinter({
    required String name,
    String? nickname,
    String? location,
    double? maxWidth,
    double? printSpeed,
  }) async {
    final res = await ApiClient.http.post(
      '/printers',
      body: {
        'name': name,
        'nickname': nickname,
        'location': location,
        'maxWidth': maxWidth,
        'printSpeed': printSpeed,
      },
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create printer');
    }

    return Printer.fromJson(res.body as Map<String, dynamic>);
  }

  // --------------------------------------------------
  // PATCH /printers/:id
  // Any fields can be updated
  // --------------------------------------------------
  Future<Printer> updatePrinter(
    String id, {
    String? name,
    String? nickname,
    String? location,
    PrinterStatus? status,
    double? maxWidth,
    double? printSpeed,
  }) async {
    final Map<String, dynamic> data = {
      if (name != null) 'name': name,
      if (nickname != null) 'nickname': nickname,
      if (location != null) 'location': location,
      if (status != null) 'status': status.name,
      if (maxWidth != null) 'maxWidth': maxWidth,
      if (printSpeed != null) 'printSpeed': printSpeed,
    };

    final res = await ApiClient.http.put('/printers/$id', body: data);

    return Printer.fromJson(res.body as Map<String, dynamic>);
  }

  // --------------------------------------------------
  // DELETE /printers/:id
  // --------------------------------------------------
  Future<void> deletePrinter(String id) async {
    await ApiClient.http.delete('/printers/$id');
  }

  // --------------------------------------------------
  // GET /printers/active
  // --------------------------------------------------
  /// map content: activePrinters List<Printer>, totalPrintersCount int
  Future<Map<String, dynamic>> getActivePrinters() async {
    final res = await ApiClient.http.get('/printers/active');

    if (res.statusCode == 200) {
      return {
        "activePrinters": (jsonDecode(res.body)['activePrinters'] as List)
            .map((e) => Printer.fromJson(e))
            .toList(),
        "totalPrintersCount": (jsonDecode(res.body)['totalPrintersCount'] as num).toInt(),
      };
    }

    throw Exception('Failed to fetch active printers: ${res.body}');
  }
  
  Future<ProductionReportResponse> getProductionReport(ReportPeriod period) async {
    try {

      final response = await ApiClient.http.get("/reports/production?for=${period.name}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return ProductionReportResponse.fromJson(jsonData);
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw ProductionReportException(
          message: errorData['message'] ?? 'Bad request',
          statusCode: 400,
        );
      } else if (response.statusCode == 401) {
        throw ProductionReportException(
          message: 'Unauthorized. Please login again.',
          statusCode: 401,
        );
      } else if (response.statusCode == 500) {
        throw ProductionReportException(
          message: 'Server error. Please try again later.',
          statusCode: 500,
        );
      } else {
        throw ProductionReportException(
          message: 'Unexpected error occurred',
          statusCode: response.statusCode,
        );
      }
    } on http.Client catch (e) {
      throw ProductionReportException(
        message: 'Network error: $e',
        statusCode: 0,
      );
    } catch (e) {
      if (e is ProductionReportException) rethrow;
      throw ProductionReportException(
        message: 'Failed to fetch production report: $e',
        statusCode: 0,
      );
    }
  }
}

class ProductionReportException implements Exception {
  final String message;
  final int statusCode;

  ProductionReportException({
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => 'ProductionReportException: $message (Status: $statusCode)';
}