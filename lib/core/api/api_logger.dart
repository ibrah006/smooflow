import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppLogger {
  static late final PackageInfo packageInfo;

  static Future<void> logError({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {
      // Ignore late init errors
    }
    final currentVersion = packageInfo.version;

    try {
      await http.post(
        Uri.parse("https://your-api.com/logs"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "level": "error",
          "message": message,
          "stack": stackTrace?.toString(),
          "context": context,
          "timestamp": DateTime.now().toIso8601String(),
          "appVersion": currentVersion,
          "device": "flutter, local_name: ${Platform.localeName}",
        }),
      );
    } catch (_) {
      // Never crash app logging
    }
  }
}
