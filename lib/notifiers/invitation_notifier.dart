import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/invitation.dart';
import 'package:smooflow/repositories/invitation_repo.dart';
import 'package:smooflow/services/login_service.dart';

enum InvitationSendStatus {
  success,
  failed,
  // A request is already pending from this organization
  alreadyPending,
}

class InvitationNotifier extends StateNotifier<InvitationState> {
  final InvitationRepository _repository;

  InvitationNotifier(this._repository) : super(InvitationState());

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
}

class InvitationState {
  final bool isLoading;
  // This is meant to hold current user's invitations and all other invitations from this organization
  // But there are two different function callings for each of those tasks
  // So, at any point, the state could hold any one (invitations to current user and invitations from current organization) or both
  final List<Invitation> invitations;
  final String? error;
  final bool success;

  InvitationState({
    this.isLoading = false,
    this.invitations = const [],
    this.error,
    this.success = false,
    DateTime? lastGetUserInvitations,
  }) : _lastGetUserInvitations = lastGetUserInvitations;

  final DateTime? _lastGetUserInvitations;

  List<Invitation> get getUserInvitations {
    return invitations
        .where((inv) => inv.email == LoginService.currentUser!.email)
        .toList();
  }

  static const intervalBetweenFetchUserInvitationsCalls = Duration(seconds: 20);

  bool get canFetchCurrentUserInvitations =>
      _lastGetUserInvitations != null
          ? DateTime.now().difference(_lastGetUserInvitations) >
              intervalBetweenFetchUserInvitationsCalls
          : true;

  InvitationState copyWith({
    bool? isLoading,
    List<Invitation>? invitations,
    // Adds (to state) if an invitation with this id doesn't exist in state, otherwise updates its existing state
    Invitation? invitation,
    String? error,
    bool? success,
    DateTime? lastGetUserInvitations,
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
      lastGetUserInvitations: lastGetUserInvitations ?? _lastGetUserInvitations,
    );
  }
}
