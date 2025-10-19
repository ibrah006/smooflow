import 'dart:convert';

import 'package:smooflow/api/api_client.dart';
import 'package:smooflow/api/endpoints.dart';
import 'package:smooflow/models/invitation.dart';

class InvitationRepository {
  InvitationRepository();

  Future<Invitation> sendInvitation({
    required String email,
    String? role,
  }) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.invitations,
      body: {'email': email, 'role': role},
    );

    if (response.statusCode != 201) {
      throw "Error sending Invitations";
    }

    final data = jsonDecode(response.body)['data'];
    return Invitation.fromJson(data);
  }

  Future<List<Invitation>> getOrganizationInvitations({String? status}) async {
    final response = await ApiClient.http.get(
      '${ApiEndpoints.invitations}/organization',
      queries: status != null ? '?status=$status' : '',
    );

    if (response.statusCode != 200) {
      throw "Error getting invitations for organization";
    }

    final List list = jsonDecode(response.body)['data'];
    return list.map((e) => Invitation.fromJson(e)).toList();
  }

  Future<void> cancelInvitation(String invitationId) async {
    final response = await ApiClient.http.delete(
      '${ApiEndpoints.invitations}/$invitationId',
    );

    if (response.statusCode != 200) {
      throw "Error Cancelling Invitation";
    }
  }

  Future<void> acceptInvitation(String token) async {
    final response = await ApiClient.http.post(
      '${ApiEndpoints.invitations}/accept/$token',
    );

    if (response.statusCode != 200) {
      throw "Error Accepting Invitation";
    }
  }

  Future<Map<String, dynamic>> verifyInvitation(String token) async {
    final response = await ApiClient.http.get(
      '${ApiEndpoints.invitations}/verify/$token',
    );

    if (response.statusCode != 200) {
      throw "Error Verifying Invitation";
    }

    return jsonDecode(response.body)['data'];
  }
}
