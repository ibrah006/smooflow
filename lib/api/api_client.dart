import 'package:smooflow/api/local_http.dart';

class ApiClient {
  static const baseUrl = 'http://127.0.0.1:3000';

  static final LocalHttp http = LocalHttp(baseUrl: baseUrl);
}
