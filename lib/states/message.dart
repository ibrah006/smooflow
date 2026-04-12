// state/message_state.dart

import 'dart:collection';

import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/models/message.dart';

const _MAX_MESSAGES = 20;

enum NewMessageState { messagesAfter, messagesBefore }

class MessageState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  final Message? selectedMessage;

  ConnectionStatus _connectionStatus;

  ConnectionStatus get connectionStatus => _connectionStatus;

  int? activeTaskId;

  // Queue<int> messageAccessQueue;

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
    this.activeTaskId,
    Queue<int>? messageAccessQueue,
  }) : _connectionStatus = connectionStatus;
  //  this.messageAccessQueue = messageAccessQueue ?? Queue<int>();

  MessageState remove({required int messageId}) {
    return MessageState(
      messages: messages.where((m) => m.id != messageId).toList(),
      isLoading: this.isLoading,
      error: this.error,
      connectionStatus: this.connectionStatus,
      selectedMessage: this.selectedMessage,
    );
  }

  MessageState update({required Message updatedMessage}) {
    return MessageState(
      messages:
          messages.map((m) {
            if (m.id == updatedMessage.id) {
              return updatedMessage;
            }
            return m;
          }).toList(),
      isLoading: this.isLoading,
      error: this.error,
      connectionStatus: this.connectionStatus,
      selectedMessage: this.selectedMessage,
    );
  }

  MessageState copyWith({
    // List<Message>? messages,
    List<Message>? newMessages,
    bool? isLoading,
    String? error,
    ConnectionStatus? connectionStatus,
    Message? selectedMessage,
    NewMessageState newMessageState = NewMessageState.messagesAfter,
  }) {
    // --> 1. Check if over memory limit and evict irrelevant messages to the UI

    if (newMessages != null) {
      final totalLength = newMessages.length + messages.length;
      _evict(newMessageState, totalLength);
    }

    // --> 2. Update messages list
    late final List<Message> updatedList;
    if (newMessages != null) {
      if (newMessages.isEmpty) {
        updatedList = this.messages;

        // messageAccessQueue = Queue.from(updatedList.map((m) => m.id));
      } else if (newMessages.length == 1) {
        // DO NOT USE INSERT FOR OTHER THAN CREATE/SEND MESSAGE SCENARIO
        this.messages.insert(0, newMessages.first);

        // messageAccessQueue.add(newMessages.first.id);
      } else {
        updatedList = _mergeMessages(
          this.messages,
          newMessages,
          // ,messageAccessQueue,
        );
      }
    } else {
      updatedList = this.messages;

      // messageAccessQueue = Queue.from(updatedList.map((m) => m.id));
    }

    return MessageState(
      messages: updatedList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      selectedMessage: selectedMessage ?? this.selectedMessage,
      // messageAccessQueue: messageAccessQueue,
    );
  }

  Message? byId(int messageId) {
    try {
      return messages.firstWhere((m) => m.id == messageId);
    } catch (e) {
      // No such message
      return null;
    }
  }

  void _evict(NewMessageState newMessageState, int totalLength) {
    final toRemove = totalLength - _MAX_MESSAGES;

    print("[MessageState] To remove: ${toRemove}");

    if (toRemove <= 0) {
      // Nothing to evict, within memory limit set for messages
      return;
    }

    int removed = 0;
    messages.removeWhere((m) {
      if (removed <= toRemove && m.taskId != activeTaskId) {
        removed++;
        return true;
      }
      return false;
    });

    // Force remove
    while (toRemove > removed) {
      if (newMessageState == NewMessageState.messagesAfter) {
        messages.removeLast();
      } else {
        messages.removeAt(0);
      }
      removed++;
    }
  }
}

/// Merges two sorted lists of messages into a single sorted list.
///
/// Both [existing] and [incoming] must already be sorted by `id` in descending order.
///
/// This function:
/// - Preserves overall sorted order (by `id`)
/// - Inserts incoming messages at the correct positions
/// - Handles gaps in IDs (they do not need to be continuous)
/// - Avoids duplicates by resolving equal IDs
///
/// Duplicate handling:
/// - If a message with the same `id` exists in both lists,
///   the incoming message (`b`) replaces the existing one (`a`).
///   (You can change this behavior if needed.)
///
/// Time complexity: O(n + m)
/// Space complexity: O(n + m)
List<Message> _mergeMessages(List<Message> existing, List<Message> incoming) {
  int i = 0;
  int j = 0;

  final result = <Message>[];

  while (i < existing.length && j < incoming.length) {
    final a = existing[i];
    final b = incoming[j];

    if (a.id == b.id) {
      // ✅ Replace duplicate with incoming
      result.add(b);
      i++;
      j++;
    }
    // 🔥 DESC: bigger id comes first
    else if (a.id > b.id) {
      result.add(a);
      i++;
    } else {
      result.add(b);
      j++;
    }
  }

  // Remaining items
  while (i < existing.length) {
    result.add(existing[i++]);
  }

  while (j < incoming.length) {
    result.add(incoming[j++]);
  }

  return result;
}
