import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/api/local_http.dart';
import 'package:smooflow/core/repositories/attachment_repo.dart';
import 'package:smooflow/enums/shared_storage_options.dart';

// ADJUST: swap in your app's real base URL constant/config (same one your
// other repositories/providers use) and however LoginService actually
// exposes the current auth token.
const String _kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final jwtToken =
      LocalHttp.prefs.get(SharedStorageOptions.jwtToken.name) as String;

  return AttachmentRepository(baseUrl: _kApiBaseUrl, authToken: () => jwtToken);
});
