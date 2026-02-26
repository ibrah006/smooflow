import 'dart:async';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/local_http.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Member change event types
enum MemberChangeType {
  created,
  updated,
  deleted,
  roleChanged,
  invited,
  removed,
}

/// Member change event
class MemberChangeEvent {
  final MemberChangeType type;
  final String memberId;
  final Member? member;
  final String? changedBy;
  final DateTime timestamp;
  final Map<String, dynamic>? changes;

  MemberChangeEvent({
    required this.type,
    required this.memberId,
    this.member,
    this.changedBy,
    required this.timestamp,
    this.changes,
  });

  factory MemberChangeEvent.fromJson(Map<String, dynamic> json) {
    MemberChangeType getType(String typeStr) {
      switch (typeStr) {
        case 'created':
          return MemberChangeType.created;
        case 'updated':
          return MemberChangeType.updated;
        case 'deleted':
          return MemberChangeType.deleted;
        case 'role_changed':
          return MemberChangeType.roleChanged;
        case 'invited':
          return MemberChangeType.invited;
        case 'removed':
          return MemberChangeType.removed;
        default:
          return MemberChangeType.updated;
      }
    }

    return MemberChangeEvent(
      type: getType(json['type'] as String),
      memberId: json['memberId'] as String,
      member: json['member'] != null ? Member.fromJson(json['member']) : null,
      changedBy: json['changedBy'] as String?,
      timestamp: DateTime.parse(json['timestamp']),
      changes: json['changes'] as Map<String, dynamic>?,
    );
  }
}

/// Member WebSocket Client
class MemberWebSocketClient {
  final String authToken = LocalHttp.prefs.get(SharedStorageOptions.jwtToken.name) as String;
  final String baseUrl = ApiClient.http.baseUrl;
  IO.Socket? _socket;

  // Status streams
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _memberChangeController = StreamController<MemberChangeEvent>.broadcast();
  final _memberListController = StreamController<List<Member>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // State
  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Set<String> _subscribedMembers = {};

  // Getters for streams
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<MemberChangeEvent> get memberChanges => _memberChangeController.stream;
  Stream<List<Member>> get memberList => _memberListController.stream;
  Stream<String> get errors => _errorController.stream;

  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _updateStatus(ConnectionStatus.connecting);

    try {
      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setPath('/ws/members')
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': authToken})
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(_maxReconnectAttempts)
            .build(),
      );

      _setupEventHandlers();
      _socket!.connect();
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      _errorController.add('Connection failed: $e');
      rethrow;
    }
  }

  /// Setup WebSocket event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;

    // Connection established
    _socket!.on('connected', (data) {
      print('Member WebSocket connected: $data');
      _reconnectAttempts = 0;
      _updateStatus(ConnectionStatus.connected);

      // Re-subscribe to members after reconnection
      for (final memberId in _subscribedMembers) {
        subscribeToMember(memberId);
      }
    });

    // Connection error
    _socket!.on('connect_error', (error) {
      print('Member WebSocket connection error: $error');
      _reconnectAttempts++;
      
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        _updateStatus(ConnectionStatus.error);
        _errorController.add('Failed to connect after $_maxReconnectAttempts attempts');
      } else {
        _updateStatus(ConnectionStatus.reconnecting);
      }
    });

    // Disconnected
    _socket!.on('disconnect', (reason) {
      print('Member WebSocket disconnected: $reason');
      _updateStatus(ConnectionStatus.disconnected);
    });

    // Reconnected
    _socket!.on('reconnect', (attemptNumber) {
      print('Member WebSocket reconnected after $attemptNumber attempts');
      _reconnectAttempts = 0;
      _updateStatus(ConnectionStatus.connected);
    });

    // Member change events
    _socket!.on('member:changed', (data) {
      try {
        final event = MemberChangeEvent.fromJson(data as Map<String, dynamic>);
        _memberChangeController.add(event);
      } catch (e) {
        print('Error parsing member:changed event: $e');
      }
    });

    _socket!.on('member:updated', (data) {
      try {
        final event = MemberChangeEvent.fromJson(data as Map<String, dynamic>);
        _memberChangeController.add(event);
      } catch (e) {
        print('Error parsing member:updated event: $e');
      }
    });

    // Member list response
    _socket!.on('members:list', (data) {
      try {
        final response = data as Map<String, dynamic>;
        final membersJson = response['members'] as List;
        final members = membersJson
            .map((json) => Member.fromJson(json as Map<String, dynamic>))
            .toList();
        _memberListController.add(members);
      } catch (e) {
        print('Error parsing members:list: $e');
        _errorController.add('Failed to parse member list: $e');
      }
    });

    // Single member data
    _socket!.on('member:data', (data) {
      try {
        final response = data as Map<String, dynamic>;
        final member = Member.fromJson(response['member']);
        _memberListController.add([member]);
      } catch (e) {
        print('Error parsing member:data: $e');
      }
    });

    // Error events
    _socket!.on('error', (data) {
      final errorMsg = data['message'] ?? 'Unknown error';
      _errorController.add(errorMsg);
    });

    // User presence
    _socket!.on('user:connected', (data) {
      print('User connected: ${data['userId']}');
    });

    _socket!.on('user:disconnected', (data) {
      print('User disconnected: ${data['userId']}');
    });
  }

  /// Update connection status
  void _updateStatus(ConnectionStatus status) {
    _status = status;
    _connectionStatusController.add(status);
  }

  /// Subscribe to a specific member
  void subscribeToMember(String memberId) {
    _ensureConnected();
    _subscribedMembers.add(memberId);
    _socket!.emit('member:subscribe', memberId);
  }

  /// Unsubscribe from a specific member
  void unsubscribeFromMember(String memberId) {
    _ensureConnected();
    _subscribedMembers.remove(memberId);
    _socket!.emit('member:unsubscribe', memberId);
  }

  /// Request current member data
  void getMember(String memberId) {
    _ensureConnected();
    _socket!.emit('member:get', memberId);
  }

  /// Request list of all members
  void listMembers({Map<String, dynamic>? filters}) {
    _ensureConnected();
    _socket!.emit('members:list', filters);
  }

  /// Refresh members list
  void refreshMembers() {
    _ensureConnected();
    _socket!.emit('members:refresh');
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _subscribedMembers.clear();
    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Ensure socket is connected
  void _ensureConnected() {
    if (_socket == null || !_socket!.connected) {
      throw StateError('WebSocket is not connected. Call connect() first.');
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _memberChangeController.close();
    _memberListController.close();
    _errorController.close();
  }
}