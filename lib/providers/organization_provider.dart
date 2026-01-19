import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/notifiers/organization_notifier.dart';
import 'package:smooflow/core/repositories/organization_repo.dart';
import 'package:smooflow/states/organization.dart';

final organizationRepoProvider = Provider<OrganizationRepo>((ref) {
  return OrganizationRepo();
});

final organizationNotifierProvider =
    StateNotifierProvider<OrganizationNotifier, OrganizationState>((ref) {
      final repo = ref.read(organizationRepoProvider);
      return OrganizationNotifier(repo);
    });
