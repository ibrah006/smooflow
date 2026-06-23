class PrintSpec {
  final int id;
  final String? ref;
  final String? size;
  final int? quantity;
  // final int taskId;

  const PrintSpec({required this.id, this.ref, this.size, this.quantity});

  factory PrintSpec.fromJson(Map<String, dynamic> json) {
    return PrintSpec(
      id: json['id'] as int,
      ref: json['ref'] as String?,
      size: json['size'] as String?,
      quantity: json['quantity'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'ref': ref, 'size': size, 'quantity': quantity};
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
