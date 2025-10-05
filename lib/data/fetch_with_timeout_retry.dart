import 'dart:async';

import 'package:http/http.dart' as http;

Future<http.Response?> fetchWithTimeoutAndRetry({
  required String url,
  Duration timeout = const Duration(seconds: 50),
  int maxRetries = 3,
  Duration retryDelay = const Duration(seconds: 3),
  required Future<http.Response> Function(
    String endpoint, {
    Map<String, dynamic>? body,
  })
  methodCall,
  Map<String, dynamic>? body,
}) async {
  int attempt = 0;

  while (attempt < maxRetries) {
    attempt++;
    try {
      final response = await methodCall(url, body: body).timeout(timeout);

      if (response.statusCode == 200) {
        return response; // ✅ Success
      } else {
        print("Server responded with ${response.statusCode}");
        return null;
      }
    } on TimeoutException catch (_) {
      print("Attempt $attempt: Request timed out");
      if (attempt < maxRetries) {
        await Future.delayed(retryDelay);
      }
    } catch (e) {
      print("Attempt $attempt: Request failed - $e");
      if (attempt < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }
  }

  print("All $maxRetries attempts failed.");
  return null;
}
