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
  final dynamic stageInfo;
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
    // Determine if this is a final stage with no forward pipeline options
    final isFinalStage =
        (widget.next == null && !widget.ableToReinitialize) ||
        widget.next == TaskStatus.printing;
    final canInteract =
        widget.canAdvance && !widget.isProgressing && !isFinalStage;

    final showAdvance = _hovered && canInteract;
    final showLocked = _hovered && isFinalStage;

    // Style design tokens from stage metadata
    final Color baseColor = widget.stageInfo.color;
    final Color baseBg = widget.stageInfo.bg;

    // Morph styles seamlessly depending on interaction state
    Color bgColor = baseBg;
    Color textColor = baseColor;
    Color borderColor = baseColor.withOpacity(0.3);

    if (showAdvance) {
      bgColor = baseColor;
      textColor = Colors.white;
      borderColor = baseColor;
    } else if (showLocked) {
      bgColor = const Color(0xFFF1F5F9); // Muted slate background
      textColor = const Color(0xFF94A3B8); // Disabled slate text color
      borderColor = const Color(0xFFE2E8F0);
    }

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
      cursor:
          widget.isProgressing
              ? SystemMouseCursors.wait
              : canInteract
              ? SystemMouseCursors.click
              : isFinalStage
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: canInteract ? widget.onAdvance : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
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
            duration: const Duration(milliseconds: 180),
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
                ] else if (showLocked) ...[
                  Icon(Icons.lock_outline_rounded, size: 13, color: textColor),
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
