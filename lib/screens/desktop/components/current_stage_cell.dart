// ─────────────────────────────────────────────────────────────────────────────
// CURRENT STAGE — Interactive hover-to-advance pill
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/screens/desktop/components/stage_pill.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

class _T {
  static const blue = Color(0xFF2563EB);
}

class CurrentStageCell extends StatefulWidget {
  final dynamic stageInfo; // same type returned by stageInfo()
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
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final si = widget.stageInfo;
    final interactive = widget.canAdvance && !widget.isProgressing;
    final showHover = interactive && _hovered;

    final nextLabel =
        widget.ableToReinitialize
            ? 'Re-initialize'
            : widget.next != null
            ? stageInfo(widget.next!).label
            : null;

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: interactive ? widget.onAdvance : null,
        child: Tooltip(
          message:
              interactive && nextLabel != null ? 'Advance to $nextLabel' : '',
          preferBelow: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: showHover ? 10 : 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: showHover ? _T.blue.withOpacity(0.08) : si.bg,
              borderRadius: BorderRadius.circular(99),
              border:
                  showHover
                      ? Border.all(color: _T.blue.withOpacity(0.4))
                      : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StagePill(stageInfo: si),
                AnimatedSize(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child:
                      showHover
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 6),
                              if (widget.isProgressing)
                                const SizedBox(
                                  width: 11,
                                  height: 11,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _T.blue,
                                  ),
                                )
                              else ...[
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: _T.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  nextLabel ?? '',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: _T.blue,
                                  ),
                                ),
                              ],
                            ],
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
