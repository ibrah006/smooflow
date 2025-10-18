import 'package:flutter/foundation.dart';
import 'package:smooflow/repositories/organization_repo.dart';

class OrganizationNotifier extends ChangeNotifier {
  final OrganizationRepo repo;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _organization;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get organization => _organization;

  OrganizationNotifier(this.repo);

  Future<void> createOrganization(String name, {String? description}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final org = await repo.createOrganization(
        name: name,
        description: description,
      );
      _organization = org;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> joinOrganization({String? id, String? name}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final org = await repo.joinOrganization(
        organizationId: id,
        organizationName: name,
      );
      _organization = org;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _error = null;
    _organization = null;
    notifyListeners();
  }
}
