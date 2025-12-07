import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:smooflow/api/api_client.dart';
import '../models/printer.dart';

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
}
