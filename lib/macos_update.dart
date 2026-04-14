import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:macos_ui/macos_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooflow/enums/shared_storage_options.dart';
import 'package:smooflow/screens/desktop/components/macos_after_update_dialog_content.dart';
import 'package:smooflow/screens/desktop/components/macos_update_dialog_content.dart';
import 'package:xml/xml.dart' as xml;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:html/parser.dart' as html;

Future<void> startUpdate({
  // required String newVersion,
  required String updateDestinationDir,
}) async {
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
      mode: ProcessStartMode.detached, // safer for macOS GUI apps
      environment: {'PATH': '/usr/bin:/bin:/usr/sbin:/sbin'},
    );

    // capture output (optional)
    // process.stdout.transform(utf8.decoder).listen(print);
    // process.stderr.transform(utf8.decoder).listen(print);

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
      print('Update available!');

      final description = macItem.getElement('description')?.innerText;

      final doc = html.parse(description);

      final items = doc.querySelectorAll('li');

      final releaseNotes =
          items.map((li) {
            final title = li.querySelector('b')?.text ?? '';
            final subtitle = li.text.replaceFirst(title, '').trim();

            return {'title': title, 'subtitle': subtitle};
          }).toList();

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
              // Release Notes
              releaseNotes:
                  releaseNotes.map((note) {
                    return ReleaseNote(
                      title: note['title'] ?? "",
                      description: note['subtitle'] ?? "",
                    );
                  }).toList(),
            ),
      );
    } else {
      print('App is up to date');

      SharedPreferences prefs = await SharedPreferences.getInstance();

      final lastVersionReleaseNotesShown = prefs.getString(
        SharedStorageOptions.lastVersionReleaseNotesShown.name,
      );

      print(
        "lastVersionReleaseNotesShown: ${lastVersionReleaseNotesShown}, currentVersion: ${currentVersion}",
      );

      if (currentVersion != "1.0.9" &&
              (lastVersionReleaseNotesShown != null &&
                  _isNewerVersion(
                    lastVersionReleaseNotesShown,
                    currentVersion,
                  )) ||
          lastVersionReleaseNotesShown == null) {
        await prefs.setString(
          SharedStorageOptions.lastVersionReleaseNotesShown.name,
          currentVersion,
        );

        _showAfterUpdateReleaseNotes(context, currentVersion);
      }
    }
  } catch (e) {
    print('Error checking update: $e');
  }
}

_showAfterUpdateReleaseNotes(context, String currentVersion) {
  showMacosSheet(
    context: context,
    builder:
        (_) => MacOSAfterUpdateDialogContent(
          currentVersion: currentVersion,
          featureVideoUrl:
              'https://raw.githubusercontent.com/ibrah006/smooflow/main/screenshots/feature%20demos/messaging.mp4',
          onDismiss: () {
            Navigator.of(context).pop();
          },
          releaseNotes: [
            ReleaseNote(
              icon: Icons.message_outlined,
              title: "Messaging (New)",
              description:
                  "Discussion threads for tasks! You can now comment and have threaded discussions on each task.",
            ),
            ReleaseNote(
              icon: Icons.bolt_outlined,
              title: "Improved Readability in Task Details",
              description:
                  "Updated the design of task details to make it easier to read and navigate, especially for tasks with a lot of information.",
            ),
            ReleaseNote(
              icon: Icons.notification_important_sharp,
              title: "Bug Fixes",
              description:
                  "Fixed in-app notifications spamming when task updated",
            ),
          ],
        ),
  );
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
