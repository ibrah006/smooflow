// services/api/pricing_api.dart
import 'dart:convert';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/models/pricing.dart';

class PricingRepo {
  Future<List<Pricing>> getPricing() async {
    final response = await ApiClient.http.get('/pricing');
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Pricing.fromJson(json)).toList();
  }

  Future<Pricing> getPricingById(String id) async {
    final response = await ApiClient.http.get('/pricing/$id');
    return Pricing.fromJson(json.decode(response.body));
  }

  Future<PricingCosts> getClientPricing(
    String pricingId,
    String clientId,
  ) async {
    final response = await ApiClient.http.get(
      '/pricing/$pricingId/client/$clientId',
    );
    return PricingCosts.fromJson(json.decode(response.body));
  }

  Future<Pricing> createPricing(Pricing pricing) async {
    final response = await ApiClient.http.post(
      '/pricing',
      body: json.encode({
        "description": pricing.description,
        "clientPrices": pricing.clientPrices,
      }),
    );

    if (response.statusCode != 200) {
      throw json.decode(response.body)['message'];
    }

    print("create pricing response body: ${response.body}");
    return Pricing.fromJson(json.decode(response.body));
  }

  Future<Pricing> updatePricing(Pricing pricing) async {
    final response = await ApiClient.http.put(
      '/pricing/${pricing.id}',
      body: pricing.toJson(),
    );
    return Pricing.fromJson(json.decode(response.body));
  }

  Future<void> deletePricing(String id) async {
    await ApiClient.http.delete('/pricing/$id');
  }

  Future<Pricing> setClientPricing(
    String pricingId,
    String clientId,
    PricingCosts costs,
  ) async {
    final response = await ApiClient.http.put(
      '/pricing/$pricingId/client',
      body: {'clientId': clientId, 'costs': costs.toJson()},
    );
    return Pricing.fromJson(json.decode(response.body));
  }

  Future<Pricing> removeClientPricing(String pricingId, String clientId) async {
    final response = await ApiClient.http.delete(
      '/pricing/$pricingId/client/$clientId',
    );
    return Pricing.fromJson(json.decode(response.body));
  }

  Future<Pricing> bulkSetClientPricing(
    String pricingId,
    Map<String, PricingCosts> clientPricingMap,
  ) async {
    final response = await ApiClient.http.put(
      '/pricing/$pricingId/client/bulk',
      body: clientPricingMap.map((key, value) => MapEntry(key, value.toJson())),
    );
    return Pricing.fromJson(json.decode(response.body));
  }
}
