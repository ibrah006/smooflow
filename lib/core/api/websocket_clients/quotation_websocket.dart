import 'dart:async';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/local_http.dart';
import 'package:smooflow/core/models/quotation.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum QuotationChangeType { created, updated, deleted }

class QuotationChangeEvent {
  final QuotationChangeType type;
  final String quotationId;
  final Map<String, dynamic>? changes;
  final String? changedBy;
  final Quotation quotation;

  QuotationChangeEvent({
    required this.type,
    required this.quotationId,
    this.changes,
    required this.changedBy,
    required this.quotation,
  });

  factory QuotationChangeEvent.fromJson(Map<String, dynamic> json) {
    QuotationChangeType getType(String typeStr) {
      switch (typeStr) {
        case 'created':
          return QuotationChangeType.created;
        case 'updated':
          return QuotationChangeType.updated;
        case 'deleted':
          return QuotationChangeType.deleted;
        default:
          return QuotationChangeType.updated;
      }
    }

    return QuotationChangeEvent(
      type: getType(json['type'] as String),
      quotationId: json['quotationId'] as String,
      changes: json['changes'] as Map<String, dynamic>?,
      quotation: Quotation.fromJson(json['quotation'] as Map<String, dynamic>),
      changedBy: json['changedBy'],
    );
  }
}

class QuotationWebSocketClient {
  final String authToken =
      LocalHttp.prefs.get(SharedStorageOptions.jwtToken.name) as String;
  final String baseUrl = ApiClient.http.baseUrl;
  IO.Socket? _socket;

  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final _quotationChangeController =
      StreamController<QuotationChangeEvent>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;

  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;
  Stream<QuotationChangeEvent> get quotationChanges =>
      _quotationChangeController.stream;
  Stream<String> get errors => _errorController.stream;

  ConnectionStatus get status => _status;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    _updateStatus(ConnectionStatus.connecting);

    try {
      _socket = IO.io(
        '$baseUrl/quotation',
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
    _socket!.on('quotation:changed', (data) {
      try {
        final event = QuotationChangeEvent.fromJson(
          data as Map<String, dynamic>,
        );
        _quotationChangeController.add(event);
      } catch (e) {
        _errorController.add('Error parsing quotation:changed event: $e');
      }
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
    _quotationChangeController.close();
    _errorController.close();
  }
}
