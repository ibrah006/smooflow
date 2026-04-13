import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smooflow/components/logo.dart';
import 'package:smooflow/macos_update.dart';
import 'package:smooflow/screens/desktop/components/notification_toast.dart';

class ReleaseNote {
  final IconData? icon;
  final String title;
  final String description;

  ReleaseNote({this.icon, required this.title, required this.description});
}

class UpdateVersionDialogContent extends StatefulWidget {
  final String currentVersion;
  final String newVersion;
  final List<ReleaseNote> releaseNotes;
  final VoidCallback onDismiss;
  final String url;

  const UpdateVersionDialogContent({
    Key? key,
    this.currentVersion = '1.0.0',
    this.newVersion = '1.1.0',
    this.releaseNotes = const [],
    required this.onDismiss,
    required this.url,
  }) : super(key: key);

  @override
  State<UpdateVersionDialogContent> createState() =>
      _UpdateVersionDialogContentState();
}

class _UpdateVersionDialogContentState extends State<UpdateVersionDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MacosTheme(
      data: MacosThemeData.light(),
      child: MacosSheet(
        child: Material(
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 15),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Logo with animation
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Logo(size: 70),
                              ),
                            ),
                          ),
                          // Version Update Title
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'What\'s New in Smooflow ${widget.newVersion}',
                                  style: MacosTheme.of(
                                    context,
                                  ).typography.largeTitle.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          // Version info subtitle
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 32),
                                child: Text(
                                  'Update from ${widget.currentVersion} to ${widget.newVersion}',
                                  style: MacosTheme.of(
                                    context,
                                  ).typography.body.copyWith(
                                    color: const Color(0xFFAAAAAA),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          // Release Notes
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Release Notes",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          ...List.generate(widget.releaseNotes.length, (index) {
                            final note = widget.releaseNotes[index];
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index == widget.releaseNotes.length - 1
                                            ? 40
                                            : 20,
                                  ),
                                  child: _buildReleaseNoteRow(
                                    title: note.title,
                                    description: note.description,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                // Action Buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        children: [
                          // Dismiss Button
                          Expanded(
                            child: PushButton(
                              onPressed: widget.onDismiss,
                              controlSize: ControlSize.large,
                              secondary: true,
                              child: Text(
                                'Not Now',
                                style: MacosTheme.of(
                                  context,
                                ).typography.body.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Download Update Button
                          Expanded(
                            child: PushButton(
                              onPressed: showDownloadDialog,
                              controlSize: ControlSize.large,
                              child: Text(
                                'Download Update',
                                style: MacosTheme.of(
                                  context,
                                ).typography.body.copyWith(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReleaseNoteRow({
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding(
        //   padding: const EdgeInsets.only(right: 16, top: 2),
        //   child: Icon(icon, color: const Color(0xFF007AFF), size: 20),
        // ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: MacosTheme.of(context).typography.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: MacosTheme.of(context).typography.body.copyWith(
                  color: const Color(0xFFAAAAAA),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showDownloadDialog() async {
    final errorMessage =
        (await showMacosAlertDialog(
              context: context,
              builder: (_) {
                return _DownloadUpdateDialogContent(url: widget.url);
              },
            ))
            as String?;

    if (errorMessage != null) {
      AppToast.show(
        message: errorMessage,
        icon: Icons.info_outline,
        color: Colors.amber,
      );
    }
  }
}

class _DownloadUpdateDialogContent extends StatefulWidget {
  final String url;
  const _DownloadUpdateDialogContent({super.key, required this.url});

  @override
  State<_DownloadUpdateDialogContent> createState() =>
      _DownloadUpdateDialogContentState();
}

class _DownloadUpdateDialogContentState
    extends State<_DownloadUpdateDialogContent> {
  double downloadProgress = 0.0;

  bool downloadComplete = false;

  String? extractedDirectoryPath;

  Future<void> unzipFile(String zipPath, String destinationPath) async {
    try {
      final process = await Process.start('/usr/bin/unzip', [
        '-o', // overwrite existing files
        zipPath,
        '-d',
        destinationPath,
      ]);

      process.stdout.transform(utf8.decoder).listen(print);
      process.stderr.transform(utf8.decoder).listen(print);

      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        throw Exception('Unzip failed with code $exitCode');
      }

      print('Unzipped successfully to $destinationPath');
    } catch (e) {
      print('Unzip error: $e');
    }
  }

  Future<void> startDownload() async {
    print("about to get temp directory");

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/smooflow-macos-release-update.zip';

    print("about to start download");

    await downloadFile(
      url: widget.url,
      savePath: filePath,
      onProgress: (progress) {
        setState(() {
          downloadProgress = progress;
        });
      },
    );

    final extractPath = '${tempDir.path}/update_extracted';

    // Create folder if not exists
    await Directory(extractPath).create(recursive: true);

    print('Download complete: $filePath');

    // unzip update
    await unzipFile(filePath, extractPath);

    setState(() {
      downloadComplete = true;
      extractedDirectoryPath = extractPath;
    });
  }

  void onCancel() async {
    Navigator.of(context).pop("Update cancelled by user");
  }

  // replaces with latest downloaded update
  void onRelaunch() async {
    try {
      await startUpdate(updateDestinationDir: extractedDirectoryPath!);
    } catch (e) {
      Navigator.of(context).pop("Error installing update, error code: 1003");
    }
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 1)).then((value) async {
      await startDownload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MacosTheme(
      data: MacosThemeData.light(),
      child: MacosAlertDialog(
        appIcon: Logo(size: 40),
        title: Text(
          downloadComplete ? 'Update Complete' : 'Downloading Update',
          style: MacosTheme.of(context).typography.headline,
        ),
        message: Column(
          spacing: 15,
          children: [
            Text(
              downloadComplete
                  ? 'Please click relaunch to apply new update and launch Smooflow.'
                  : 'Please do not exit the app while the update is being downloaded.',
              textAlign: TextAlign.center,
              style: MacosTypography.of(
                context,
              ).body.copyWith(fontWeight: FontWeight.w500),
            ),
            SizedBox(
              width: double.infinity,
              child: ProgressBar(
                height: 7,
                value: downloadProgress * 100, // 0.0 → 1.0
              ),
            ),
            Text(
              '${(downloadProgress * 100).toStringAsFixed(0)}%',
              style: MacosTheme.of(context).typography.body,
            ),
          ],
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          child: Text(downloadComplete ? 'Relaunch app' : 'Cancel'),
          // Secondary button if download is not complete 'Cancel'
          secondary: !downloadComplete,
          onPressed: downloadComplete ? onRelaunch : onCancel,
        ),
      ),
    );
  }
}
