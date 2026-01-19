import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/invitation.dart';
import 'package:smooflow/enums/invitation_send_satus.dart';
import 'package:smooflow/core/repositories/invitation_repo.dart';
import 'package:smooflow/states/invitation.dart';

class InvitationNotifier extends StateNotifier<InvitationState> {
  final InvitationRepository _repository;

  InvitationNotifier(this._repository) : super(InvitationState());

  bool _isInitialized = false;

  Future<List<Invitation>> fetchInvitations({bool forceReload = false}) async {
    state = state.copyWith(isLoading: true);

    try {
      late final List<Invitation>? invitations;
      if ((state.invitations.isEmpty && !_isInitialized) || forceReload) {
        invitations = await _repository.getOrganizationInvitations();
        if (!_isInitialized) _isInitialized = true;
      } else {
        invitations = null;
      }

      state = state.copyWith(isLoading: false, invitations: invitations);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }

    return state.invitations;
  }

  Future<InvitationSendStatus> sendInvitation({
    required String email,
    String? role,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      final invitationResponse = await _repository.sendInvitation(
        email: email,
        role: role,
      );
      // Update local state
      state = state.copyWith(
        isLoading: false,
        success: true,
        invitation: invitationResponse.invitation,
      );

      return invitationResponse.invitationSendStatus;
    } catch (e) {
      print("error: $e");
      state = state.copyWith(isLoading: false, error: e.toString());

      return InvitationSendStatus.failed;
    }
  }

  Future<void> cancelInvitation(String invitationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.cancelInvitation(invitationId);

      // update local state

      final invitation = state.invitations.firstWhere(
        (inv) => inv.id == invitationId,
      );

      invitation.status = InvitationStatus.cancelled;

      state = state.copyWith(
        isLoading: false,
        success: true,
        invitation: invitation,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());

      rethrow;
    }
  }

  Future<void> fetchMyInvitations() async {
    // Can't try to load in invitations while already having an fetch invitations task
    if (state.isLoading) return;
    if (!state.canFetchCurrentUserInvitations) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final invitations = await _repository.getMyInvitations();
      state = state.copyWith(
        isLoading: false,
        invitations: invitations,
        lastGetUserInvitations: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetSuccess() {
    state = state.copyWith(success: false);
  }

  Future<void> acceptInvitation(Invitation invitation) async {
    while (state.isLoading) {
      print("waiting for another invitation task to finish");
      await Future.delayed(Duration(milliseconds: 1000));
    }
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.acceptInvitation(invitation.token);

      invitation.status = InvitationStatus.accepted;

      state = state.copyWith(
        isLoading: false,
        success: true,
        invitation: invitation,
      );
    } catch (e) {
      // Could be either expired or cancelled invitation
      invitation.status = InvitationStatus.cancelled;

      state = state.copyWith(
        isLoading: false,
        success: false,
        invitation: invitation,
        error: e.toString(),
      );
    }
  }
}
