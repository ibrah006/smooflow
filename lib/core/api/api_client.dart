import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smooflow/core/api/local_http.dart';

class ApiClient {
  static get liveServerUrl => dotenv.env['API_URL'];
  static var localDevUrl = 'http://192.168.0.188:3000';

  static final LocalHttp http = LocalHttp(baseUrl: localDevUrl);
}
