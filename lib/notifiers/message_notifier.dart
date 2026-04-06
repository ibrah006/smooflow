// notifier/message_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/change_events/task_change_event.dart';
import 'package:smooflow/core/repositories/message_repo.dart';
import 'package:smooflow/states/message.dart';

class MessageNotifier extends StateNotifier<MessageState> {
  final MessageRepo repo;

  MessageNotifier(this.repo) : super(MessageState());

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
      await repo.getById(id);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// GET /messages/task/:taskId
  Future<void> getMessagesByTask(int taskId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await repo.getByTaskId(taskId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  /// GET /messages
  Future<void> getAllMessages() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await repo.getAll();
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
      await repo.getRecent(userOnly: userOnly, taskId: taskId, limit: limit);

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
      await repo.create(message: message, taskId: taskId, date: date);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }
}
