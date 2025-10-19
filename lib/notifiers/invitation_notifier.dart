import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/invitation.dart';
import 'package:smooflow/repositories/invitation_repo.dart';

class InvitationNotifier extends StateNotifier<InvitationState> {
  final InvitationRepository _repository;

  InvitationNotifier(this._repository) : super(const InvitationState());

  Future<void> fetchInvitations(String organizationId) async {
    state = state.copyWith(isLoading: true);
    try {
      final invitations = await _repository.getOrganizationInvitations(
        organizationId,
      );
      state = state.copyWith(isLoading: false, invitations: invitations);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendInvitation({
    required String email,
    required String organizationId,
    String? role,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _repository.sendInvitation(
        email: email,
        organizationId: organizationId,
        role: role,
      );
      state = state.copyWith(isLoading: false, success: true);
      await fetchInvitations(organizationId);
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
      await fetchInvitations(organizationId);
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
    String? error,
    bool? success,
  }) {
    return InvitationState(
      isLoading: isLoading ?? this.isLoading,
      invitations: invitations ?? this.invitations,
      error: error,
      success: success ?? this.success,
    );
  }
}
