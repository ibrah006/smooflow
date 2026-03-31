import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smooflow/components/logo.dart';
import 'package:smooflow/macos_update.dart';

class ReleaseNote {
  final IconData icon;
  final String title;
  final String description;

  ReleaseNote({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class UpdateVersionDialogContent extends StatefulWidget {
  final String currentVersion;
  final String newVersion;
  final List<ReleaseNote> releaseNotes;
  final VoidCallback onDownloadUpdate;
  final VoidCallback onDismiss;
  final String url;

  const UpdateVersionDialogContent({
    Key? key,
    this.currentVersion = '1.0.0',
    this.newVersion = '1.1.0',
    this.releaseNotes = const [],
    required this.onDownloadUpdate,
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

  double downloadProgress = 0.0;
  bool isDownloading = false;

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

    Future.delayed(Duration(seconds: 3)).then((value) async {
      await startDownload();
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> startDownload() async {
    setState(() {
      isDownloading = true;
    });

    print("about to get temp directory");

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/update.zip';

    print("about to start download");

    await downloadFile(
      url: widget.url,
      savePath: filePath,
      onProgress: (progress) {
        print('Progress: ${(progress * 100).toStringAsFixed(0)}%');
        setState(() {
          downloadProgress = progress;
        });
      },
    );

    print('Download complete: $filePath');

    setState(() {
      isDownloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MacosTheme(
      data: MacosThemeData.light(),
      child: MacosSheet(
        child: Material(
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
                          if (isDownloading) ...[
                            ProgressBar(
                              value: downloadProgress * 100, // 0.0 → 1.0
                            ),
                            Text(
                              '${(downloadProgress * 100).toStringAsFixed(0)}%',
                              style: MacosTheme.of(context).typography.caption1,
                            ),
                          ],
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
                                    icon: note.icon,
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
                              onPressed: widget.onDownloadUpdate,
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
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 2),
          child: Icon(icon, color: const Color(0xFF007AFF), size: 20),
        ),
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
}
