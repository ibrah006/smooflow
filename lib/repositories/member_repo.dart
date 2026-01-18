// minimal version of user

import 'dart:convert';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/endpoints.dart';
import '../core/models/member.dart';

class MemberRepo {
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

  // Fetch organization member by ID
  Future<Member> getMemberById(String memberId) async {
    final response = await ApiClient.http.get(
      ApiEndpoints.getCurrentOrgMember(memberId),
    );

    if (response.statusCode == 200) {
      final memberRaw = (jsonDecode(response.body) as Map)["member"];
      return Member.fromJson(memberRaw);
    } else if (response.statusCode == 401) {
      throw Exception('Organization context required');
    } else {
      throw Exception(
        'Failed to fetch organization members: ${response.statusCode}',
      );
    }
  }
}
