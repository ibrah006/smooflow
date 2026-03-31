import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:macos_ui/macos_ui.dart';
import 'package:xml/xml.dart' as xml;
import 'package:package_info_plus/package_info_plus.dart';

Future<void> startUpdate() async {
  final scriptPath = '';

  try {
    final process = await Process.start(
      'bash',
      [scriptPath, '1.0.2'],
      mode: ProcessStartMode.detachedWithStdio, // safer for macOS GUI apps
      environment: {'PATH': '/usr/bin:/bin:/usr/sbin:/sbin'},
    );

    // capture output (optional)
    process.stdout.transform(utf8.decoder).listen(print);
    process.stderr.transform(utf8.decoder).listen(print);

    print('Process started with PID: ${process.pid}');
    exit(0);
  } catch (e) {
    print('Error starting script: $e');
  }
}

/// only meant for macos
Future<void> checkForUpdate(BuildContext context) async {
  if (!Platform.isMacOS) return null;

  const appcastUrl =
      'https://raw.githubusercontent.com/ibrah006/workflow-backend/main/public/updates/appcast.xml';

  try {
    // 1. Download XML
    final response = await http.get(Uri.parse(appcastUrl));
    if (response.statusCode != 200) {
      print('Failed to download appcast: ${response.statusCode}');
      return;
    }

    // 2. Parse XML
    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    // 3. Filter macOS items only
    final macItem = items.firstWhere(
      (item) =>
          item.getElement('enclosure')?.getAttribute('sparkle:os') == 'macos',
      orElse: () => throw Exception('No macOS updates found'),
    );

    final shortVersion = macItem.getElement('sparkle:shortVersionString')?.text;
    final url = macItem.getElement('enclosure')?.getAttribute('url');

    if (shortVersion == null || url == null) {
      print('Invalid appcast entry');
      return;
    }

    // 4. Get current app version
    // final packageInfo = await PackageVersion();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    print("current version: ${currentVersion}");

    // 5. Compare versions
    if (currentVersion != shortVersion) {
      print('Update available! Download at $url');

      showMacosSheet(
        context: context,
        builder:
            (_) => MacosTheme(
              data: MacosThemeData.light(),
              child: MacosSheet(
                child: Material(
                  child: Column(
                    children: [
                      FlutterLogo(size: 64),
                      Text(
                        'Alert Dialog with Primary Action',
                        style: MacosTheme.of(context).typography.headline,
                      ),
                      Text(
                        'This is an alert dialog with a primary action and no secondary action',
                        textAlign: TextAlign.center,
                        style: MacosTypography.of(context).headline,
                      ),
                      PushButton(
                        controlSize: ControlSize.large,
                        child: Text('Primary'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );
    } else {
      print('App is up to date');
    }
  } catch (e) {
    print('Error checking update: $e');
  }
}
