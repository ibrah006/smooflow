// ─────────────────────────────────────────────────────────────────────────────
// DESKTOP TOAST — Global, no wrapper widget required
//
// Inserts toasts directly into the Navigator overlay via a GlobalKey.
// All state lives in the singleton _ToastManager.
//
// Setup (once, in your MaterialApp):
//   final navigatorKey = GlobalKey<NavigatorState>();
//   MaterialApp(navigatorKey: navigatorKey, ...)
//
// Show a toast from anywhere — no BuildContext needed:
//   AppToast.show(
//     message: 'Task updated',
//     icon:    Icons.edit_outlined,
//     color:   Color(0xFF2563EB),
//   );
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────────────────────────────────────
abstract class AppToast {
  /// Call this once after your MaterialApp is built, passing your navigatorKey.
  static void init(GlobalKey<NavigatorState> key) {
    _ToastManager.instance.init(key);
  }

  static void show({
    required String message,
    required IconData icon,
    required Color color,
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    _ToastManager.instance.show(
      message: message,
      icon: icon,
      color: color,
      subtitle: subtitle,
      duration: duration,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOAST DATA
// ─────────────────────────────────────────────────────────────────────────────
class _ToastData {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Duration duration;
  final String id;

  _ToastData({
    required this.message,
    required this.icon,
    required this.color,
    this.subtitle,
    this.duration = const Duration(seconds: 3),
  }) : id = UniqueKey().toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// TOAST MANAGER — singleton, owns the single OverlayEntry
//
// A single OverlayEntry hosts the entire deck widget. The deck rebuilds via
// a ValueNotifier whenever the toast list changes — no setState, no wrapper.
// ─────────────────────────────────────────────────────────────────────────────
class _ToastManager {
  _ToastManager._();
  static final instance = _ToastManager._();

  GlobalKey<NavigatorState>? _navKey;
  OverlayEntry? _entry;

  final ValueNotifier<List<_ToastData>> _toasts =
      ValueNotifier<List<_ToastData>>([]);

  static const int _maxVisible = 4;

  void init(GlobalKey<NavigatorState> key) {
    _navKey = key;
  }

  void show({
    required String message,
    required IconData icon,
    required Color color,
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    final toast = _ToastData(
      message: message,
      icon: icon,
      color: color,
      subtitle: subtitle,
      duration: duration,
    );

    final current = List<_ToastData>.from(_toasts.value);
    current.insert(0, toast);
    if (current.length > _maxVisible) {
      current.removeRange(_maxVisible, current.length);
    }
    _toasts.value = current;

    _ensureOverlay();
  }

  void _dismiss(String id) {
    final current = List<_ToastData>.from(_toasts.value)
      ..removeWhere((t) => t.id == id);
    _toasts.value = current;

    // Remove the overlay entry once the deck is empty
    if (current.isEmpty) {
      _entry?.remove();
      _entry = null;
    }
  }

  void _ensureOverlay() {
    if (_entry != null) return; // already inserted

    final overlay = _navKey?.currentState?.overlay;
    assert(
      overlay != null,
      'AppToast: navigatorKey has no overlay. '
      'Did you call AppToast.init(navigatorKey) and pass the key to MaterialApp?',
    );
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (_) => _ToastDeckOverlay(toasts: _toasts, onDismiss: _dismiss),
    );

    overlay.insert(_entry!);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY WIDGET — reacts to ValueNotifier, no setState needed
// ─────────────────────────────────────────────────────────────────────────────
class _ToastDeckOverlay extends StatelessWidget {
  final ValueNotifier<List<_ToastData>> toasts;
  final ValueChanged<String> onDismiss;

  const _ToastDeckOverlay({required this.toasts, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, right: 20),
        child: ValueListenableBuilder<List<_ToastData>>(
          valueListenable: toasts,
          builder:
              (_, list, __) => _ToastDeck(toasts: list, onDismiss: onDismiss),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DECK VISUAL CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const double _kCardW = 320.0;
const double _kCardH = 72.0;

const _kOpacities = [1.0, 0.55, 0.28, 0.12];
const _kScales = [1.0, 0.97, 0.94, 0.91];
const _kOffsets = [0.0, 6.0, 10.0, 13.0];

// ─────────────────────────────────────────────────────────────────────────────
// TOAST DECK
// ─────────────────────────────────────────────────────────────────────────────
class _ToastDeck extends StatelessWidget {
  final List<_ToastData> toasts;
  final ValueChanged<String> onDismiss;

  const _ToastDeck({required this.toasts, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (toasts.isEmpty) return const SizedBox.shrink();

    final int count = toasts.length.clamp(0, 4);
    final double deckHeight = _kCardH + _kOffsets[count - 1] + 20;

    return SizedBox(
      width: _kCardW,
      height: deckHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          for (int i = count - 1; i >= 0; i--)
            _AnimatedDeckCard(
              key: ValueKey(toasts[i].id),
              data: toasts[i],
              depth: i,
              onDismiss: () => onDismiss(toasts[i].id),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED DECK CARD
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedDeckCard extends StatefulWidget {
  final _ToastData data;
  final int depth;
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
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _entryFade;
  late final AnimationController _progressCtrl;

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: widget.data.duration,
      value: 1.0,
    );

    if (widget.depth == 0) _startCountdown();
  }

  @override
  void didUpdateWidget(_AnimatedDeckCard old) {
    super.didUpdateWidget(old);
    if (widget.depth == 0 && old.depth != 0) _startCountdown();
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
    final int d = widget.depth.clamp(0, 3);
    final double opacity = _kOpacities[d];
    final double scale = _kScales[d];
    final double yOffset = _kOffsets[d];

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      top: yOffset,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: opacity,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 280),
          scale: scale,
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _entryFade,
              child: _ToastCard(
                data: widget.data,
                isTop: d == 0,
                progressCtrl: _progressCtrl,
                onDismiss: _startDismiss,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOAST CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ToastCard extends StatelessWidget {
  final _ToastData data;
  final bool isTop;
  final AnimationController progressCtrl;
  final VoidCallback onDismiss;

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: data.color),

              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 10, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: data.color.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(data.icon, size: 15, color: data.color),
                          ),
                          const SizedBox(width: 11),

                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    data.message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                      height: 1.2,
                                    ),
                                  ),
                                  if (data.subtitle != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      data.subtitle!,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          if (isTop)
                            GestureDetector(
                              onTap: onDismiss,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
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

                    if (isTop)
                      AnimatedBuilder(
                        animation: progressCtrl,
                        builder:
                            (_, __) => SizedBox(
                              height: 2,
                              child: LinearProgressIndicator(
                                value: progressCtrl.value,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation(
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
