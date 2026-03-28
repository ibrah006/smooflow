class QuotationLineItem {
  final String id;
  final int? taskId;
  String description;
  final String? subTitle;
  double qty;
  double unitPrice;

  double get amount => qty * unitPrice;

  QuotationLineItem({
    required this.id,
    this.taskId,
    required this.description,
    this.subTitle,
    required this.qty,
    required this.unitPrice,
  });

  QuotationLineItem copyWith({
    String? description,
    double? qty,
    double? unitPrice,
  }) => QuotationLineItem(
    id: id,
    taskId: taskId,
    description: description ?? this.description,
    qty: qty ?? this.qty,
    unitPrice: unitPrice ?? this.unitPrice,
  );

  // Snapshot for invoice diffing
  Map<String, dynamic> toSnapshot() => {
    'description': description,
    'qty': qty,
    'unitPrice': unitPrice,
  };
}
