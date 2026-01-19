import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/notifiers/invitation_notifier.dart';
import 'package:smooflow/core/repositories/invitation_repo.dart';
import 'package:smooflow/states/invitation.dart';

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository();
});

final invitationNotifierProvider =
    StateNotifierProvider<InvitationNotifier, InvitationState>((ref) {
      final repo = ref.watch(invitationRepositoryProvider);
      return InvitationNotifier(repo);
    });
