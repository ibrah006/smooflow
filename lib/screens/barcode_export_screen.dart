import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // Load font from assets
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData(defaultTextStyle: pw.TextStyle(font: ttf)),
        ),
        build:
            (context) => pw.Column(
              children:
                  widget.barcodes.map((code) {
                    return pw.Container(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(code, style: pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(height: 4),
                          // pw.BarcodeWidget(
                          //   barcode: pw.Barcode.code128(),
                          //   data: code,
                          //   width: 200,
                          //   height: 60,
                          // ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
      ),
    );

    // 2. Convert PDF document to bytes
    final Uint8List bytes = await pdf.save();

    // 3. Prompt user to choose save location
    final saveLocation = await getSaveLocation(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'PDF Document', extensions: ['pdf']),
      ],
      suggestedName: 'export.pdf',
    );

    print("got save location: ${saveLocation?.path}");

    if (saveLocation == null) {
      // User cancelled dialog
      print("user cancelled dialog");
      return;
    }

    // 4. Save the file
    final file = XFile.fromData(
      bytes,
      name: saveLocation.path.split('/').last,
      mimeType: 'application/pdf',
    );

    await file.saveTo(saveLocation.path);

    print("✅ PDF Saved at: ${saveLocation.path}");
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
