import 'dart:convert';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/quotation.dart';

class QuotationRepo {
  Future<List<Quotation>> getQuotations() async {
    final response = await ApiClient.http.get('/quotations');
    final List<dynamic> data = json.decode(response.body);

    return data.map((json) => Quotation.fromJson(json)).toList();
  }

  Future<Quotation> getQuotation(String id) async {
    final response = await ApiClient.http.get('/quotations/$id');

    return Quotation.fromJson(json.decode(response.body));
  }

  Future<Quotation> createQuotation(Map<String, dynamic> data) async {
    final response = await ApiClient.http.post('/quotations', body: data);

    if (response.statusCode != 201) {
      throw json.decode(response.body)['message'];
    }

    return Quotation.fromJson(json.decode(response.body));
  }

  Future<Quotation> updateQuotation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.http.put('/quotations/$id', body: data);

    if (response.statusCode != 200) {
      throw json.decode(response.body)['message'];
    }

    return Quotation.fromJson(json.decode(response.body));
  }

  Future<void> deleteQuotation(String id) async {
    await ApiClient.http.delete('/quotations/$id');
  }
}
