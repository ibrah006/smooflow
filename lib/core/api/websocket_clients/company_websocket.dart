import 'dart:async';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/local_http.dart';
import 'package:smooflow/core/models/company.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Company change event types
enum CompanyChangeType {
  created,
  updated,
  deleted,
  statusChanged,
  activated,
  deactivated,
}

/// Company change event
class CompanyChangeEvent {
  final CompanyChangeType type;
  final String companyId;
  final Company? company;
  final String? changedBy;
  final DateTime timestamp;
  final Map<String, dynamic>? changes;

  CompanyChangeEvent({
    required this.type,
    required this.companyId,
    this.company,
    this.changedBy,
    required this.timestamp,
    this.changes,
  });

  factory CompanyChangeEvent.fromJson(Map<String, dynamic> json) {
    CompanyChangeType getType(String typeStr) {
      switch (typeStr) {
        case 'created':
          return CompanyChangeType.created;
        case 'updated':
          return CompanyChangeType.updated;
        case 'deleted':
          return CompanyChangeType.deleted;
        case 'status_changed':
          return CompanyChangeType.statusChanged;
        case 'activated':
          return CompanyChangeType.activated;
        case 'deactivated':
          return CompanyChangeType.deactivated;
        default:
          return CompanyChangeType.updated;
      }
    }

    return CompanyChangeEvent(
      type: getType(json['type'] as String),
      companyId: json['companyId'] as String,
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
      changedBy: json['changedBy'] as String?,
      timestamp: DateTime.parse(json['timestamp']),
      changes: json['changes'] as Map<String, dynamic>?,
    );
  }
}

/// Company WebSocket Client
class CompanyWebSocketClient {
  final String authToken = LocalHttp.prefs.get(SharedStorageOptions.jwtToken.name) as String;
  final String baseUrl;
  IO.Socket? _socket;

  // Status streams
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _companyChangeController = StreamController<CompanyChangeEvent>.broadcast();
  final _companyListController = StreamController<List<Company>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // State
  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Set<String> _subscribedCompanies = {};

  CompanyWebSocketClient({
    required this.baseUrl,
  });

  // Getters for streams
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<CompanyChangeEvent> get companyChanges => _companyChangeController.stream;
  Stream<List<Company>> get companyList => _companyListController.stream;
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
      // _socket = IO.io(
      //   baseUrl,
      //   IO.OptionBuilder()
      //       .setPath('/ws/companies')
      //       .setTransports(['websocket', 'polling'])
      //       .setAuth({'token': authToken})
      //       .enableReconnection()
      //       .setReconnectionDelay(1000)
      //       .setReconnectionDelayMax(5000)
      //       .setReconnectionAttempts(_maxReconnectAttempts)
      //       .build(),
      // );
      _socket = IO.io(
        '$baseUrl/companies',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': authToken})
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
      print('Company WebSocket connected: $data');
      _reconnectAttempts = 0;
      _updateStatus(ConnectionStatus.connected);

      // Re-subscribe to companies after reconnection
      for (final companyId in _subscribedCompanies) {
        subscribeToCompany(companyId);
      }
    });

    // Connection error
    _socket!.on('connect_error', (error) {
      print('Company WebSocket connection error: $error');
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
      print('Company WebSocket disconnected: $reason');
      _updateStatus(ConnectionStatus.disconnected);
    });

    // Reconnected
    _socket!.on('reconnect', (attemptNumber) {
      print('Company WebSocket reconnected after $attemptNumber attempts');
      _reconnectAttempts = 0;
      _updateStatus(ConnectionStatus.connected);
    });

    // Company change events
    _socket!.on('company:changed', (data) {
      // try {
        print("data passed: $data");
        final event = CompanyChangeEvent.fromJson(data as Map<String, dynamic>);
        _companyChangeController.add(event);
      // } catch (e) {
      //   print('Error parsing company:changed event: $e');
      // }
    });

    _socket!.on('company:updated', (data) {
      try {
        final event = CompanyChangeEvent.fromJson(data as Map<String, dynamic>);
        _companyChangeController.add(event);
      } catch (e) {
        print('Error parsing company:updated event: $e');
      }
    });

    // Company list response
    _socket!.on('companies:list', (data) {
      try {
        final response = data as Map<String, dynamic>;
        final companiesJson = response['companies'] as List;
        final companies = companiesJson
            .map((json) => Company.fromJson(json as Map<String, dynamic>))
            .toList();
        _companyListController.add(companies);
      } catch (e) {
        print('Error parsing companies:list: $e');
        _errorController.add('Failed to parse company list: $e');
      }
    });

    // Single company data
    _socket!.on('company:data', (data) {
      try {
        final response = data as Map<String, dynamic>;
        final company = Company.fromJson(response['company']);
        // Emit as single-item list or create separate stream if needed
        _companyListController.add([company]);
      } catch (e) {
        print('Error parsing company:data: $e');
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

  /// Subscribe to a specific company
  void subscribeToCompany(String companyId) {
    _ensureConnected();
    _subscribedCompanies.add(companyId);
    _socket!.emit('company:subscribe', companyId);
  }

  /// Unsubscribe from a specific company
  void unsubscribeFromCompany(String companyId) {
    _ensureConnected();
    _subscribedCompanies.remove(companyId);
    _socket!.emit('company:unsubscribe', companyId);
  }

  /// Request current company data
  void getCompany(String companyId) {
    _ensureConnected();
    _socket!.emit('company:get', companyId);
  }

  /// Request list of all companies
  void listCompanies({Map<String, dynamic>? filters}) {
    _ensureConnected();
    _socket!.emit('companies:list', filters);
  }

  /// Refresh companies list
  void refreshCompanies() {
    _ensureConnected();
    _socket!.emit('companies:refresh');
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _subscribedCompanies.clear();
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
    _companyChangeController.close();
    _companyListController.close();
    _errorController.close();
  }
}