import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/invitation.dart';
import 'package:smooflow/repositories/invitation_repo.dart';

enum InvitationSendStatus {
  success,
  failed,
  // A request is already pending from this organization
  alreadyPending,
}

class InvitationNotifier extends StateNotifier<InvitationState> {
  final InvitationRepository _repository;

  InvitationNotifier(this._repository) : super(const InvitationState());

  bool _isInitialized = false;

  Future<List<Invitation>> fetchInvitations({bool forceReload = false}) async {
    // state = state.copyWith(isLoading: true);

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

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetSuccess() {
    state = state.copyWith(success: false);
  }
}

class InvitationState {
  final bool isLoading;
  final List<Invitation> invitations;
  final String? error;
  final bool success;

  const InvitationState({
    this.isLoading = false,
    this.invitations = const [],
    this.error,
    this.success = false,
  });

  InvitationState copyWith({
    bool? isLoading,
    List<Invitation>? invitations,
    // Adds (to state) if an invitation with this id doesn't exist in state, otherwise updates its existing state
    Invitation? invitation,
    String? error,
    bool? success,
  }) {
    final invs = invitations ?? this.invitations;

    if (invitation != null) {
      invs.removeWhere((inv) => inv.id == invitation.id);

      invs.add(invitation);
    }

    return InvitationState(
      isLoading: isLoading ?? this.isLoading,
      invitations: invs,
      error: error,
      success: success ?? this.success,
    );
  }
}
