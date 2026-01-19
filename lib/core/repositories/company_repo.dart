import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/endpoints.dart';
import 'package:smooflow/core/models/company.dart';

class CompanyRepo {
  @deprecated
  static List<Company> companies = [];

  static Future<void> fetchCompanies() async {
    try {
      final response = await ApiClient.http.get(ApiEndpoints.companies);
      final body = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw "Failed to fetch companies: ${response.body}";
      }

      companies = (body as List).map((e) => Company.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Server Error getting companies");
    }
  }

  /// returns error message, if any
  static Future<String?> createCompany(Company company) async {
    try {
      final response = await ApiClient.http.post(
        ApiEndpoints.companies,
        body: company.toJson(),
      );

      final body = jsonDecode(response.body) as Map;

      if (response.statusCode != 201 && response.statusCode != 209) {
        return body["error"];
      }

      final createdAt = DateTime.parse(body["company"]["createdAt"]);

      company.createdAt = createdAt;

      companies.add(company);

      // Client company already exists in this organization
      if (response.statusCode == 209) {
        companies.add(body["company"]);
      }
    } catch (e) {
      debugPrint("Error creating company profile,\nerror: $e");
    }
    return null;
  }

  // static Future<void> createCompany(Company project) async {
  //   final response = await ApiClient.http.post(
  //     ApiEndpoints.projects,
  //     body: project.toJson(),
  //   );
  //   final body = jsonDecode(response.body);

  //   if (response.statusCode != 201) {
  //     throw "Failed to create company: ${response.body}\nbody: $body";
  //   }
  // }
}
