// state/message_state.dart

import 'package:googleapis/chat/v1.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/websocket_clients/message_websocket.dart';

class MessageState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  ConnectionStatus _connectionStatus;

  ConnectionStatus get connectionStatus => _connectionStatus;

  MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    ConnectionStatus connectionStatus = ConnectionStatus.disconnected,
  }) : _connectionStatus = connectionStatus;

  MessageState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      connectionStatus: connectionStatus,
    );
  }
}
