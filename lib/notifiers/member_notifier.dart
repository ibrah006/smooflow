import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/member_repo.dart';
import '../models/member.dart';

class MemberState {
  final bool isLoading;
  final String? error;
  final List<Member> members;

  const MemberState({
    this.isLoading = false,
    this.error,
    this.members = const [],
  });

  MemberState copyWith({
    bool? isLoading,
    String? error,
    List<Member>? members,
  }) {
    return MemberState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      members: members ?? this.members,
    );
  }
}

class MemberNotifier extends StateNotifier<MemberState> {
  final MemberRepo repo;

  MemberNotifier(this.repo) : super(const MemberState());

  /// ✅ Fetch all members from the backend
  Future<List<Member>> get members async {
    try {
      if (state.members.isEmpty) {
        final members = await repo.getOrganizationMembers();
        print("we here");
        state = state.copyWith(isLoading: false, members: members);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }

    return state.members;
  }

  /// Optional: filter members by role
  List<Member> getMembersByRole(String role) {
    return state.members.where((m) => m.role == role).toList();
  }

  /// Optional: clear state (e.g., on logout)
  void reset() {
    state = const MemberState();
  }
}
