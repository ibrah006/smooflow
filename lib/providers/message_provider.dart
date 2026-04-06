import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/repositories/message_repo.dart';
import 'package:smooflow/notifiers/message_notifier.dart';
import 'package:smooflow/states/message.dart';

final messageRepoProvider = Provider<MessageRepo>((ref) => MessageRepo());

final messageNotifierProvider =
    StateNotifierProvider<MessageNotifier, MessageState>((ref) {
      final repo = ref.read(messageRepoProvider);
      return MessageNotifier(repo);
    });
