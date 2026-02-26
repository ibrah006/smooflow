import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/websocket_clients/company_websocket.dart';
import 'package:smooflow/core/models/company.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// WebSocket client provider - manages the connection
final companyWebSocketClientProvider = Provider<CompanyWebSocketClient>((ref) {
  // Get auth token from your auth provider
  final baseUrl = ApiClient.http.baseUrl; // Or from config provider
  
  final client = CompanyWebSocketClient(
    baseUrl: baseUrl,
  );

  // Auto-connect when provider is created
  client.connect();

  // Cleanup when provider is disposed
  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

/// Connection status stream provider
final companyConnectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final client = ref.watch(companyWebSocketClientProvider);
  return client.connectionStatus;
});

/// Company changes stream provider
final companyChangesStreamProvider = StreamProvider<CompanyChangeEvent>((ref) {
  final client = ref.watch(companyWebSocketClientProvider);
  return client.companyChanges;
});

/// Company list state notifier
final companyListProvider = StateNotifierProvider<CompanyListNotifier, CompanyListState>((ref) {
  final client = ref.watch(companyWebSocketClientProvider);
  return CompanyListNotifier(client, ref);
});

/// Selected company provider
final selectedCompanyProvider = StateProvider<Company?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// STATE CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class CompanyListState {
  final List<Company> companies;
  final bool isLoading;
  final String? error;
  final ConnectionStatus connectionStatus;

  const CompanyListState({
    this.companies = const [],
    this.isLoading = false,
    this.error,
    this.connectionStatus = ConnectionStatus.disconnected,
  });

  CompanyListState copyWith({
    List<Company>? companies,
    bool? isLoading,
    String? error,
    ConnectionStatus? connectionStatus,
  }) {
    return CompanyListState(
      companies: companies ?? this.companies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class CompanyListNotifier extends StateNotifier<CompanyListState> {
  final CompanyWebSocketClient _client;
  final Ref _ref;

  CompanyListNotifier(this._client, this._ref) : super(const CompanyListState()) {
    _initialize();
  }

  void _initialize() {
    // Listen to connection status
    _client.connectionStatus.listen((status) {
      if (mounted) {
        state = state.copyWith(connectionStatus: status);
      }
    });

    // Listen to company changes
    _client.companyChanges.listen(_handleCompanyChange);

    // Listen to company list
    _client.companyList.listen((companies) {
      if (mounted) {
        state = state.copyWith(
          companies: companies,
          isLoading: false,
          error: null,
        );
      }
    });

    // Listen to errors
    _client.errors.listen((error) {
      if (mounted) {
        state = state.copyWith(
          error: error,
          isLoading: false,
        );
      }
    });
  }

  void _handleCompanyChange(CompanyChangeEvent event) {
    if (!mounted) return;

    final companies = List<Company>.from(state.companies);

    switch (event.type) {
      case CompanyChangeType.created:
        if (event.company != null && !companies.any((c) => c.id == event.companyId)) {
          companies.insert(0, event.company!);
          state = state.copyWith(companies: companies);
        }
        break;

      case CompanyChangeType.updated:
      case CompanyChangeType.statusChanged:
      case CompanyChangeType.activated:
      case CompanyChangeType.deactivated:
        final index = companies.indexWhere((c) => c.id == event.companyId);
        if (index != -1 && event.company != null) {
          companies[index] = event.company!;
          state = state.copyWith(companies: companies);
        }

        // Update selected company if it's the one that changed
        final selectedCompany = _ref.read(selectedCompanyProvider);
        if (selectedCompany?.id == event.companyId && event.company != null) {
          _ref.read(selectedCompanyProvider.notifier).state = event.company;
        }
        break;

      case CompanyChangeType.deleted:
        companies.removeWhere((c) => c.id == event.companyId);
        state = state.copyWith(companies: companies);

        // Clear selected company if it was deleted
        final selectedCompany = _ref.read(selectedCompanyProvider);
        if (selectedCompany?.id == event.companyId) {
          _ref.read(selectedCompanyProvider.notifier).state = null;
        }
        break;
    }
  }

  /// Load all companies
  Future<void> loadCompanies({Map<String, dynamic>? filters}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _client.listCompanies(filters: filters);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load companies: $e',
        isLoading: false,
      );
    }
  }

  /// Refresh companies
  Future<void> refreshCompanies() async {
    state = state.copyWith(isLoading: true);
    _client.refreshCompanies();
  }

  /// Load a specific company
  Future<void> loadCompany(String companyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _client.subscribeToCompany(companyId);
      _client.getCompany(companyId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load company: $e',
        isLoading: false,
      );
    }
  }

  /// Subscribe to a company
  void subscribeToCompany(String companyId) {
    _client.subscribeToCompany(companyId);
  }

  /// Unsubscribe from a company
  void unsubscribeFromCompany(String companyId) {
    _client.unsubscribeFromCompany(companyId);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPUTED PROVIDERS (Filtered/Sorted Lists)
// ─────────────────────────────────────────────────────────────────────────────

/// Active companies provider
final activeCompaniesProvider = Provider<List<Company>>((ref) {
  final state = ref.watch(companyListProvider);
  return state.companies.where((c) => c.isActive).toList();
});

/// Inactive companies provider
final inactiveCompaniesProvider = Provider<List<Company>>((ref) {
  final state = ref.watch(companyListProvider);
  return state.companies.where((c) => !c.isActive).toList();
});

/// Companies by industry provider
final companiesByIndustryProvider = Provider.family<List<Company>, String>((ref, industry) {
  final state = ref.watch(companyListProvider);
  return state.companies.where((c) => c.industry == industry).toList();
});

/// Search companies provider
final searchCompaniesProvider = Provider.family<List<Company>, String>((ref, query) {
  final state = ref.watch(companyListProvider);
  if (query.isEmpty) return state.companies;

  final lowerQuery = query.toLowerCase();
  return state.companies.where((company) {
    return company.name.toLowerCase().contains(lowerQuery) ||
           (company.description?.toLowerCase().contains(lowerQuery) ?? false) ||
           (company.contactName?.toLowerCase().contains(lowerQuery) ?? false) ||
           (company.email?.toLowerCase().contains(lowerQuery) ?? false);
  }).toList();
});

/// All industries provider
final industriesProvider = Provider<List<String>>((ref) {
  final state = ref.watch(companyListProvider);
  final industries = state.companies
      .where((c) => c.industry != null)
      .map((c) => c.industry!)
      .toSet()
      .toList();
  industries.sort();
  return industries;
});

/// Company statistics provider
final companyStatsProvider = Provider<CompanyStats>((ref) {
  final state = ref.watch(companyListProvider);
  return CompanyStats(
    total: state.companies.length,
    active: state.companies.where((c) => c.isActive).length,
    inactive: state.companies.where((c) => !c.isActive).length,
  );
});

class CompanyStats {
  final int total;
  final int active;
  final int inactive;

  const CompanyStats({
    required this.total,
    required this.active,
    required this.inactive,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH TOKEN PROVIDER (Replace with your actual auth provider)
// ─────────────────────────────────────────────────────────────────────────────

/// Replace this with your actual auth token provider
// final authTokenProvider = Provider<String>((ref) {
//   // Get from your auth state/secure storage
//   return 'your-jwt-token';
// });