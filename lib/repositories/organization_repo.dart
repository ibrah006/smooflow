import 'dart:convert';
import 'package:googleapis/admin/directory_v1.dart';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';
import 'package:smooflow/models/organization.dart';

class OrganizationRepo {
  OrganizationRepo();

  /// Create a new organization
  Future<Organization> createOrganization({
    required String name,
    String? description,
  }) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.createOrg,
      body: {'name': name, 'description': description},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Organization.fromJson(data['organization']);
    } else {
      throw Exception(data['message'] ?? 'Failed to create organization');
    }
  }

  /// Join an existing organization (by id or name)
  Future<Organization> joinOrganization({
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

  /// ✅ Fetch the current user's organization details
  Future<Organization> getCurrentOrganization() async {
    final response = await ApiClient.http.get(ApiEndpoints.getCurrentOrg);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Organization.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception(
        jsonDecode(response.body)['message'] ??
            'You are not part of any organization',
      );
    } else if (response.statusCode == 401) {
      throw Exception('Authentication required');
    } else {
      throw Exception(
        'Failed to fetch current organization: ${response.statusCode}',
      );
    }
  }

  /// ✅ Fetch all members of the current user's organization
  Future<List<Member>> getOrganizationMembers() async {
    final response = await ApiClient.http.get(
      ApiEndpoints.getCurrentOrgMembers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List members = data['members'];
      return members.map((m) => Member.fromJson(m)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Organization context required');
    } else {
      throw Exception(
        'Failed to fetch organization members: ${response.statusCode}',
      );
    }
  }

  Future<DateTime> get getProjectsLastAdded async {
    final response = await ApiClient.http.get(
      ApiEndpoints.getProjectsLastAdded,
    );

    if (response.statusCode != 200) {
      throw "Error getting Projects Last Added (datetime) for this organization";
    }

    return DateTime.parse(jsonDecode(response.body)["projectsLastAdded"]);
  }
}
