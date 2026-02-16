import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/screen_responses/barcode_scan_response.dart';
import 'package:smooflow/notifiers/material_notifier.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/screens/stock_entry_screen.dart';

class BarcodeScanScreen extends ConsumerStatefulWidget {
  late final String? projectId;

  final bool isStockIn;
  final bool isDraft;

  BarcodeScanScreen.stockOut({required this.projectId}) : isStockIn = false, isDraft = false;

  BarcodeScanScreen.stockIn() : isStockIn = true, isDraft = false;

  BarcodeScanScreen.draft({required this.projectId}) : isStockIn = false, isDraft = true;

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  void _onDetect(BarcodeCapture barcode) async {

    await cameraController.stop();

    final String? code = barcode.barcodes.first.rawValue;
    if (code != null) {
      print("scanned barcode: $code");

      try {
        late final MaterialResponse materialResponse;
        late final MaterialModel material;
        if (!widget.isStockIn) {
          materialResponse = await ref
              .watch(materialNotifierProvider.notifier)
              .fetchMaterialResponseByBarcode(code);
        } else {
          material = await ref
              .watch(materialNotifierProvider.notifier)
              .fetchMaterialByMaterialBarcode(code);
        }

        // on Success
        final quantity = await Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => widget.isDraft? StockEntryScreen.draft(
                      isStockIn: widget.isStockIn,
                      material: materialResponse.material,
                      transaction: materialResponse.stockTransaction,
                      projectId: widget.projectId,
                    ) :
                    !widget.isStockIn
                        ? StockEntryScreen.stockOut(
                          material: materialResponse.material,
                          transaction: materialResponse.stockTransaction,
                          projectId: widget.projectId,
                        )
                        : StockEntryScreen.stockin(material: material),
          ),
        );

        if (quantity == null) {
          // User cancelled the stock entry screen
          Navigator.pop(context, null);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Stock entry cancelled by user")));
          return;
        }

        Navigator.pop(context, BarcodeScanResponse(barcode: code, quantity: quantity));
      } catch (e) {
        print("error: $e");
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
