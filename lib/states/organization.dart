import 'package:smooflow/core/models/organization.dart';

class OrganizationState {
  final bool isLoading;
  final String? error;
  final Organization? organization;
  final DateTime? projectsLastAdded;

  const OrganizationState({
    this.isLoading = false,
    this.error,
    Organization? organization,
    this.projectsLastAdded,
  }) : this.organization = organization;

  OrganizationState copyWith({
    bool? isLoading,
    String? error,
    Organization? organization,
    DateTime? projectsLastAdded,
  }) {
    return OrganizationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      organization: organization ?? this.organization,
      projectsLastAdded: this.projectsLastAdded ?? projectsLastAdded,
    );
  }
}