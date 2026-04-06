import 'dart:async';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/api_client.dart';
import 'package:smooflow/core/api/local_http.dart';
import 'package:smooflow/core/models/message.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Message change event types
enum MessageChangeType { created, updated, deleted }

/// Message change event from WebSocket
class MessageChangeEvent {
  final MessageChangeType type;
  final int messageId;
  final Message? message;
  final String? changedBy;
  final DateTime timestamp;
  final Map<String, dynamic>? changes;

  MessageChangeEvent({
    required this.type,
    required this.messageId,
    this.message,
    this.changedBy,
    required this.timestamp,
    this.changes,
  });

  factory MessageChangeEvent.fromJson(Map<String, dynamic> json) {
    MessageChangeType getType(String typeStr) {
      switch (typeStr) {
        case 'created':
          return MessageChangeType.created;
        case 'updated':
          return MessageChangeType.updated;
        case 'deleted':
          return MessageChangeType.deleted;
        default:
          return MessageChangeType.updated;
      }
    }

    return MessageChangeEvent(
      type: getType(json['type'] as String),
      messageId: json['messageId'] as int,
      message:
          json['message'] != null ? Message.fromJson(json['message']) : null,
      changedBy: json['changedBy'] as String?,
      timestamp: DateTime.parse(json['timestamp']),
      changes: json['changes'] as Map<String, dynamic>?,
    );
  }
}

/// Message WebSocket Client
class MessageWebSocketClient {
  final String authToken =
      LocalHttp.prefs.get(SharedStorageOptions.jwtToken.name) as String;
  IO.Socket? _socket;

  // Status streams
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final _messageChangeController =
      StreamController<MessageChangeEvent>.broadcast();
  final _messageListController = StreamController<List<Message>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // State
  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Set<int> _subscribedMessages = {};

  MessageWebSocketClient();

  // Getters for streams
  Stream<ConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;
  Stream<MessageChangeEvent> get messageChanges =>
      _messageChangeController.stream;
  Stream<List<Message>> get messageList => _messageListController.stream;
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
        '${ApiClient.http.baseUrl}/messages',
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

  /// Setup WebSocket event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;

    // Connection established
    _socket!.on('connected', (data) {
      print('WebSocket connected: $data');
      _reconnectAttempts = 0;
      _updateStatus(ConnectionStatus.connected);

      // Re-subscribe to messages after reconnection
      for (final messageId in _subscribedMessages) {
        subscribeToMessage(messageId);
      }
    });

    // Connection error
    _socket!.on('connect_error', (error) {
      print('WebSocket connection error: $error');
      _reconnectAttempts++;

      if (_reconnectAttempts >= _maxReconnectAttempts) {
        _updateStatus(ConnectionStatus.error);
        _errorController.add(
          'Failed to connect after $_maxReconnectAttempts attempts',
        );
      } else {
        _updateStatus(ConnectionStatus.reconnecting);
      }
    });

    // Disconnected
    _socket!.on('disconnect', (reason) {
      print('WebSocket disconnected: $reason');
      _updateStatus(ConnectionStatus.disconnected);
    });

    // Reconnected
    _socket!.on('reconnect', (attemptNumber) {
      print('WebSocket reconnected after $attemptNumber attempts');
      _reconnectAttempts = 0;
      _updateStatus(ConnectionStatus.connected);
    });

    // Message change events
    _socket!.on('message:changed', (data) {
      try {
        final event = MessageChangeEvent.fromJson(data as Map<String, dynamic>);
        _messageChangeController.add(event);
      } catch (e) {
        print('Error parsing message:changed event: $e');
      }
    });

    _socket!.on('message:updated', (data) {
      try {
        final event = MessageChangeEvent.fromJson(data as Map<String, dynamic>);
        _messageChangeController.add(event);
      } catch (e) {
        print('Error parsing message:updated event: $e');
      }
    });

    // Message list response
    _socket!.on('messages:list', (data) {
      try {
        final response = data as Map<String, dynamic>;
        final messagesJson = response['messages'] as List;
        final messages =
            messagesJson
                .map((json) => Message.fromJson(json as Map<String, dynamic>))
                .toList();
        _messageListController.add(messages);
      } catch (e) {
        print('Error parsing messages:list: $e');
        _errorController.add('Failed to parse message list: $e');
      }
    });

    // Single message data
    _socket!.on('message:data', (data) {
      try {
        final response = data as Map<String, dynamic>;
        final message = Message.fromJson(response['message']);
        // Emit as single-item list or create separate stream if needed
        _messageListController.add([message]);
      } catch (e) {
        print('Error parsing message:data: $e');
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

  /// Subscribe to a specific message
  void subscribeToMessage(int messageId) {
    _ensureConnected();
    _subscribedMessages.add(messageId);
    _socket!.emit('message:subscribe', messageId);
  }

  /// Unsubscribe from a specific message
  void unsubscribeFromMessage(int messageId) {
    _ensureConnected();
    _subscribedMessages.remove(messageId);
    _socket!.emit('message:unsubscribe', messageId);
  }

  /// Request current message data
  void getMessage(int messageId) {
    _ensureConnected();
    _socket!.emit('message:get', messageId);
  }

  /// Request list of all messages
  void listMessages({Map<String, dynamic>? filters}) {
    _ensureConnected();
    _socket!.emit('messages:list', filters);
  }

  /// Refresh messages list
  void refreshMessages() {
    _ensureConnected();
    _socket!.emit('messages:refresh');
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _subscribedMessages.clear();
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
    _messageChangeController.close();
    _messageListController.close();
    _errorController.close();
  }
}
