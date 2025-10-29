import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/cupertino.dart';

class ProductBarcode extends StatelessWidget {
  final String barcode;

  const ProductBarcode({super.key, required this.barcode});

  @override
  Widget build(BuildContext context) {
    return BarcodeWidget(
      barcode: Barcode.code128(), // or Barcode.qrCode()
      data: barcode, // e.g. "PROD-001"
      height: 80,
      drawText: true, // shows productId under barcode
    );
  }
}
