import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/notifiers/organization_notifier.dart';
import 'package:smooflow/repositories/organization_repo.dart';

final organizationRepoProvider = Provider<OrganizationRepo>((ref) {
  return OrganizationRepo();
});

final organizationNotifierProvider =
    StateNotifierProvider<OrganizationNotifier, OrganizationState>((ref) {
      final repo = ref.read(organizationRepoProvider);
      return OrganizationNotifier(repo);
    });
