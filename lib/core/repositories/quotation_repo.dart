import 'dart:convert';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/quotation.dart';

class QuotationRepo {
  Future<List<Quotation>> getQuotations() async {
    final response = await ApiClient.http.get('/quotation');
    final List<dynamic> data = json.decode(response.body);

    return data.map((json) => Quotation.fromJson(json)).toList();
  }

  Future<Quotation> getQuotation(String id) async {
    final response = await ApiClient.http.get('/quotation/$id');

    return Quotation.fromJson(json.decode(response.body));
  }

  Future<Quotation> createQuotation(Map<String, dynamic> data) async {
    final response = await ApiClient.http.post('/quotation', body: data);

    if (response.statusCode != 201) {
      throw json.decode(response.body)['message'];
    }

    return Quotation.fromJson(json.decode(response.body));
  }

  Future<Quotation> updateQuotation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.http.put('/quotation/$id', body: data);

    if (response.statusCode != 200) {
      throw json.decode(response.body)['message'];
    }

    return Quotation.fromJson(json.decode(response.body));
  }

  Future<void> deleteQuotation(String id) async {
    await ApiClient.http.delete('/quotation/$id');
  }

  Future<Quotation> updateQuotationLineItem(
    String lineItemId,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.http.put(
      '/quotation/lineItems/$lineItemId',
      body: data,
    );

    if (response.statusCode != 200) {
      throw json.decode(response.body)['message'];
    }

    return Quotation.fromJson(json.decode(response.body));
  }
}
