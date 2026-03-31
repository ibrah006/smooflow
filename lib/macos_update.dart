import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:macos_ui/macos_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smooflow/screens/desktop/components/macos_update_dialog_content.dart';
import 'package:xml/xml.dart' as xml;
import 'package:package_info_plus/package_info_plus.dart';

Future<void> startUpdate({required String updateDestinationDir}) async {
  // 1. Load script from assets
  final scriptContent = await rootBundle.loadString(
    'assets/scripts/install_update.sh',
  );

  // 2. Write to temp file
  final tempDir = await getTemporaryDirectory();
  final scriptFile = File('${tempDir.path}/install_update.sh');

  await scriptFile.writeAsString(scriptContent);

  // 3. Make executable (macOS/Linux)
  await Process.run('chmod', ['+x', scriptFile.path]);

  try {
    final process = await Process.start(
      'bash',
      [
        scriptFile.path, '1.0.3',
        // Update downloaded directory path
        updateDestinationDir,
      ],
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
    if (_isNewerVersion(currentVersion, shortVersion)) {
      print('Update available! Download at $url');

      showMacosSheet(
        context: context,
        builder:
            (_) => UpdateVersionDialogContent(
              currentVersion: currentVersion,
              newVersion: shortVersion,
              url: url,
              onDismiss: () {
                Navigator.of(context).pop();
              },
              releaseNotes: [
                ReleaseNote(
                  icon: Icons.bug_report_outlined,
                  title: "Minor bug fixes",
                  description:
                      "Fixed label 'Due date' -> 'Date' in task details.",
                ),
                ReleaseNote(
                  icon: Icons.list_outlined,
                  title: "Update Task Print Specs",
                  description: "You can now update task print specifications.",
                ),
                ReleaseNote(
                  icon: Icons.delete_sweep_outlined,
                  title: "Delete Task",
                  description: "Tasks can be deleted when needed to be.",
                ),
              ],
            ),
      );
    } else {
      print('App is up to date');
    }
  } catch (e) {
    print('Error checking update: $e');
  }
}

Future<void> downloadFile({
  required String url,
  required String savePath,
  required Function(double progress) onProgress,
}) async {
  final request = http.Request('GET', Uri.parse(url));
  final response = await http.Client().send(request);

  final totalBytes = response.contentLength ?? 0;
  int receivedBytes = 0;

  final file = File(savePath);
  final sink = file.openWrite();

  await for (final chunk in response.stream) {
    receivedBytes += chunk.length;
    sink.add(chunk);

    if (totalBytes != 0) {
      final progress = receivedBytes / totalBytes;
      onProgress(progress); // 👈 update UI
    }
  }

  await sink.close();
}

bool _isNewerVersion(String currentVersion, String latestVersion) {
  final currentParts = currentVersion.split('.').map(int.parse).toList();
  final latestParts = latestVersion.split('.').map(int.parse).toList();

  // Ensure both have 3 parts (x.x.x)
  while (currentParts.length < 3) currentParts.add(0);
  while (latestParts.length < 3) latestParts.add(0);

  for (int i = 0; i < 3; i++) {
    if (latestParts[i] > currentParts[i]) return true;
    if (latestParts[i] < currentParts[i]) return false;
  }

  return false; // equal
}
