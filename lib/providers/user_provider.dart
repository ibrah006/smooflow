import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/repositories/user_repo.dart';
import 'package:smooflow/notifiers/user_notifier.dart';
import 'package:smooflow/core/models/user.dart';

final userRepoProvider = Provider<UserRepo>((ref) => UserRepo());

final userNotifierProvider = StateNotifierProvider<UserNotifier, List<User>>((
  ref,
) {
  final repo = ref.watch(userRepoProvider);
  return UserNotifier(repo);
});
