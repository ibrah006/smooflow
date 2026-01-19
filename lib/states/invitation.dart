import 'package:smooflow/core/models/invitation.dart';
import 'package:smooflow/services/login_service.dart';

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
    final invs = List<Invitation>.from(invitations ?? this.invitations);

    if (invitation != null) {
      invs.removeWhere((inv) {
        return inv.id == invitation.id;
      });

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