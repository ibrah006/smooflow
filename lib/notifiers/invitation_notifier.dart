import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/invitation.dart';
import 'package:smooflow/repositories/invitation_repo.dart';

class InvitationNotifier extends StateNotifier<InvitationState> {
  final InvitationRepository _repository;

  InvitationNotifier(this._repository) : super(const InvitationState());

  bool _isInitialized = false;

  Future<List<Invitation>> fetchInvitations({bool forceReload = false}) async {
    state = state.copyWith(isLoading: true);

    try {
      late final List<Invitation>? invitations;
      if ((state.invitations.isEmpty && !_isInitialized) || forceReload) {
        invitations = await _repository.getOrganizationInvitations();
        _isInitialized = true;
      } else {
        invitations = null;
      }

      state = state.copyWith(isLoading: false, invitations: invitations);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }

    return state.invitations;
  }

  // TODO: return back invitation send status like success, fail or alreadyPending and depending on that give response to user
  Future<void> sendInvitation({required String email, String? role}) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      final invitation = await _repository.sendInvitation(
        email: email,
        role: role,
      );
      // Update local state
      state = state.copyWith(
        isLoading: false,
        success: true,
        invitation: invitation,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cancelInvitation(
    String invitationId,
    String organizationId,
  ) async {
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
      bool updated = false;
      invs.map((inv) {
        if (inv.id == invitation.id) {
          updated = true;
          return invitation;
        }
        return inv;
      });

      if (!updated) invs.add(invitation);
    }

    return InvitationState(
      isLoading: isLoading ?? this.isLoading,
      invitations: invs,
      error: error,
      success: success ?? this.success,
    );
  }
}
