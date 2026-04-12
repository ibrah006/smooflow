import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:smooflow/components/logo.dart';
import 'package:smooflow/screens/desktop/components/macos_update_dialog_content.dart';
import 'package:video_player/video_player.dart';

enum _Phase { video, revealingNotes, notes }

class MacOSAfterUpdateDialogContent extends StatefulWidget {
  final String currentVersion;
  final List<ReleaseNote> releaseNotes;
  final VoidCallback onDismiss;

  /// Optional URL for a feature preview video.
  /// If null, the dialog skips straight to release notes.
  final String? featureVideoUrl;

  const MacOSAfterUpdateDialogContent({
    Key? key,
    this.currentVersion = '1.0.0',
    this.releaseNotes = const [],
    required this.onDismiss,
    this.featureVideoUrl,
  }) : super(key: key);

  @override
  State<MacOSAfterUpdateDialogContent> createState() =>
      _MacOSAfterUpdateDialogContentState();
}

class _MacOSAfterUpdateDialogContentState
    extends State<MacOSAfterUpdateDialogContent>
    with TickerProviderStateMixin {
  // ── entrance ──────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  // ── notes reveal ──────────────────────────────────────────
  late final AnimationController _notesCtrl;
  late final Animation<double> _notesFade;
  late final Animation<Offset> _notesSlide;

  // ── video ─────────────────────────────────────────────────
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  bool _videoEnded = false;

  _Phase _phase = _Phase.video;
  final ScrollController _scroll = ScrollController();

  // ── lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));

    _notesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _notesFade = CurvedAnimation(parent: _notesCtrl, curve: Curves.easeOut);
    _notesSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _notesCtrl, curve: Curves.easeOut));

    _entranceCtrl.forward();

    if (widget.featureVideoUrl != null) {
      _initVideo();
    } else {
      _phase = _Phase.notes;
      _notesCtrl.forward();
    }
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.featureVideoUrl!),
    );
    _videoCtrl = ctrl;
    await ctrl.initialize();
    if (!mounted) return;
    ctrl.addListener(_onVideoTick);
    setState(() => _videoReady = true);
    ctrl.play();
  }

  void _onVideoTick() {
    if (!mounted) return;
    final ctrl = _videoCtrl!;
    final finished =
        ctrl.value.duration != Duration.zero &&
        ctrl.value.position >= ctrl.value.duration;
    if (finished && !_videoEnded) {
      setState(() => _videoEnded = true);
      _triggerNotesReveal();
    }
  }

  void _triggerNotesReveal() {
    setState(() => _phase = _Phase.revealingNotes);
    _notesCtrl.forward().then((_) {
      if (mounted) setState(() => _phase = _Phase.notes);
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _replayVideo() {
    _notesCtrl.reverse();
    setState(() {
      _videoEnded = false;
      _phase = _Phase.video;
    });
    _videoCtrl?.seekTo(Duration.zero);
    _videoCtrl?.play();
  }

  void _skipVideo() {
    _videoCtrl?.pause();
    setState(() => _videoEnded = true);
    _triggerNotesReveal();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _notesCtrl.dispose();
    _videoCtrl?.removeListener(_onVideoTick);
    _videoCtrl?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MacosTheme(
      data: MacosThemeData.light(),
      child: MacosSheet(
        child: Material(
          borderRadius: BorderRadius.circular(10),
          child: FadeTransition(
            opacity: _entranceFade,
            child: SlideTransition(
              position: _entranceSlide,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 15,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scroll,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              _Header(
                                version: widget.currentVersion,
                                hasVideo: widget.featureVideoUrl != null,
                                phase: _phase,
                              ),
                              const SizedBox(height: 24),
                              if (widget.featureVideoUrl != null)
                                _VideoSection(
                                  controller: _videoCtrl,
                                  ready: _videoReady,
                                  ended: _videoEnded,
                                  onReplay: _replayVideo,
                                  onSkip: _skipVideo,
                                ),
                              if (widget.featureVideoUrl != null &&
                                  _phase != _Phase.video)
                                const SizedBox(height: 28),
                              if (widget.featureVideoUrl == null ||
                                  _phase != _Phase.video)
                                _NotesSection(
                                  notes: widget.releaseNotes,
                                  fadeAnimation: _notesFade,
                                  slideAnimation: _notesSlide,
                                  showDivider: widget.featureVideoUrl != null,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _Footer(
                      phase: _phase,
                      hasVideo: widget.featureVideoUrl != null,
                      onDismiss: widget.onDismiss,
                      onReplay: _replayVideo,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.version,
    required this.hasVideo,
    required this.phase,
  });

  final String version;
  final bool hasVideo;
  final _Phase phase;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        hasVideo && phase == _Phase.video
            ? "Watch what's new in Smooflow $version"
            : "See what's new in Smooflow $version";

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Logo(size: 58),
        ),
        Text(
          'Updated to $version',
          style: MacosTheme.of(context).typography.largeTitle.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            subtitle,
            key: ValueKey(subtitle),
            style: MacosTheme.of(context).typography.body.copyWith(
              color: const Color(0xFFAAAAAA),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ── Video section ─────────────────────────────────────────────

class _VideoSection extends StatelessWidget {
  const _VideoSection({
    required this.controller,
    required this.ready,
    required this.ended,
    required this.onReplay,
    required this.onSkip,
  });

  final VideoPlayerController? controller;
  final bool ready;
  final bool ended;
  final VoidCallback onReplay;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── player ──
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                // video or loader
                if (ready && controller != null)
                  VideoPlayer(controller!)
                else
                  Container(
                    color: const Color(0xFFF2F2F2),
                    child: const Center(
                      child: CupertinoActivityIndicator(radius: 14),
                    ),
                  ),

                // ended overlay
                if (ended)
                  AnimatedOpacity(
                    opacity: ended ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: GestureDetector(
                          onTap: onReplay,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.replay_rounded,
                                  color: Color(0xFF007AFF),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Replay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── progress bar ──
        if (ready && controller != null && !ended)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: VideoProgressIndicator(
              controller!,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF007AFF),
                bufferedColor: Color(0xFFDDDDDD),
                backgroundColor: Color(0xFFEEEEEE),
              ),
            ),
          ),

        // ── skip link ──
        if (!ended)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GestureDetector(
              onTap: onSkip,
              child: const Text(
                'Skip to release notes',
                style: TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFBBBBBB),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Notes section ─────────────────────────────────────────────

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.notes,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.showDivider,
  });

  final List<ReleaseNote> notes;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "What's new",
                        style: MacosTheme.of(
                          context,
                        ).typography.subheadline.copyWith(
                          color: const Color(0xFFAAAAAA),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                  ],
                ),
              ),
            ...List.generate(notes.length, (i) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 380 + i * 90),
                curve: Curves.easeOut,
                builder:
                    (context, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - v)),
                        child: child,
                      ),
                    ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: i == notes.length - 1 ? 8 : 20,
                  ),
                  child: _NoteRow(note: notes[i]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});
  final ReleaseNote note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 2),
          child: Icon(note.icon, color: const Color(0xFF007AFF), size: 20),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: MacosTheme.of(context).typography.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note.description,
                style: MacosTheme.of(context).typography.body.copyWith(
                  color: const Color(0xFFAAAAAA),
                  fontSize: 13,
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

// ── Footer ────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.phase,
    required this.hasVideo,
    required this.onDismiss,
    required this.onReplay,
  });

  final _Phase phase;
  final bool hasVideo;
  final VoidCallback onDismiss;
  final VoidCallback onReplay;

  bool get _notesVisible => phase != _Phase.video;
  bool get _showReplay => hasVideo && _notesVisible;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: Row(
          key: ValueKey(_showReplay),
          children: [
            if (_showReplay) ...[
              Expanded(
                child: PushButton(
                  onPressed: onReplay,
                  controlSize: ControlSize.large,
                  secondary: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.replay_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        'Replay',
                        style: MacosTheme.of(context).typography.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: PushButton(
                onPressed: onDismiss,
                controlSize: ControlSize.large,
                child: Text(
                  _notesVisible ? 'Get Started' : 'Skip',
                  style: MacosTheme.of(context).typography.body.copyWith(
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
    );
  }
}
