class StockPercentageResult {
  final double percentage;
  final int totalMaterials;
  final int materialsAboveMin;
  final int materialsBelowMin;

  StockPercentageResult({
    required this.percentage,
    required this.totalMaterials,
    required this.materialsAboveMin,
    required this.materialsBelowMin,
  });

  factory StockPercentageResult.fromJson(Map<String, dynamic> json) {
    return StockPercentageResult(
      percentage: (json['percentage'] as num).toDouble(),
      totalMaterials: (json['totalMaterials'] as num).toInt(),
      materialsAboveMin: (json['materialsAboveMin'] as num).toInt(),
      materialsBelowMin: (json['materialsBelowMin'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'percentage': percentage,
        'totalMaterials': totalMaterials,
        'materialsAboveMin': materialsAboveMin,
        'materialsBelowMin': materialsBelowMin,
      };
}
