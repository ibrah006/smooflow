class PrintSpec {
  late final int id;
  final String? ref;
  final String? size;
  final int? quantity;
  // final int taskId;

  double get width {
    return size != null ? double.tryParse(size!.split('×').first) ?? 0 : 0;
  }

  double get height {
    return size != null
        ? double.tryParse(size!.split('×')[1].split('cm').first.trim()) ?? 0
        : 0;
  }

  PrintSpec({required this.id, this.ref, this.size, this.quantity});

  PrintSpec.create({this.ref, this.size, this.quantity});

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
