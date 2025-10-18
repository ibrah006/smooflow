import 'package:smooflow/notifiers/member_notifier.dart';
import 'package:smooflow/repositories/member_repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final memberRepoProvider = Provider<MemberRepo>((ref) {
  return MemberRepo();
});

final memberNotifierProvider =
    StateNotifierProvider<MemberNotifier, MemberState>((ref) {
      final repo = ref.read(memberRepoProvider);
      return MemberNotifier(repo);
    });
