import 'dart:convert';
import 'package:http/http.dart' as http;

class OrganizationRepo {
  final String baseUrl;
  final String token;

  OrganizationRepo({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Create a new organization
  Future<Map<String, dynamic>> createOrganization({
    required String name,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/organizations'),
      headers: _headers,
      body: jsonEncode({'name': name, 'description': description}),
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
    final response = await http.post(
      Uri.parse('$baseUrl/organizations/join'),
      headers: _headers,
      body: jsonEncode({
        if (organizationId != null) 'organizationId': organizationId,
        if (organizationName != null) 'organizationName': organizationName,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['organization'];
    } else {
      throw Exception(data['message'] ?? 'Failed to join organization');
    }
  }
}
