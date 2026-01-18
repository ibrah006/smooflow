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

  Future<http.Response> get(
    String endpoint, {
    String queries = "",
    Map<String, dynamic>? body,
  }) async {
    if (body != null) throw "Don't pass in body for get method";
    final headers = await getHeaders();
    return await http.get(
      Uri.parse('$baseUrl$endpoint$queries'),
      headers: headers,
    );
  }

  // T can be Map<String, dynamic> or decodable List
  Future<http.Response> post<T>(
    String endpoint, {
    T? body,
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
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json', ...await getHeaders()},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String endpoint, {Map? body}) async {
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );
  }
}
