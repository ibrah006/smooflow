import 'package:flutter/material.dart';

extension ColorHexExtension on Color {
  String toHex() {
    final argb = toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}

extension HexColorExtension on String {
  Color? toColor() {
    try {
      final hex = replaceFirst('#', '');

      if (hex.length != 6 && hex.length != 8) return null;

      final buffer = StringBuffer();

      if (hex.length == 6) {
        buffer.write('ff'); // default alpha
      }

      buffer.write(hex);

      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }
}