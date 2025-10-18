// minimal version of user

import 'dart:convert';
import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';
import '../models/member.dart';

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
}
