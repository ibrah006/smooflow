// notifier/message_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/websocket_clients/message_websocket.dart';
import 'package:smooflow/core/models/message.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/repositories/message_repo.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/states/message.dart';

class MessageNotifier extends StateNotifier<MessageState> {
  final MessageRepo _repo;
  late final MessageWebSocketClient _client;

  MessageNotifier(this._repo, this._client) : super(MessageState()) {
    _initializeSocket();
  }

  ConnectionStatus get connectionStatus => state.connectionStatus;

  /// Helper to extract readable error
  String _parseError(dynamic e) {
    try {
      return e?.response?.data?['error'] ?? e.toString();
    } catch (_) {
      return "Something went wrong";
    }
  }

  /// GET /messages/:id
  Future<void> getMessageById(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repo.getById(id);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// GET
  /// This function doesn't return result,
  /// rely on results from ref.watch/read(messagesNotifierProvider)
  Future<void> getMessagesByTask(WidgetRef ref, Task task) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      state.messages.firstWhere((m) => m.id == task.lastMessageId);
      // the required messages are in memory for now
    } catch (e) {
      if (task.lastMessageId != null) {
        print(
          "[MESSAGE_NOTIFIER] task ${task.id} last msg id: ${task.lastMessageId}",
        );
        // Last message is not in memory, fetch messages after the local last message id
        await getMessagesAfter(
          afterMessageId: task.lastMessageId!,
          taskId: task.id,
        );
      } else {
        print("[MESSAGE_NOTIFIER] getting recent messages for task ${task.id}");
        // No messages for this task, fetch recent messages for the task
        await getRecent(taskId: task.id);
      }
    }
  }

  Future<void> getRecent({int? taskId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _repo.getRecent(taskId: taskId);

      state = state.copyWith(
        messages: [...state.messages, ...messages],
        isLoading: false,
      );
    } catch (e) {
      print("[get recent msgs] error: ${e}");
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// GET /messages
  Future<void> getAllMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final messages = await _repo.getAll();
      state = state.copyWith(isLoading: false, messages: messages);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// GET /messages/recent
  Future<void> getRecentMessages({
    bool userOnly = false,
    int? taskId,
    int limit = 20,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final recentMessages = await _repo.getRecent(
        userOnly: userOnly,
        taskId: taskId,
        limit: limit,
      );

      final newMessages = _mergeMessages(state.messages, recentMessages);

      state = state.copyWith(messages: newMessages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// POST /messages
  Future<Message?> createMessage({
    required String text,
    required int taskId,
    DateTime? date,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final message = await _repo.create(
        message: text,
        taskId: taskId,
        date: date,
      );

      state = state.copyWith(isLoading: false);

      return message;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));

      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // WEBSOCKET FUNCTIONALITY
  // ─────────────────────────────────────────────────────────────────────────────

  /// Initialize WebSocket and setup listeners
  void _initializeSocket() {
    _initialize();
  }

  void _initialize() {
    // Listen to connection status
    _client.connectionStatus.listen((status) {
      if (mounted) {
        state = state.copyWith(connectionStatus: status);
      }
    });

    // Listen to message changes
    _client.messageChanges.listen(_handleMessageChange);

    // Listen to message list updates
    _client.messageList.listen((messages) {
      if (mounted) {
        state = state.copyWith(
          messages: messages,
          isLoading: false,
          error: null,
        );
      }
    });

    // Listen to errors
    _client.errors.listen((error) {
      if (mounted) {
        state = state.copyWith(error: error, isLoading: false);
      }
    });
  }

  /// Handle message change events from WebSocket
  void _handleMessageChange(MessageChangeEvent event) {
    if (!mounted) {
      return;
    }

    final messages = List<Message>.from(state.messages);

    switch (event.type) {
      case MessageChangeType.created:
        if (event.message != null &&
            !messages.any((t) => t.id == event.messageId)) {
          messages.add(event.message!);
          state = state.copyWith(messages: messages);
          print(
            '[MessageNotifier] message created, new count: ${messages.length}',
          );
        }
        break;

      case MessageChangeType.updated:
        state = state.copyWith(
          messages:
              messages.map((t) {
                if (t.id == event.messageId && event.message != null) {
                  return event.message!;
                }
                return t;
              }).toList(),
        );
        break;
      case MessageChangeType.deleted:
        messages.removeWhere((t) => t.id == event.messageId);
        state = state.copyWith(messages: messages);

        // Clear selected message if it was deleted
        if (state.selectedMessage?.id == event.messageId) {
          state = state.copyWith(selectedMessage: null);
        }
        break;
    }
  }

  /// Load all messages
  Future<void> loadMessages({Map<String, dynamic>? filters}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _client.listMessages(filters: filters);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load messages: $e',
        isLoading: false,
      );
    }
  }

  // Future<void> delete(int id) async {
  //   state = state.copyWith(isLoading: true, error: null);
  //   try {
  //     await _repo.delete(id);

  //     state.messages.removeWhere((message) => message.id == id);
  //     state = state.copyWith(isLoading: false);
  //   } catch (e) {
  //     state = state.copyWith(
  //       error: 'Failed to delete message: $e',
  //       isLoading: false,
  //     );
  //   }
  // }

  /// Refresh messages
  Future<void> refreshMessages() async {
    state = state.copyWith(isLoading: true);
    _client.refreshMessages();
  }

  /// Load a specific message
  Future<void> loadMessage(int messageId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _client.subscribeToMessage(messageId);
      _client.getMessage(messageId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load message: $e',
        isLoading: false,
      );
    }
  }

  Future<void> getMessagesAfter({
    required int afterMessageId,
    int? taskId,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final newMessages = await _repo.getMessagesAfter(
        afterMessageId: afterMessageId,
        taskId: taskId,
      );

      late final updatedList = _mergeMessages(state.messages, newMessages);

      // Step 4: Update state
      state = state.copyWith(messages: updatedList, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to latest messages',
        isLoading: false,
      );
    }
  }

  /// Subscribe to a message
  void subscribeToMessage(int messageId) {
    _client.subscribeToMessage(messageId);
  }

  /// Unsubscribe from a message
  void unsubscribeFromMessage(int messageId) {
    _client.unsubscribeFromMessage(messageId);
  }

  /// Select a message
  void selectMessage(Message message) {
    state = state.copyWith(selectedMessage: message);
    _client.subscribeToMessage(message.id);
  }

  /// Deselect message
  void deselectMessage() {
    if (state.selectedMessage != null) {
      _client.unsubscribeFromMessage(state.selectedMessage!.id);
      state = state.copyWith(selectedMessage: null);
    }
  }
}

// This function assumes that the existing is already sorted by ID
List<Message> _mergeSortedMessages(
  List<Message> existing,
  List<Message> incoming,
) {
  final result = <Message>[];

  int i = 0;
  int j = 0;

  while (i < existing.length && j < incoming.length) {
    final a = existing[i];
    final b = incoming[j];

    if (a.id == b.id) {
      // Replace old with new
      result.add(b);
      i++;
      j++;
    } else if (a.id < b.id) {
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

/// Merges two sorted lists of messages into a single sorted list.
///
/// Both [existing] and [incoming] must already be sorted by `id` in ascending order.
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
      // replace any duplicate with incoming newer version
      result.add(b);
      i++;
      j++;
    } else if (a.id < b.id) {
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
