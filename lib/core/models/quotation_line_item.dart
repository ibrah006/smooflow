class QuotationLineItem {
  final String id;
  final int? taskId;
  String description;
  final String? subTitle;
  String? _size;

  String? get size {
    final String? s;
    if (subTitle?.contains("Size") ?? false) {
      final subTitleSplit = subTitle?.split("Size: ");

      s = subTitleSplit![1].split("cm")[0];
    } else {
      s = null;
    }
    return _size ?? s;
  }

  set size(String? value) {
    _size = value;
  }

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
    String? size,
  }) : _size = size;

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

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'description': description,
    'subTitle': subTitle,
    'qty': qty,
    'unitPrice': unitPrice,
  };

  factory QuotationLineItem.fromJson(Map<String, dynamic> json) =>
      QuotationLineItem(
        id: json['id'],
        taskId: json['taskId'],
        description: json['description'],
        subTitle: json['subTitle'],
        qty: double.tryParse(json['qty']) ?? 0,
        unitPrice: double.tryParse(json['unitPrice']) ?? 0,
      );
}
