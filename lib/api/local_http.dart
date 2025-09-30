import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/enums/shared_storage_options.dart';

class LocalHttp {
  String baseUrl;

  LocalHttp({required this.baseUrl});

  static late final SharedPreferences prefs;

  static Future<Map<String, String>> getHeaders() async {
    try {
      final jwtToken = prefs.get(SharedStorageOptions.jwtToken.name);
      return {"Authorization": "Bearer $jwtToken"};
    } catch (e) {
      prefs = await SharedPreferences.getInstance();
      return await getHeaders();
    }
  }

  Future<http.Response> get(String endpoint, {String queries = ""}) async {
    final headers = await getHeaders();
    print("headers: ${headers}");
    return await http.get(
      Uri.parse('$baseUrl$endpoint$queries'),
      headers: headers,
    );
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? headers,
    bool hasJsonHeaders = true,
    String queries = "",
  }) async {
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        ...headers ?? {},
        ...await getHeaders(),
        ...hasJsonHeaders ? {'Content-Type': 'application/json'} : {},
      },
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String endpoint, {Map? body}) async {
    print("body before calling put: $body");
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json', ...await getHeaders()},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint, {Map? body}) async {
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      body: jsonEncode(body),
    );
  }
}
