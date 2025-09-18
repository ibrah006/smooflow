import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';
import 'package:smooflow/models/company.dart';

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
