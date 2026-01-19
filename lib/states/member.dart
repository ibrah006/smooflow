import 'package:smooflow/core/models/member.dart';

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
    Member? member,
  }) {
    members = List.from(members ?? this.members);

    if (member != null) {
      members.removeWhere((mem) => mem.id == member.id);
      members.add(member);
    }

    return MemberState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      members: members,
    );
  }
}