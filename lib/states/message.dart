// state/message_state.dart
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/models/message.dart';

class MessageState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  final Message? selectedMessage;

  ConnectionStatus _connectionStatus;

  ConnectionStatus get connectionStatus => _connectionStatus;

  MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    ConnectionStatus connectionStatus = ConnectionStatus.disconnected,
    this.selectedMessage,
  }) : _connectionStatus = connectionStatus;

  MessageState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    ConnectionStatus? connectionStatus,
    Message? selectedMessage,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      selectedMessage: selectedMessage ?? this.selectedMessage,
    );
  }
}
