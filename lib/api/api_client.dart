import 'package:smooflow/api/local_http.dart';

class ApiClient {
  static const liveServerUrl = "https://workflow-backend-1-rihm.onrender.com";
  static const baseUrl = 'http://localhost:3000';

  static final LocalHttp http = LocalHttp(baseUrl: liveServerUrl);
}
