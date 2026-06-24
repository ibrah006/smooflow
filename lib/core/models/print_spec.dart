import 'dart:math';

import 'package:uuid/uuid.dart';

class PrintSpec {
  late final int id;
  String? ref;
  String? size;
  int? quantity;
  // final int taskId;

  late final int _tempId;

  int get tempId {
    try {
      return id;
    } catch (e) {
      return _tempId;
    }
  }

  double get width {
    return size != null ? double.tryParse(size!.split('×').first) ?? 0 : 0;
  }

  double get height {
    return size != null && unit != null
        ? double.tryParse(size!.split('×')[1].split(unit!).first.trim()) ?? 0
        : 0;
  }

  String? get unit {
    return size != null ? size!.split('×')[1].split(' ')[1] : null;
  }

  PrintSpec({required this.id, this.ref, this.size, this.quantity});

  PrintSpec.create({this.ref, this.size, this.quantity})
    : _tempId = Random().nextInt(2000000) * -1;

  factory PrintSpec.fromJson(Map<String, dynamic> json) {
    return PrintSpec(
      id: json['id'] as int,
      ref: json['ref'] as String?,
      size: json['size'] as String?,
      quantity: json['quantity'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'ref': ref, 'size': size, 'quantity': quantity};
  }

  PrintSpec copyWith({
    int? id,
    String? ref,
    String? size,
    int? quantity,
    int? taskId,
  }) {
    return PrintSpec(
      id: id ?? this.tempId,
      ref: ref ?? this.ref,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
    );
  }
}
