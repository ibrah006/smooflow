import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/repositories/organization_repo.dart';

/// --- STATE MODEL --- ///
class OrganizationState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? organization;

  const OrganizationState({
    this.isLoading = false,
    this.error,
    this.organization,
  });

  OrganizationState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? organization,
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

  OrganizationNotifier(this.repo) : super(const OrganizationState());

  Future<void> createOrganization(String name, {String? description}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final org = await repo.createOrganization(
        name: name,
        description: description,
      );
      state = state.copyWith(isLoading: false, organization: org);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
