import 'dart:convert';

import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/endpoints.dart';
import 'package:smooflow/core/models/invitation.dart';
import 'package:smooflow/notifiers/invitation_notifier.dart';

class InvitationResponse {
  InvitationResponse({
    required this.invitation,
    required this.invitationSendStatus,
  });

  Invitation invitation;
  InvitationSendStatus invitationSendStatus;
}

class InvitationRepository {
  InvitationRepository();

  Future<InvitationResponse> sendInvitation({
    required String email,
    String? role,
  }) async {
    final response = await ApiClient.http.post(
      ApiEndpoints.invitations,
      body: {'email': email, 'role': role},
    );

    // CODE 208 means invitation to that user, from this organization is already pending
    if (response.statusCode != 201 && response.statusCode != 208) {
      throw "Error sending Invitations";
    }

    print("response received: ${response.statusCode}");

    final data = jsonDecode(response.body)['data'];
    return InvitationResponse(
      invitation: Invitation.fromJson(data),
      invitationSendStatus:
          response.statusCode == 201
              ? InvitationSendStatus.success
              : response.statusCode == 208
              ? InvitationSendStatus.alreadyPending
              : InvitationSendStatus.failed,
    );
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

    print("cancel inv STATUS ${response.statusCode},\n${response.body}");

    if (response.statusCode != 200) {
      throw "Error Cancelling Invitation";
    }
  }

  Future<void> acceptInvitation(String token) async {
    print("accept-token: $token");
    final response = await ApiClient.http.post(
      '${ApiEndpoints.invitations}/accept/$token',
      body: {"placeholder": null},
    );

    if (response.statusCode != 200) {
      throw jsonDecode(response.body)["message"];
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

  Future<List<Invitation>> getMyInvitations() async {
    final response = await ApiClient.http.get('${ApiEndpoints.invitations}/me');

    final body = jsonDecode(response.body) as Map;

    print("get my invitations response body: $body");

    if (response.statusCode != 200) {
      throw body["message"];
    }

    final List list = body['data'];
    return list.map((e) => Invitation.fromJson(e)).toList();
  }
}
