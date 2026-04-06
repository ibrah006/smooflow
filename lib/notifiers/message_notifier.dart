// notifier/message_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/api/websocket_clients/message_websocket.dart';
import 'package:smooflow/core/models/message.dart';
import 'package:smooflow/core/repositories/message_repo.dart';
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

  /// GET /messages/task/:taskId
  Future<void> getMessagesByTask(int messageId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repo.getByTaskId(messageId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// GET /messages
  Future<void> getAllMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repo.getAll();
      state = state.copyWith(isLoading: false);
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
      await _repo.getRecent(userOnly: userOnly, taskId: taskId, limit: limit);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// POST /messages
  Future<void> createMessage({
    required String message,
    required int taskId,
    DateTime? date,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repo.create(message: message, taskId: taskId, date: date);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
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

      final updatedList = _mergeSortedMessages(state.messages, newMessages);

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
}
