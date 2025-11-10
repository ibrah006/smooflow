import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;

Future<void> exportToJpg(BuildContext context, GlobalKey barcodeKey) async {
  /// Converts transparent PNG bytes into JPEG with white background
  Future<Uint8List> _convertPngToJpgWithWhiteBg(Uint8List pngBytes) async {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Fill background white
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      paint,
    );

    // Draw the original image on top
    canvas.drawImage(image, Offset.zero, Paint());

    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(image.width, image.height);
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  Future<void> saveImageToGallery(Uint8List imageBytes) async {
    // Check and request storage permission
    var status = await Permission.storage.request();

    if (Platform.isAndroid) {
      status = await Permission.accessMediaLocation.request();
    }

    // For Android 13+ (API 33+) you might request Permission.photos or Permission.mediaLibrary
    // The 'storage' permission handler typically abstracts this for you.
    if (status.isGranted) {
      final result = await ImageGallerySaverPlus.saveImage(
        imageBytes,
        name: "barcode_${DateTime.now().millisecondsSinceEpoch}",
      );
      print("Image saved: $result");

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Barcode exported to gallery successfully")),
      );
    } else {
      print("Permission denied");
      // Optionally, show a dialogue to guide the user to app settings
      openAppSettings();
    }
  }

  final status = await Permission.storage.request();

  if (status.isGranted) {
    // Camera permission granted, proceed with camera functionality
  } else if (status.isDenied) {
    // Camera permission denied
  } else if (status.isRestricted) {
    // Camera permission permanently denied, guide user to app settings
    openAppSettings(); // Opens the app's settings page
  }

  try {
    // Get RenderRepaintBoundary
    RenderRepaintBoundary boundary =
        barcodeKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    // Convert to Image
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);

    // Convert to byte data (PNG first)
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Convert to JPEG with white background
    Uint8List jpgBytes = await _convertPngToJpgWithWhiteBg(pngBytes);

    // (Optional) Save to gallery
    await saveImageToGallery(jpgBytes);
  } catch (e) {
    print('Error exporting barcode: $e');
  }
}
