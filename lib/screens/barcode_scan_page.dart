import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController cameraController = MobileScannerController();

  void _onDetect(BarcodeCapture barcode) {
    final String? code = barcode.barcodes.first.rawValue;
    if (code != null) {
      print("scanned barcode: $code");
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) =>
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body: MobileScanner(controller: cameraController, onDetect: _onDetect),
    );
  }
}
