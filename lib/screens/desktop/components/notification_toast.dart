// ─────────────────────────────────────────────────────────────────────────────
// DESKTOP TOAST NOTIFICATION SYSTEM — Stacked Deck
//
// Newest toast sits on top. Older toasts peek below it with decreasing
// opacity, slight vertical offset, and a subtle scale-down — like a deck
// of cards. Max 4 toasts visible in the stack. 5th+ are dropped.
//
// Usage:
//   1. Wrap your app with ToastOverlay:
//        ToastOverlay(child: MaterialApp(...))
//
//   2. Show a toast from anywhere:
//        ToastQueue.of(context).show(
//          message: 'Task status changed',
//          icon:    Icons.swap_horiz,
//          color:   Color(0xFFF59E0B),
//        );
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOAST DATA
// ─────────────────────────────────────────────────────────────────────────────
class ToastData {
  final String   message;
  final String?  subtitle;
  final IconData icon;
  final Color    color;
  final Duration duration;
  final String   id;

  ToastData({
    required this.message,
    required this.icon,
    required this.color,
    this.subtitle,
    this.duration = const Duration(seconds: 3),
  }) : id = UniqueKey().toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// TOAST QUEUE — inherited widget
// ─────────────────────────────────────────────────────────────────────────────
class ToastQueue extends InheritedWidget {
  final _ToastOverlayState _state;

  const ToastQueue({
    super.key,
    required _ToastOverlayState state,
    required super.child,
  }) : _state = state;

  static _ToastOverlayState of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<ToastQueue>();
    assert(result != null, 'No ToastOverlay found in widget tree.');
    return result!._state;
  }

  @override
  bool updateShouldNotify(ToastQueue old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOAST OVERLAY
// ─────────────────────────────────────────────────────────────────────────────
class ToastOverlay extends StatefulWidget {
  final Widget child;
  const ToastOverlay({super.key, required this.child});

  @override
  State<ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<ToastOverlay> {
  // Index 0 = newest (top of deck), higher index = older (lower in deck)
  final List<ToastData> _toasts = [];

  static const int _maxVisible = 4;

  void show({
    required String   message,
    required IconData icon,
    required Color    color,
    String?           subtitle,
    Duration          duration = const Duration(seconds: 3),
  }) {
    setState(() {
      _toasts.insert(0, ToastData(
        message:  message,
        icon:     icon,
        color:    color,
        subtitle: subtitle,
        duration: duration,
      ));
      // Silently drop anything beyond max — they'd be invisible anyway
      if (_toasts.length > _maxVisible) {
        _toasts.removeRange(_maxVisible, _toasts.length);
      }
    });
  }

  void _dismiss(String id) {
    setState(() => _toasts.removeWhere((t) => t.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return ToastQueue(
      state: this,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top:    0,
            right:  0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: _toasts.isEmpty,
              child: Padding(
                padding: const EdgeInsets.only(top: 20, right: 20),
                child: _ToastDeck(
                  toasts:    _toasts,
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DECK VISUAL CONSTANTS
//
//  depth 0 — top card:    full size, full opacity
//  depth 1 — one below:   slight peek, reduced opacity, tiny scale-down
//  depth 2 — two below:   more faded
//  depth 3 — three below: barely visible edge
// ─────────────────────────────────────────────────────────────────────────────
const double _kCardW = 320.0;
const double _kCardH = 72.0;   // approx — used for deck container sizing

// How many px each card is offset downward from the card above it
const _kOpacities = [1.0,  0.55, 0.28, 0.12];
const _kScales    = [1.0,  0.97, 0.94, 0.91];
const _kOffsets   = [0.0,  6.0,  10.0, 13.0]; // cumulative y-offset from top

// ─────────────────────────────────────────────────────────────────────────────
// TOAST DECK — positions cards as a layered stack
// ─────────────────────────────────────────────────────────────────────────────
class _ToastDeck extends StatelessWidget {
  final List<ToastData>      toasts;
  final ValueChanged<String> onDismiss;

  const _ToastDeck({required this.toasts, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (toasts.isEmpty) return const SizedBox.shrink();

    final int    count      = toasts.length.clamp(0, 4);
    final double deckHeight = _kCardH + _kOffsets[count - 1] + 20; // shadow room

    return SizedBox(
      width:  _kCardW,
      height: deckHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment:    Alignment.topCenter,
        // Render oldest first so newer cards paint on top
        children: [
          for (int i = count - 1; i >= 0; i--)
            _AnimatedDeckCard(
              key:       ValueKey(toasts[i].id),
              data:      toasts[i],
              depth:     i,
              onDismiss: () => onDismiss(toasts[i].id),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED DECK CARD
//
// Handles its own:
//   • Slide-in from right on first render
//   • Animated depth transitions (position, opacity, scale)
//   • Countdown timer + auto-dismiss (only when depth == 0)
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedDeckCard extends StatefulWidget {
  final ToastData    data;
  final int          depth;    // 0 = top/newest
  final VoidCallback onDismiss;

  const _AnimatedDeckCard({
    super.key,
    required this.data,
    required this.depth,
    required this.onDismiss,
  });

  @override
  State<_AnimatedDeckCard> createState() => _AnimatedDeckCardState();
}

class _AnimatedDeckCardState extends State<_AnimatedDeckCard>
    with SingleTickerProviderStateMixin {

  // Entry slide
  late final AnimationController _entryCtrl;
  late final Animation<Offset>   _slideAnim;
  late final Animation<double>   _entryFade;

  // Progress countdown
  late final AnimationController _progressCtrl;

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.3, 0),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();

    _progressCtrl = AnimationController(
      vsync:    this,
      duration: widget.data.duration,
      value:    1.0,
    );

    if (widget.depth == 0) _startCountdown();
  }

  @override
  void didUpdateWidget(_AnimatedDeckCard old) {
    super.didUpdateWidget(old);
    // Promoted to top — begin countdown
    if (widget.depth == 0 && old.depth != 0) _startCountdown();
    // Demoted from top — pause countdown
    if (widget.depth != 0 && old.depth == 0) _progressCtrl.stop();
  }

  void _startCountdown() {
    _progressCtrl.animateTo(0.0).then((_) => _startDismiss());
  }

  Future<void> _startDismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _progressCtrl.stop();
    _entryCtrl.duration = const Duration(milliseconds: 220);
    await _entryCtrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int    d       = widget.depth.clamp(0, 3);
    final double opacity = _kOpacities[d];
    final double scale   = _kScales[d];
    final double yOffset = _kOffsets[d];

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve:    Curves.easeOutCubic,
      top:      yOffset,
      left:     0,
      right:    0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity:  opacity,
        child: AnimatedScale(
          duration:  const Duration(milliseconds: 280),
          scale:     scale,
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _entryFade,
              child: _ToastCard(
                data:         widget.data,
                isTop:        d == 0,
                progressCtrl: _progressCtrl,
                onDismiss:    _startDismiss,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOAST CARD — pure visual, no state
// ─────────────────────────────────────────────────────────────────────────────
class _ToastCard extends StatelessWidget {
  final ToastData           data;
  final bool                isTop;
  final AnimationController progressCtrl;
  final VoidCallback        onDismiss;

  const _ToastCard({
    required this.data,
    required this.isTop,
    required this.progressCtrl,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kCardW,
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color:      const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 16,
            offset:     const Offset(0, 4),
          ),
          BoxShadow(
            color:      const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 4,
            offset:     const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Left accent bar
              Container(width: 3, color: data.color),

              // Body
              Expanded(
                child: Column(
                  mainAxisSize:       MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 10, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Icon in tinted circle
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: data.color.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(data.icon, size: 15, color: data.color),
                          ),
                          const SizedBox(width: 11),

                          // Message + subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  data.message,
                                  style: const TextStyle(
                                    fontSize:   13,
                                    fontWeight: FontWeight.w600,
                                    color:      Color(0xFF1E293B),
                                    height:     1.2,
                                  ),
                                ),
                                if (data.subtitle != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    data.subtitle!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color:    Color(0xFF64748B),
                                      height:   1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // × dismiss — only on top card
                          if (isTop)
                            GestureDetector(
                              onTap: onDismiss,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size:  14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 18),

                        ],
                      ),
                    ),

                    // Progress bar — only on top card
                    if (isTop)
                      AnimatedBuilder(
                        animation: progressCtrl,
                        builder: (_, __) => SizedBox(
                          height: 2,
                          child: LinearProgressIndicator(
                            value:           progressCtrl.value,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor:      AlwaysStoppedAnimation(
                              data.color.withOpacity(0.55),
                            ),
                            minHeight: 2,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 2),

                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}