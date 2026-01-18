import 'package:flutter/material.dart';

enum TaskStatus {
  pending,
  inProgress,
  waitingApproval,
  approved,
  revision,
}

class AdvanceStagePopup {
  static void show({
    required BuildContext context,
    required GlobalKey buttonKey,
    required String taskName,
    required TaskStatus currentStatus,
    required Function(String? notes) onConfirm,
  }) {
    final RenderBox? renderBox =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AdvanceStagePopupContent(
        buttonPosition: buttonPosition,
        buttonSize: buttonSize,
        taskName: taskName,
        currentStatus: currentStatus,
        onConfirm: (notes) {
          overlayEntry.remove();
          onConfirm(notes);
        },
        onCancel: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _AdvanceStagePopupContent extends StatefulWidget {
  final Offset buttonPosition;
  final Size buttonSize;
  final String taskName;
  final TaskStatus currentStatus;
  final Function(String? notes) onConfirm;
  final VoidCallback onCancel;

  const _AdvanceStagePopupContent({
    required this.buttonPosition,
    required this.buttonSize,
    required this.taskName,
    required this.currentStatus,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_AdvanceStagePopupContent> createState() =>
      _AdvanceStagePopupContentState();
}

class _AdvanceStagePopupContentState extends State<_AdvanceStagePopupContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _notesController = TextEditingController();
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  (TaskStatus, String, IconData, Color) get _nextStageInfo {
    switch (widget.currentStatus) {
      case TaskStatus.pending:
        return (
          TaskStatus.inProgress,
          'In Progress',
          Icons.play_circle_rounded,
          const Color(0xFFF59E0B),
        );
      case TaskStatus.inProgress:
        return (
          TaskStatus.waitingApproval,
          'Pending Approval',
          Icons.send_rounded,
          const Color(0xFF8B5CF6),
        );
      case TaskStatus.waitingApproval:
        return (
          TaskStatus.approved,
          'Approved',
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
        );
      default:
        return (
          TaskStatus.approved,
          'Approved',
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextStage = _nextStageInfo;
    final nextStatusLabel = nextStage.$2;
    final nextIcon = nextStage.$3;
    final nextColor = nextStage.$4;

    final screenSize = MediaQuery.of(context).size;
    final popupWidth = 340.0;
    final popupMaxHeight = 400.0;

    // Calculate position - show above or below button
    final spaceBelow =
        screenSize.height - (widget.buttonPosition.dy + widget.buttonSize.height);
    final showAbove = spaceBelow < 300;

    double top;
    if (showAbove) {
      top = widget.buttonPosition.dy - popupMaxHeight - 12;
    } else {
      top = widget.buttonPosition.dy + widget.buttonSize.height + 12;
    }

    // Center popup horizontally relative to button
    final left = (widget.buttonPosition.dx + widget.buttonSize.width / 2) -
        (popupWidth / 2);

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: widget.onCancel,
          child: Container(
            color: Colors.black.withOpacity(0.3),
            width: screenSize.width,
            height: screenSize.height,
          ),
        ),
        // Popup
        Positioned(
          left: left.clamp(16.0, screenSize.width - popupWidth - 16),
          top: top.clamp(16.0, screenSize.height - popupMaxHeight - 16),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: showAbove ? Alignment.bottomCenter : Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: popupWidth,
                  constraints: BoxConstraints(maxHeight: popupMaxHeight),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              nextColor.withOpacity(0.08),
                              nextColor.withOpacity(0.03),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: nextColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                nextIcon,
                                color: nextColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Advance to',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nextStatusLabel,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: nextColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onCancel,
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xFF64748B),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Task info
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.assignment_rounded,
                                      size: 18,
                                      color: Color(0xFF4F46E5),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        widget.taskName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Add notes toggle
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _showNotes = !_showNotes;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.9,
                                        child: Checkbox(
                                          value: _showNotes,
                                          onChanged: (value) {
                                            setState(() {
                                              _showNotes = value ?? false;
                                            });
                                          },
                                          activeColor: const Color(0xFF4F46E5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'Add notes',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Notes field
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: _showNotes
                                    ? Column(
                                        children: [
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _notesController,
                                            autofocus: true,
                                            maxLines: 3,
                                            style: const TextStyle(fontSize: 14),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Add any comments or notes...',
                                              hintStyle: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 13,
                                              ),
                                              filled: true,
                                              fillColor:
                                                  const Color(0xFFF8FAFC),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF4F46E5),
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.all(12),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Actions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: widget.onCancel,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF64748B),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  final notes = _showNotes &&
                                          _notesController.text.isNotEmpty
                                      ? _notesController.text
                                      : null;
                                  widget.onConfirm(notes);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: nextColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Confirm',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(nextIcon, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Usage example in your screen:
/*
class TaskDetailsScreen extends StatefulWidget {
  // ...
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final GlobalKey _advanceButtonKey = GlobalKey();

  Widget _buildHeader() {
    return ElevatedButton.icon(
      key: _advanceButtonKey, // Assign the key here
      onPressed: () {
        AdvanceStagePopup.show(
          context: context,
          buttonKey: _advanceButtonKey,
          taskName: 'Social Media Graphics',
          currentStatus: TaskStatus.inProgress,
          onConfirm: (notes) {
            // Handle stage advancement
            setState(() {
              // Update status
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task advanced successfully'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
      label: const Text('Advance Stage'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
    );
  }
}
*/