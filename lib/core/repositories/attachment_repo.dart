import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:smooflow/screens/desktop/components/attachements_section.dart';

/// Talks to the /tasks/:taskId/attachments endpoints and to R2 directly for
/// the actual file bytes (the backend only ever hands back a presigned URL —
/// it never proxies the upload).
class AttachmentRepository {
  final String
  baseUrl; // ADJUST: match however your other repositories get this
  final String? Function() authToken; // ADJUST: match your auth token accessor

  AttachmentRepository({required this.baseUrl, required this.authToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken() != null) 'Authorization': 'Bearer ${authToken()}',
  };

  /// Full flow: presign -> PUT bytes to R2 -> confirm with the backend.
  /// Returns the persisted attachment once all three steps succeed.
  Future<TaskAttachment> uploadFile(
    int taskId,
    String path, {
    ValueChanged<double>? onProgress,
  }) async {
    final file = File(path);
    final fileName = path.split(Platform.pathSeparator).last;
    final mimeType = lookupMimeType(path) ?? 'application/octet-stream';
    final sizeBytes = await file.length();

    final presign = await _presign(
      taskId,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );

    await _putToR2(presign['uploadUrl'] as String, file, mimeType);
    onProgress?.call(1.0);

    return confirmUpload(
      taskId,
      objectKey: presign['objectKey'] as String,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );
  }

  Future<Map<String, dynamic>> _presign(
    int taskId, {
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/attachments/presign'),
      headers: _headers,
      body: jsonEncode({
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to get upload URL (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _putToR2(String uploadUrl, File file, String mimeType) async {
    final bytes = await file.readAsBytes();
    final res = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': mimeType},
      body: bytes,
    );
    if (res.statusCode != 200) {
      throw Exception('Upload to storage failed (${res.statusCode})');
    }
  }

  Future<TaskAttachment> confirmUpload(
    int taskId, {
    required String objectKey,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/attachments'),
      headers: _headers,
      body: jsonEncode({
        'objectKey': objectKey,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to save attachment (${res.statusCode})');
    }
    return _fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<TaskAttachment>> list(int taskId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId/attachments'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load attachments (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List;
    return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> delete(int taskId, int attachmentId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId/attachments/$attachmentId'),
      headers: _headers,
    );
    if (res.statusCode != 204) {
      throw Exception('Failed to delete attachment (${res.statusCode})');
    }
  }

  TaskAttachment _fromJson(Map<String, dynamic> json) => TaskAttachment(
    id: json['id'] as int,
    fileName: json['fileName'] as String,
    url: json['url'] as String,
    sizeBytes: json['sizeBytes'] as int,
    mimeType: json['mimeType'] as String,
    uploadedByName: json['uploadedByName'] as String? ?? '',
    uploadedAt: DateTime.parse(json['createdAt'] as String),
  );
}

typedef ValueChanged<T> = void Function(T value);
