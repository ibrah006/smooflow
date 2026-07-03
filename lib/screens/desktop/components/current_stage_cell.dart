// ─────────────────────────────────────────────────────────────────────────────
// CURRENT STAGE — Interactive hover-to-advance pill
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/screens/desktop/components/stage_pill.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

class _T {
  static const blue = Color(0xFF2563EB);
}

// ─────────────────────────────────────────────────────────────────────────────
// CURRENT STAGE — Hover reveals a floating "advance" affordance via Overlay
// (pill itself never resizes, so it can't overflow its GridView cell)
// ─────────────────────────────────────────────────────────────────────────────
class CurrentStageCell extends StatefulWidget {
  final dynamic stageInfo; // return type of stageInfo()
  final TaskStatus? next;
  final bool ableToReinitialize;
  final bool canAdvance;
  final bool isProgressing;
  final VoidCallback onAdvance;

  const CurrentStageCell({
    required this.stageInfo,
    required this.next,
    required this.ableToReinitialize,
    required this.canAdvance,
    required this.isProgressing,
    required this.onAdvance,
  });

  @override
  State<CurrentStageCell> createState() => _CurrentStageCellState();
}

class _CurrentStageCellState extends State<CurrentStageCell> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool _pillHovered = false;
  bool _popoverHovered = false;
  Timer? _hideTimer;

  bool get _interactive => widget.canAdvance && !widget.isProgressing;

  String? get _nextLabel =>
      widget.ableToReinitialize
          ? 'Re-initialize'
          : widget.next != null
          ? stageInfo(widget.next!).label
          : null;

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 120), () {
      if (!_pillHovered && !_popoverHovered) _removeOverlay();
    });
  }

  void _showOverlay() {
    if (_entry != null || !_interactive || _nextLabel == null) return;

    _entry = OverlayEntry(
      builder:
          (context) => Positioned(
            width:
                220, // generous fixed width; floats free of any parent constraint
            child: CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Align(
                alignment: Alignment.topLeft,
                child: MouseRegion(
                  onEnter: (_) {
                    _popoverHovered = true;
                    _hideTimer?.cancel();
                  },
                  onExit: (_) {
                    _popoverHovered = false;
                    _scheduleHide();
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        widget.onAdvance();
                        _removeOverlay();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _T.blue,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: _T.blue.withOpacity(0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isProgressing)
                              const SizedBox(
                                width: 11,
                                height: 11,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              'Move to "${_nextLabel!}"',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_entry!);
  }

  void _removeOverlay() {
    _hideTimer?.cancel();
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final si = widget.stageInfo;
    final showHover = _interactive && _pillHovered;

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        cursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) {
          setState(() => _pillHovered = true);
          _hideTimer?.cancel();
          _showOverlay();
        },
        onExit: (_) {
          setState(() => _pillHovered = false);
          _scheduleHide();
        },
        child: GestureDetector(
          onTap: _interactive ? widget.onAdvance : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: showHover ? _T.blue.withOpacity(0.10) : si.bg,
              borderRadius: BorderRadius.circular(99),
              border:
                  showHover
                      ? Border.all(color: _T.blue.withOpacity(0.45))
                      : null,
            ),
            child: StagePill(stageInfo: si),
          ),
        ),
      ),
    );
  }
}
