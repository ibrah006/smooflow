import 'package:smooflow/core/api/websocket_clients/member_websocket.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/notifiers/member_notifier.dart';
import 'package:smooflow/core/repositories/member_repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/states/member.dart';

final memberRepoProvider = Provider<MemberRepo>((ref) {
  return MemberRepo();
});

final memberNotifierProvider =
    StateNotifierProvider<MemberNotifier, MemberState>((ref) {
      final repo = ref.read(memberRepoProvider);
      return MemberNotifier(repo);
    });

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// WebSocket client provider
final memberWebSocketClientProvider = Provider<MemberWebSocketClient>((ref) {
  
  final client = MemberWebSocketClient();

  client.connect();

  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

/// Connection status stream provider
final memberConnectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final client = ref.watch(memberWebSocketClientProvider);
  return client.connectionStatus;
});

/// Member changes stream provider
final memberChangesStreamProvider = StreamProvider<MemberChangeEvent>((ref) {
  final client = ref.watch(memberWebSocketClientProvider);
  return client.memberChanges;
});

/// Member list state notifier
final memberListProvider = StateNotifierProvider<MemberListNotifier, MemberListState>((ref) {
  final client = ref.watch(memberWebSocketClientProvider);
  return MemberListNotifier(client, ref);
});

/// Selected member provider
final selectedMemberProvider = StateProvider<Member?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// STATE CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class MemberListState {
  final List<Member> members;
  final bool isLoading;
  final String? error;
  final ConnectionStatus connectionStatus;

  const MemberListState({
    this.members = const [],
    this.isLoading = false,
    this.error,
    this.connectionStatus = ConnectionStatus.disconnected,
  });

  MemberListState copyWith({
    List<Member>? members,
    bool? isLoading,
    String? error,
    ConnectionStatus? connectionStatus,
  }) {
    return MemberListState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class MemberListNotifier extends StateNotifier<MemberListState> {
  final MemberWebSocketClient _client;
  final Ref _ref;

  MemberListNotifier(this._client, this._ref) : super(const MemberListState()) {
    _initialize();
  }

  void _initialize() {
    // Listen to connection status
    _client.connectionStatus.listen((status) {
      if (mounted) {
        state = state.copyWith(connectionStatus: status);
      }
    });

    // Listen to member changes
    _client.memberChanges.listen(_handleMemberChange);

    // Listen to member list
    _client.memberList.listen((members) {
      if (mounted) {
        state = state.copyWith(
          members: members,
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

  void _handleMemberChange(MemberChangeEvent event) {
    if (!mounted) return;

    final members = List<Member>.from(state.members);

    switch (event.type) {
      case MemberChangeType.created:
      case MemberChangeType.invited:
        if (event.member != null && !members.any((m) => m.id == event.memberId)) {
          members.insert(0, event.member!);
          state = state.copyWith(members: members);
        }
        break;

      case MemberChangeType.updated:
      case MemberChangeType.roleChanged:
        final index = members.indexWhere((m) => m.id == event.memberId);
        if (index != -1 && event.member != null) {
          members[index] = event.member!;
          state = state.copyWith(members: members);
        }

        // Update selected member if it's the one that changed
        final selectedMember = _ref.read(selectedMemberProvider);
        if (selectedMember?.id == event.memberId && event.member != null) {
          _ref.read(selectedMemberProvider.notifier).state = event.member;
        }
        break;

      case MemberChangeType.deleted:
      case MemberChangeType.removed:
        members.removeWhere((m) => m.id == event.memberId);
        state = state.copyWith(members: members);

        // Clear selected member if it was removed
        final selectedMember = _ref.read(selectedMemberProvider);
        if (selectedMember?.id == event.memberId) {
          _ref.read(selectedMemberProvider.notifier).state = null;
        }
        break;
    }
  }

  /// Load all members
  Future<void> loadMembers({Map<String, dynamic>? filters}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _client.listMembers(filters: filters);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load members: $e',
        isLoading: false,
      );
    }
  }

  /// Refresh members
  Future<void> refreshMembers() async {
    state = state.copyWith(isLoading: true);
    _client.refreshMembers();
  }

  /// Load a specific member
  Future<void> loadMember(String memberId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _client.subscribeToMember(memberId);
      _client.getMember(memberId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load member: $e',
        isLoading: false,
      );
    }
  }

  /// Subscribe to a member
  void subscribeToMember(String memberId) {
    _client.subscribeToMember(memberId);
  }

  /// Unsubscribe from a member
  void unsubscribeFromMember(String memberId) {
    _client.unsubscribeFromMember(memberId);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPUTED PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Members by role provider
final membersByRoleProvider = Provider.family<List<Member>, String>((ref, role) {
  final state = ref.watch(memberListProvider);
  return state.members.where((m) => m.role == role).toList();
});

/// Search members provider
final searchMembersProvider = Provider.family<List<Member>, String>((ref, query) {
  final state = ref.watch(memberListProvider);
  if (query.isEmpty) return state.members;

  final lowerQuery = query.toLowerCase();
  return state.members.where((member) {
    return member.name.toLowerCase().contains(lowerQuery) ||
           member.email.toLowerCase().contains(lowerQuery);
  }).toList();
});

/// Member statistics provider
final memberStatsProvider = Provider<MemberStats>((ref) {
  final state = ref.watch(memberListProvider);
  return MemberStats(
    total: state.members.length,
    admins: state.members.where((m) => m.role == 'admin').length,
    managers: state.members.where((m) => m.role == 'manager').length,
    designers: state.members.where((m) => m.role == 'designer').length,
    delivery: state.members.where((m) => m.role == 'delivery').length,
    viewers: state.members.where((m) => m.role == 'viewer').length,
  );
});

class MemberStats {
  final int total;
  final int admins;
  final int managers;
  final int designers;
  final int delivery;
  final int viewers;

  const MemberStats({
    required this.total,
    required this.admins,
    required this.managers,
    required this.designers,
    required this.delivery,
    required this.viewers,
  });
}
