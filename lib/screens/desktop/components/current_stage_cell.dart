// ─────────────────────────────────────────────────────────────────────────────
// CURRENT STAGE — Interactive hover-to-advance pill
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

class _T {
  static const blue = Color(0xFF2563EB);
}

class CurrentStageCell extends StatefulWidget {
  final dynamic stageInfo; // The current stage information object
  final TaskStatus? next;
  final bool ableToReinitialize;
  final bool canAdvance;
  final bool isProgressing;
  final VoidCallback onAdvance;

  const CurrentStageCell({
    super.key,
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
    // Determine if the user is allowed to click it right now
    final canInteract = widget.canAdvance && !widget.isProgressing;

    // Only show the advance prompt if hovered and interaction is allowed
    final showAdvance = _hovered && canInteract;

    // Extract base colors from the current stage info
    final Color baseColor = widget.stageInfo.color;
    final Color baseBg = widget.stageInfo.bg;

    // Smoothly animate colors based on hover state
    final Color bgColor = showAdvance ? baseColor : baseBg;
    final Color textColor = showAdvance ? Colors.white : baseColor;
    final Color borderColor =
        showAdvance ? baseColor : baseColor.withOpacity(0.3);

    // Determine the text to display
    String displayText = widget.stageInfo.label;

    if (widget.isProgressing) {
      displayText = 'Progressing...';
    } else if (showAdvance) {
      if (widget.ableToReinitialize) {
        displayText = 'Re-initialize';
      } else if (widget.next == TaskStatus.clientApproved) {
        displayText = 'Confirm Approval';
      } else if (widget.next != null) {
        displayText = 'Move to ${stageInfo(widget.next!).label}';
      }
    }

    return MouseRegion(
      cursor: canInteract ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: canInteract ? widget.onAdvance : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: borderColor),
            boxShadow:
                showAdvance
                    ? [
                      BoxShadow(
                        color: baseColor.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isProgressing) ...[
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                ] else if (showAdvance) ...[
                  Icon(Icons.arrow_forward_rounded, size: 13, color: textColor),
                  const SizedBox(width: 6),
                ] else ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: showAdvance ? 0.2 : 0.0,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
