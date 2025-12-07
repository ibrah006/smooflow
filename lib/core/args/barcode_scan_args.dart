class BarcodeScanArgs {
  late final String? projectId;

  final bool isStockIn;

  BarcodeScanArgs.stockOut({required this.projectId}) : isStockIn = false;

  BarcodeScanArgs.stockIn() : isStockIn = true;
}
