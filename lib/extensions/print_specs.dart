import 'package:smooflow/core/models/print_spec.dart';

extension SizeNormalization on PrintSpec {
  String? get normalizeSize {
    if (size == null) return null;

    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*[xX×*]\s*(\d+(?:\.\d+)?)\s*(cm|mm|in|inch|inches|m|ft)?',
      caseSensitive: false,
    ).firstMatch(size!);

    if (match == null) {
      return size!.trim().toLowerCase();
    }

    final width = double.parse(match.group(1)!);
    final height = double.parse(match.group(2)!);
    final unit = match.group(3)?.toLowerCase();

    final normalizedUnit = switch (unit) {
      'inch' || 'inches' => 'in',
      _ => unit ?? '',
    };

    return '$width x $height $normalizedUnit';
  }
}
