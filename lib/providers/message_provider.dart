import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/message.dart';
import 'package:smooflow/core/repositories/message_repo.dart';
import 'package:smooflow/notifiers/message_notifier.dart';
import 'package:smooflow/states/message.dart';

final messageRepoProvider = Provider<MessageRepo>((ref) => MessageRepo());

final messageNotifierProvider =
    StateNotifierProvider<MessageNotifier, MessageState>((ref) {
      final repo = ref.read(messageRepoProvider);
      return MessageNotifier(repo);
    });

final messageConnectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final notifier = ref.watch(messageNotifierProvider.notifier);
  // Create a stream from the MessageNotifier's connection status changes
  return Stream.periodic(
    Duration(milliseconds: 500),
    (_) => notifier.connectionStatus,
  );
});

final messageWebSocketClientProvider = Provider<MessageWebSocketClient>((ref) {
  // Get auth token from your auth provider

  final client = MessageWebSocketClient();

  client.connect();

  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

final messageChangesStreamProvider = StreamProvider<MessageChangeEvent>((ref) {
  final client = ref.watch(messageWebSocketClientProvider);
  return client.messageChanges;
});
