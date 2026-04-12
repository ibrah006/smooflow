// state/message_state.dart
import 'dart:collection';

import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/models/message.dart';

class MessageState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  final Message? selectedMessage;

  ConnectionStatus _connectionStatus;

  ConnectionStatus get connectionStatus => _connectionStatus;

  /// Messages that cannot be removed from state to free up memory
  /// 1. Messages that are still being displayed in the UI
  ///  - Discussion form
  /// 2. Messages that are still being processed
  /// Tasks whose messages shouldn't be removed from state because of the above reasons
  final List<int> priorityTasks;

  Message? lastMessageForTask(int taskId) {
    try {
      return messages.firstWhere((m) => m.taskId == taskId);
    } catch (e) {
      return null;
    }
  }

  MessageState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    ConnectionStatus connectionStatus = ConnectionStatus.disconnected,
    this.selectedMessage,
    this.priorityTasks = const [],
  }) : _connectionStatus = connectionStatus;

  MessageState prioritizeTask(int taskId) {
    if (!priorityTasks.contains(taskId)) {
      this.priorityTasks.add(taskId);
    }
    return this;
  }

  MessageState deprioritizeTask(int taskId) {
    this.priorityTasks.remove(taskId);
    return this;
  }

  MessageState copyWith({
    // List<Message>? messages,
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
