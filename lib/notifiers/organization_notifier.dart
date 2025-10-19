import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/models/organization.dart';
import 'package:smooflow/repositories/organization_repo.dart';

/// --- STATE MODEL --- ///
class OrganizationState {
  final bool isLoading;
  final String? error;
  final Organization? organization;

  const OrganizationState({
    this.isLoading = false,
    this.error,
    this.organization,
  });

  OrganizationState copyWith({
    bool? isLoading,
    String? error,
    Organization? organization,
  }) {
    return OrganizationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      organization: organization ?? this.organization,
    );
  }
}

/// --- STATE NOTIFIER --- ///
class OrganizationNotifier extends StateNotifier<OrganizationState> {
  final OrganizationRepo repo;

  OrganizationNotifier(this.repo) : super(OrganizationState());

  Future<Organization> get getCurrentOrganization async {
    late final Organization organization;
    try {
      organization = state.organization!;
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
    state = OrganizationState();
  }
}
