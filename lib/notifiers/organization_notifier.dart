import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/organization.dart';
import 'package:smooflow/repositories/organization_repo.dart';
import 'package:smooflow/services/login_service.dart';

/// --- STATE MODEL --- ///
class OrganizationState {
  final bool isLoading;
  final String? error;
  final List<Organization> organizations;

  const OrganizationState({
    this.isLoading = false,
    this.error,
    this.organizations = const [],
  });

  OrganizationState copyWith({
    bool? isLoading,
    String? error,
    Organization? organization,
  }) {
    return OrganizationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      organizations: [
        ...organizations,
        ...organization != null ? [organization] : [],
      ],
    );
  }
}

/// --- STATE NOTIFIER --- ///
class OrganizationNotifier extends StateNotifier<OrganizationState> {
  final OrganizationRepo repo;

  OrganizationNotifier(this.repo) : super(const OrganizationState());

  Future<Organization> get getCurrentOrganization async {
    late final Organization organization;
    try {
      organization = state.organizations.firstWhere(
        (org) => org.id == LoginService.currentUser!.organizationId,
      );
    } catch (e) {
      state.copyWith(isLoading: true);

      late final String? error;
      try {
        organization = await repo.getCurrentOrganization();
        error = null;
      } catch (e) {
        error = e.toString();
        print("error: $e");
      }
      state.copyWith(
        isLoading: false,
        error: error,
        organization: organization,
      );
    }

    return organization;
  }

  Future<Organization?> createOrganization(
    String name, {
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final org = await repo.createOrganization(
        name: name,
        description: description,
      );

      state = state.copyWith(isLoading: false, organization: org);
      return org;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> joinOrganization({String? id, String? name}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final org = await repo.joinOrganization(
        organizationId: id,
        organizationName: name,
      );
      state = state.copyWith(isLoading: false, organization: org);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const OrganizationState();
  }
}
