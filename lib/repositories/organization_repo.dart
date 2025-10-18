import 'dart:convert';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';

class OrganizationRepo {
  OrganizationRepo();

  /// Create a new organization
  Future<Map<String, dynamic>> createOrganization({
    required String name,
    String? description,
  }) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.createOrg,
      body: {'name': name, 'description': description},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data['organization'];
    } else {
      throw Exception(data['message'] ?? 'Failed to create organization');
    }
  }

  /// Join an existing organization (by id or name)
  Future<Map<String, dynamic>> joinOrganization({
    String? organizationId,
    String? organizationName,
  }) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.joinOrg,
      body: {
        if (organizationId != null) 'organizationId': organizationId,
        if (organizationName != null) 'organizationName': organizationName,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['organization'];
    } else {
      throw Exception(data['message'] ?? 'Failed to join organization');
    }
  }
}
