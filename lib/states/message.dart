// state/message_state.dart

import 'package:googleapis/chat/v1.dart';

class MessageState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  const MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  MessageState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
