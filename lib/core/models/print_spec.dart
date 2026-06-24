import 'dart:math';

class PrintSpec {
  late final int _id;

  int get id {
    try {
      return _id;
    } catch (e) {
      return _tempId!;
    }
  }

  String? ref;
  String? size;
  int? quantity;
  // final int taskId;

  int? _tempId;

  // int get tempId {
  //   try {
  //     return id;
  //   } catch (e) {
  //     return _tempId;
  //   }
  // }

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

  PrintSpec({required int id, this.ref, this.size, this.quantity}) : _id = id;

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
      id: id ?? this.id,
      ref: ref ?? this.ref,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
    );
  }
}
