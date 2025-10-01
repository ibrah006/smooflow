import 'package:smooflow/api/local_http.dart';

class ApiClient {
  static const baseUrl = 'http://localhost:3000';

  static final LocalHttp http = LocalHttp(baseUrl: baseUrl);
}
