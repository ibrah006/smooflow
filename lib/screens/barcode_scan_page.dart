import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smooflow/models/material.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/screens/stock_entry_checkout_screen.dart';
import 'package:smooflow/screens/stock_entry_screen.dart';

class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  void _onDetect(BarcodeCapture barcode) async {
    final String? code = barcode.barcodes.first.rawValue;
    if (code != null) {
      print("scanned barcode: $code");

      try {
        final materialResponse = await ref
            .watch(materialNotifierProvider.notifier)
            .fetchMaterialResponseByBarcode(code);

        // on Success
        Navigator.of(context).pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => StockEntryScreen.stockOut(
                  material: materialResponse.material,
                  transaction: materialResponse.stockTransaction,
                ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Item not found")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: ref.watch(materialNotifierProvider).isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text("Scan Barcode")),
        body: MobileScanner(controller: cameraController, onDetect: _onDetect),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
