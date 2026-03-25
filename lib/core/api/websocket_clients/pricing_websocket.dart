import 'dart:async';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/local_http.dart';
import 'package:smooflow/core/models/pricing.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum PricingChangeType { created, updated, deleted }

class PricingChangeEvent {
  final PricingChangeType type;
  final String pricingId;
  final Map<String, dynamic>? changes;
  final String? changedBy;
  final Pricing pricing;

  PricingChangeEvent({
    required this.type,
    required this.pricingId,
    this.changes,
    required this.changedBy,
    required this.pricing,
  });

  factory PricingChangeEvent.fromJson(Map<String, dynamic> json) {
    PricingChangeType getType(String typeStr) {
      switch (typeStr) {
        case 'created':
          return PricingChangeType.created;
        case 'updated':
          return PricingChangeType.updated;
        case 'deleted':
          return PricingChangeType.deleted;
        default:
          return PricingChangeType.updated;
      }
    }

    return PricingChangeEvent(
      type: getType(json['type'] as String),
      pricingId: json['pricingId'] as String,
      changes: json['changes'] as Map<String, dynamic>?,
      pricing: Pricing.fromJson(json['pricing'] as Map<String, dynamic>),
      changedBy: json['changedBy'],
    );
  }
}

class PricingWebSocketClient {
  final String authToken =
      LocalHttp.prefs.get(SharedStorageOptions.jwtToken.name) as String;
  final String baseUrl = ApiClient.http.baseUrl;
  IO.Socket? _socket;

  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final _pricingChangeController =
      StreamController<PricingChangeEvent>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;

  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;
  Stream<PricingChangeEvent> get pricingChanges =>
      _pricingChangeController.stream;
  Stream<String> get errors => _errorController.stream;

  ConnectionStatus get status => _status;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _updateStatus(ConnectionStatus.connecting);

    try {
      _socket = IO.io(
        '$baseUrl/pricing',
        IO.OptionBuilder().setTransports(['websocket']).setAuth({
          'token': authToken,
        }).build(),
      );
      _setupEventHandlers();
      _socket!.connect();
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      _errorController.add('Connection failed: $e');
      rethrow;
    }
  }

  void _setupEventHandlers() {
    if (_socket == null) return;

    _socket!.on('connected', (_) => _updateStatus(ConnectionStatus.connected));
    _socket!.on(
      'disconnect',
      (_) => _updateStatus(ConnectionStatus.disconnected),
    );
    _socket!.on('pricing:changed', (data) {
      print("new event received, data: ${data}");
      // try {
      final event = PricingChangeEvent.fromJson(data as Map<String, dynamic>);
      _pricingChangeController.add(event);
      print("new event received: ${event}");
      // } catch (e) {
      //   print("event parse failed, ")
      //   _errorController.add('Error parsing pricing:changed event: $e');
      // }
    });
    _socket!.on('error', (data) {
      final errorMsg = data['message'] ?? 'Unknown error';
      _errorController.add(errorMsg);
    });
  }

  void _updateStatus(ConnectionStatus status) {
    _status = status;
    _connectionStatusController.add(status);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _pricingChangeController.close();
    _errorController.close();
  }
}
