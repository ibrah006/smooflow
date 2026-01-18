import 'dart:convert';
import 'package:googleapis/admin/directory_v1.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/endpoints.dart';
import 'package:smooflow/core/models/organization.dart';

class OrganizationRepo {
  OrganizationRepo();

  /// Create a new organization
  Future<CreateOrganizationResponse> createOrganization({
    required String name,
    String? description,
  }) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.createOrg,
      body: {'name': name, 'description': description},
    );

    final data = jsonDecode(response.body);

    print("create organization: $data");

    if (response.statusCode == 201) {
      return CreateOrganizationResponse(
        organization: Organization.fromJson(data['organization']),
        privateDomainAvailable: data['privateDomainAvailable'],
        privateDomain: data['privateDomain'],
      );
    } else {
      throw Exception(data['message'] ?? 'Failed to create organization');
    }
  }

  /// Join an existing organization (by id or name)
  Future<Organization> joinOrganization({
    required String organizationId,
    required String role,
  }) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.joinOrg,
      body: {'organizationId': organizationId, 'role': role},
    );

    final data = jsonDecode(response.body) as Map;

    if (response.statusCode == 200) {
      return Organization.fromJson(data['organization']);
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

  Future<DateTime?> get getProjectsLastAdded async {
    final response = await ApiClient.http.get(
      ApiEndpoints.getProjectsLastAdded,
    );

    if (response.statusCode != 200) {
      throw "Error getting Projects Last Added (datetime) for this organization";
    }

    final projectsLastAddedRaw = jsonDecode(response.body)["projectsLastAdded"];

    return projectsLastAddedRaw == null
        ? null
        : DateTime.parse(projectsLastAddedRaw);
  }

  // true: success
  Future<bool> claimDomainOwnership() async {
    final response = await ApiClient.http.put(
      ApiEndpoints.claimOrganizationDomainOwnership,
      body: {"placeholder": null},
    );

    return response.statusCode == 200;
  }
}

class CreateOrganizationResponse {
  final Organization organization;
  final bool privateDomainAvailable;
  final String? privateDomain;

  CreateOrganizationResponse({
    required this.organization,
    required this.privateDomainAvailable,
    required this.privateDomain,
  }) {
    if (privateDomainAvailable && privateDomain == null) {
      // If this error is ever thrown then it's probably in the frontend and just th developer's fault in modifying the create organization repo function
      throw "ERROR: Private domain can't be available on a null private domain";
    }
  }
}
