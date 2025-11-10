import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:smooflow/components/product_barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportBarcodesScreen extends StatefulWidget {
  final List<String> barcodes;

  const ExportBarcodesScreen({super.key, required this.barcodes});

  @override
  State<ExportBarcodesScreen> createState() => _ExportBarcodesScreenState();
}

class _ExportBarcodesScreenState extends State<ExportBarcodesScreen> {
  final screenshotCtrl = ScreenshotController();

  Future<void> exportBarcodesToPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              pw.Column(
                children:
                    widget.barcodes.map((code) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(code, style: pw.TextStyle(fontSize: 12)),
                            pw.SizedBox(height: 4),
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.code128(),
                              data: code,
                              width: 200,
                              height: 60,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barcodes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: exportBarcodesToPdf,
          ),
        ],
      ),
      body: Screenshot(
        controller: screenshotCtrl,
        child: _BarcodeList(barcodes: widget.barcodes),
      ),
    );
  }
}

class _BarcodeList extends StatelessWidget {
  final List<String> barcodes;

  const _BarcodeList({super.key, required this.barcodes});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3.5,
      ),
      padding: const EdgeInsets.all(16),
      itemCount: barcodes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ProductBarcode(barcode: barcodes[index]),
        );
      },
    );
  }
}
