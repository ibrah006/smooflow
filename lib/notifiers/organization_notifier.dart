import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/organization.dart';
import 'package:smooflow/core/repositories/organization_repo.dart';
import 'package:smooflow/states/organization.dart';

/// --- STATE NOTIFIER --- ///
class OrganizationNotifier extends StateNotifier<OrganizationState> {
  final OrganizationRepo repo;

  OrganizationNotifier(this.repo) : super(OrganizationState());

  Future<void> claimDomainOwnership() async {
    final isSuccess = await repo.claimDomainOwnership();

    if (!isSuccess) {
      throw "Failed to claim ownership. Perhaps, an organization already holds ownership of this domain";
    }
  }

  Future<Organization> get getCurrentOrganization async {
    late final Organization organization;
    try {
      organization = state.organization!;
    } catch (e) {
      state = state.copyWith(isLoading: true);

      late final String? error;
      try {
        organization = await repo.getCurrentOrganization();
        error = null;
      } catch (e) {
        error = e.toString();
        print("error: $e");
      }
      state = state.copyWith(
        isLoading: false,
        error: error,
        organization: organization,
      );
    }

    return organization;
  }

  Future<CreateOrganizationResponse?> createOrganization(
    String name, {
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // try {
    final organizationResponse = await repo.createOrganization(
      name: name,
      description: description,
    );

    state = state.copyWith(
      isLoading: false,
      organization: organizationResponse.organization,
    );

    return organizationResponse;
    // } catch (e) {
    //   state = state.copyWith(isLoading: false, error: e.toString());
    //   return null;
    // }
  }

  Future<void> joinOrganization(String orgId, {required String role}) async {
    state = state.copyWith(isLoading: true, error: null);

    // try {
    final org = await repo.joinOrganization(organizationId: orgId, role: role);
    state = state.copyWith(isLoading: false, organization: org);
    // } catch (e) {
    //   state = state.copyWith(isLoading: false, error: e.toString());
    // }
  }

  void projectAdded() {
    state = state.copyWith(projectsLastAdded: DateTime.now());
  }

  void reset() {
    state = OrganizationState();
  }
}
