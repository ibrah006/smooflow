import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/task_provider.dart';

class PipelineSegment {
  final String id;
  final TaskStatus status;
  double startDayOffset;
  double durationDays;

  PipelineSegment({
    required this.id,
    required this.status,
    required this.startDayOffset,
    required this.durationDays,
  });
}

class ProjectTask {
  final String id;
  final String name;
  final List<PipelineSegment> pipeline;

  ProjectTask({required this.id, required this.name, required this.pipeline});
}

class PipelineRule {
  final TaskStatus status;
  bool isExclusive;

  PipelineRule({required this.status, this.isExclusive = false});
}

class TaskDependency {
  final String fromSegmentId;
  final String toSegmentId;
  final bool fromLeft;
  final bool toLeft;

  TaskDependency({
    required this.fromSegmentId,
    required this.toSegmentId,
    required this.fromLeft,
    required this.toLeft,
  });
}

class DesktopProjectOverviewScreen extends ConsumerStatefulWidget {
  final String? selectedProjectId;
  final dynamic project;

  const DesktopProjectOverviewScreen({
    super.key,
    required this.selectedProjectId,
    required this.project,
  });

  @override
  ConsumerState<DesktopProjectOverviewScreen> createState() =>
      _DesktopProjectOverviewScreenState();
}

class _DesktopProjectOverviewScreenState
    extends ConsumerState<DesktopProjectOverviewScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final GlobalKey _gridCanvasKey = GlobalKey();

  static const double _dayColumnWidth = 72.0;
  static const double _taskRowHeight = 54.0;
  static const double _blockHeight = 32.0;
  static const int _timelineDaysRange = 30;

  late DateTime _timelineStartDate;
  String? _lastSelectedProjectId;

  List<PipelineRule> _pipelineRules = [];
  final List<ProjectTask> _activeTasks = [];
  final List<TaskDependency> _dependencies = [];

  final Map<String, String?> _hoveredSegmentId = {};

  // Active Connection Link Drag State
  String? _draggingFromSegmentId;
  bool? _isDraggingFromLeft;
  Offset? _currentDragPosition;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _timelineStartDate = DateTime(now.year, now.month, now.day);

    _pipelineRules =
        TaskStatus.values.map((status) {
          return PipelineRule(
            status: status,
            isExclusive:
                status == TaskStatus.designing ||
                status == TaskStatus.printing ||
                status == TaskStatus.installing,
          );
        }).toList();
  }

  void _syncTasksWithProvider(List<dynamic> providerTasks) {
    final providerIds = providerTasks.map((t) => t.id.toString()).toSet();

    _activeTasks.removeWhere((task) => !providerIds.contains(task.id));

    for (var pTask in providerTasks) {
      final existingIndex = _activeTasks.indexWhere(
        (t) => t.id == pTask.id.toString(),
      );

      if (existingIndex == -1) {
        TaskStatus defaultStatus = TaskStatus.designing;
        if (pTask.status == 'completed') {
          defaultStatus = TaskStatus.installing;
        } else if (pTask.status == 'printing') {
          defaultStatus = TaskStatus.printing;
        }

        _activeTasks.add(
          ProjectTask(
            id: pTask.id.toString(),
            name: pTask.name ?? 'Untitled Task',
            pipeline: [
              PipelineSegment(
                id: 'seg-${pTask.id}-init',
                status: defaultStatus,
                startDayOffset: 1.0,
                durationDays: 4.0,
              ),
            ],
          ),
        );
      } else {
        final existing = _activeTasks[existingIndex];
        if (existing.name != pTask.name) {
          _activeTasks[existingIndex] = ProjectTask(
            id: existing.id,
            name: pTask.name ?? 'Untitled Task',
            pipeline: existing.pipeline,
          );
        }
      }
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.designing:
        return const Color(0xFF2563EB);
      case TaskStatus.waitingApproval:
        return const Color(0xFFD97706);
      case TaskStatus.printing:
        return const Color(0xFF4F46E5);
      case TaskStatus.installing:
        return const Color(0xFF059669);
      default:
        return const Color(0xFF475569);
    }
  }

  String _getStatusLabel(TaskStatus status) {
    return status.toString().split('.').last.toUpperCase();
  }

  void _addNewSegment(ProjectTask task, PipelineSegment afterSegment) {
    print("add new segment called");
    setState(() {
      final newStartOffset =
          afterSegment.startDayOffset + afterSegment.durationDays;
      final nextStatus = _getNextStatus(afterSegment.status);

      final newSegment = PipelineSegment(
        id: 'seg-${DateTime.now().millisecondsSinceEpoch}',
        status: nextStatus,
        startDayOffset: newStartOffset,
        durationDays: 3.0,
      );

      final segmentIndex = task.pipeline.indexOf(afterSegment);
      task.pipeline.insert(segmentIndex + 1, newSegment);
    });
  }

  TaskStatus _getNextStatus(TaskStatus current) {
    const statusSequence = [
      TaskStatus.designing,
      TaskStatus.waitingApproval,
      TaskStatus.printing,
      TaskStatus.installing,
    ];

    final currentIndex = statusSequence.indexOf(current);
    if (currentIndex >= 0 && currentIndex < statusSequence.length - 1) {
      return statusSequence[currentIndex + 1];
    }
    return TaskStatus.installing;
  }

  // Connection Drag Methods
  void _startConnectionDrag(String segmentId, bool isLeft, Offset globalPos) {
    final RenderBox? renderBox =
        _gridCanvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _draggingFromSegmentId = segmentId;
        _isDraggingFromLeft = isLeft;
        _currentDragPosition = renderBox.globalToLocal(globalPos);
      });
    }
  }

  void _updateConnectionDrag(Offset globalPos) {
    final RenderBox? renderBox =
        _gridCanvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && _draggingFromSegmentId != null) {
      setState(() {
        _currentDragPosition = renderBox.globalToLocal(globalPos);
      });
    }
  }

  void _endConnectionDrag() {
    if (_draggingFromSegmentId == null ||
        _currentDragPosition == null ||
        _isDraggingFromLeft == null)
      return;

    String? targetSegmentId;
    bool targetLeft = true;
    double minDistance = 24.0; // Proximity target snapping radius

    for (int tIdx = 0; tIdx < _activeTasks.length; tIdx++) {
      final task = _activeTasks[tIdx];
      for (var seg in task.pipeline) {
        if (seg.id == _draggingFromSegmentId) continue;

        // Visual coordinate alignment match with Painter layout offsets
        final lx = 240 + (seg.startDayOffset * _dayColumnWidth) - 11;
        final ly = (tIdx * _taskRowHeight) + (_taskRowHeight / 2);
        double distL = sqrt(
          pow(lx - _currentDragPosition!.dx, 2) +
              pow(ly - _currentDragPosition!.dy, 2),
        );
        if (distL < minDistance) {
          minDistance = distL;
          targetSegmentId = seg.id;
          targetLeft = true;
        }

        final rx =
            240 +
            ((seg.startDayOffset + seg.durationDays) * _dayColumnWidth) +
            11;
        final ry = (tIdx * _taskRowHeight) + (_taskRowHeight / 2);
        double distR = sqrt(
          pow(rx - _currentDragPosition!.dx, 2) +
              pow(ry - _currentDragPosition!.dy, 2),
        );
        if (distR < minDistance) {
          minDistance = distR;
          targetSegmentId = seg.id;
          targetLeft = false;
        }
      }
    }

    if (targetSegmentId != null) {
      setState(() {
        _dependencies.add(
          TaskDependency(
            fromSegmentId: _draggingFromSegmentId!,
            toSegmentId: targetSegmentId!,
            fromLeft: _isDraggingFromLeft!,
            toLeft: targetLeft,
          ),
        );
      });
    }

    setState(() {
      _draggingFromSegmentId = null;
      _isDraggingFromLeft = null;
      _currentDragPosition = null;
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.project == null) {
      return const Center(
        child: Text(
          'Select a project to view operational intelligence insights.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      );
    }

    final taskState = ref.watch(taskNotifierProvider);
    final allTasks = taskState.tasks;
    final filteredTasks =
        widget.selectedProjectId != null
            ? allTasks
                .where(
                  (t) => t.projectId.toString() == widget.selectedProjectId,
                )
                .toList()
            : allTasks;

    final timelineTasks =
        filteredTasks
            .where((t) => t.dueDate != null || t.createdAt != null)
            .toList();

    if (_lastSelectedProjectId != widget.selectedProjectId) {
      _lastSelectedProjectId = widget.selectedProjectId;
      _activeTasks.clear();
      _dependencies.clear();
    }

    _syncTasksWithProvider(filteredTasks);

    final totalCount = timelineTasks.length;
    final completedCount =
        timelineTasks.where((t) => t.status == 'completed').length;
    final double completionPercent =
        totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sidebar Detail Pane
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PROJECT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.project.name ?? 'Untitled Project',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PROJECT OBJECTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      widget.project.description ?? 'No description provided.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 32),
                const Text(
                  'COMPLETION METRIC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: completionPercent,
                            strokeWidth: 4.5,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF059669),
                            ),
                          ),
                        ),
                        Text(
                          '${(completionPercent * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedCount of $totalCount Tasks Done',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${totalCount - completedCount} open assignments',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right Work Canvas: Dynamic Gantt View
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 56,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Project Timeline - Interactive Gantt Chart',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.link_rounded,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Click and drag directly from end nodes (●) to link task layers',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _activeTasks.isEmpty
                          ? const Center(
                            child: Text(
                              'No project tasks to show on layout timeline.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          )
                          : Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: SizedBox(
                                width:
                                    _timelineDaysRange * _dayColumnWidth + 240,
                                child: Column(
                                  children: [
                                    _buildTimelineCalendarHeader(),
                                    Expanded(
                                      child: Scrollbar(
                                        controller: _verticalScrollController,
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          controller: _verticalScrollController,
                                          scrollDirection: Axis.vertical,
                                          child: Stack(
                                            key: _gridCanvasKey,
                                            children: [
                                              // Row Grid Matrix Container
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: List.generate(
                                                  _activeTasks.length,
                                                  (index) => _buildTaskRow(
                                                    _activeTasks[index],
                                                    index,
                                                  ),
                                                ),
                                              ),

                                              // Shared Interactive Painter Overlay
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: CustomPaint(
                                                    painter: GanttLinkPainter(
                                                      tasks: _activeTasks,
                                                      dependencies:
                                                          _dependencies,
                                                      draggingFromSegmentId:
                                                          _draggingFromSegmentId,
                                                      isDraggingFromLeft:
                                                          _isDraggingFromLeft,
                                                      currentDragPosition:
                                                          _currentDragPosition,
                                                      dayColumnWidth:
                                                          _dayColumnWidth,
                                                      taskRowHeight:
                                                          _taskRowHeight,
                                                      getStatusColor:
                                                          _getStatusColor,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCalendarHeader() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 240,
            padding: const EdgeInsets.only(left: 24),
            alignment: Alignment.centerLeft,
            child: const Text(
              'TASK NAME',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...List.generate(_timelineDaysRange, (i) {
            final targetDay = _timelineStartDate.add(Duration(days: i));
            final isWeekend =
                targetDay.weekday == DateTime.saturday ||
                targetDay.weekday == DateTime.sunday;
            final isToday =
                DateTime.now().day == targetDay.day &&
                DateTime.now().month == targetDay.month &&
                DateTime.now().year == targetDay.year;

            return Container(
              width: _dayColumnWidth,
              decoration: BoxDecoration(
                color:
                    isToday
                        ? const Color(0xFFEFF6FF)
                        : (isWeekend
                            ? const Color(0xFFFDFDFD)
                            : Colors.transparent),
                border: const Border(
                  left: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(targetDay).toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color:
                          isToday
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd').format(targetDay),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color:
                          isToday
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaskRow(ProjectTask task, int taskIndex) {
    return Container(
      height: _taskRowHeight,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
        ),
        color: Colors.white,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Positioned.fill(
            child: Row(
              children: [
                const SizedBox(width: 240),
                ...List.generate(_timelineDaysRange, (i) {
                  return Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Color(0xFFF1F5F9),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Positioned(
            left: 0,
            width: 240,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                task.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ...task.pipeline.asMap().entries.map((entry) {
                  return _buildSegmentBlock(
                    task,
                    entry.value,
                    entry.key,
                    taskIndex,
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBlock(
    ProjectTask task,
    PipelineSegment segment,
    int segmentIndex,
    int taskIndex,
  ) {
    final double leftPosition =
        240 + (segment.startDayOffset * _dayColumnWidth);
    final double blockWidth = max(16.0, segment.durationDays * _dayColumnWidth);
    final Color blockColor = _getStatusColor(segment.status);
    final bool isHovered = _hoveredSegmentId[task.id] == segment.id;

    final double topSpacing = (_taskRowHeight - _blockHeight) / 2;

    // Width reserved for the connection handles on both ends
    const double handleSpace = 14.0;

    return Positioned(
      // Parent container expanded by 14px symmetrically to guarantee uninhibited hit-testing input context
      left: leftPosition - handleSpace,
      top: topSpacing,
      width: blockWidth + (handleSpace * 2),
      height: _blockHeight,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredSegmentId[task.id] = segment.id),
        onExit: (_) async {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (_hoveredSegmentId[task.id] == segment.id) {
              setState(() => _hoveredSegmentId[task.id] = null);
            }
          });
        },
        child: Tooltip(
          message:
              '${_getStatusLabel(segment.status)}: ${segment.durationDays.toStringAsFixed(1)} days',
          preferBelow: false,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Center Content Main Task Block
              Positioned(
                left: handleSpace,
                right: handleSpace,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: blockColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: blockColor, width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      // Inner Left Resize Drag Window
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 10,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: Listener(
                            onPointerMove: (event) {
                              if (event.buttons == kPrimaryButton) {
                                final double dayDelta =
                                    event.delta.dx / _dayColumnWidth;
                                setState(() {
                                  final proposedStart =
                                      segment.startDayOffset + dayDelta;
                                  final proposedDuration =
                                      segment.durationDays - dayDelta;
                                  if (proposedDuration > 0.1 &&
                                      proposedStart >= 0) {
                                    segment.startDayOffset = proposedStart;
                                    segment.durationDays = proposedDuration;
                                  }
                                });
                              }
                            },
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ),

                      // Central Movement Shift Space
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 0,
                        bottom: 0,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.move,
                          child: Listener(
                            onPointerMove: (event) {
                              if (event.buttons == kPrimaryButton) {
                                final double dayDelta =
                                    event.delta.dx / _dayColumnWidth;
                                setState(() {
                                  segment.startDayOffset = max(
                                    0.0,
                                    segment.startDayOffset + dayDelta,
                                  );
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              alignment: Alignment.center,
                              color: Colors.transparent,
                              child: Text(
                                _getStatusLabel(segment.status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: blockColor,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Inner Right Resize Drag Window
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 10,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: Listener(
                            onPointerMove: (event) {
                              if (event.buttons == kPrimaryButton) {
                                final double dayDelta =
                                    event.delta.dx / _dayColumnWidth;
                                setState(() {
                                  final proposedDuration =
                                      segment.durationDays + dayDelta;
                                  if (proposedDuration > 0.1) {
                                    segment.durationDays = proposedDuration;
                                  }
                                });
                              }
                            },
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Fully Interactable Left Connection Handle Node: ●─
              Positioned(
                left: 0,
                width: handleSpace,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart:
                      (details) => _startConnectionDrag(
                        segment.id,
                        true,
                        details.globalPosition,
                      ),
                  onPanUpdate:
                      (details) =>
                          _updateConnectionDrag(details.globalPosition),
                  onPanEnd: (_) => _endConnectionDrag(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.alias,
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: blockColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(width: 8, height: 1.5, color: blockColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Fully Interactable Right Connection Handle Node: ─●
              Positioned(
                right: 0,
                width: handleSpace,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart:
                      (details) => _startConnectionDrag(
                        segment.id,
                        false,
                        details.globalPosition,
                      ),
                  onPanUpdate:
                      (details) =>
                          _updateConnectionDrag(details.globalPosition),
                  onPanEnd: (_) => _endConnectionDrag(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.alias,
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 1.5, color: blockColor),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: blockColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Add-Stage Context Button
              if (isHovered && segmentIndex == task.pipeline.length - 1)
                Positioned(
                  right: -28,
                  top: (_blockHeight - 20) / 100,
                  child: IconButton(
                    onPressed: () {
                      _addNewSegment(task, segment);
                    },
                    icon: const Icon(
                      Icons.add_circle,
                      color: Color(0xFF0F172A),
                      size: 17,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GanttLinkPainter extends CustomPainter {
  final List<ProjectTask> tasks;
  final List<TaskDependency> dependencies;
  final String? draggingFromSegmentId;
  final bool? isDraggingFromLeft;
  final Offset? currentDragPosition;
  final double dayColumnWidth;
  final double taskRowHeight;
  final Color Function(TaskStatus) getStatusColor;

  GanttLinkPainter({
    required this.tasks,
    required this.dependencies,
    required this.draggingFromSegmentId,
    required this.isDraggingFromLeft,
    required this.currentDragPosition,
    required this.dayColumnWidth,
    required this.taskRowHeight,
    required this.getStatusColor,
  });

  Offset _getNodeOffset(String segmentId, bool isLeft) {
    for (int tIdx = 0; tIdx < tasks.length; tIdx++) {
      final task = tasks[tIdx];
      for (var seg in task.pipeline) {
        if (seg.id == segmentId) {
          final double baseLeft = 240 + (seg.startDayOffset * dayColumnWidth);
          final double x =
              isLeft
                  ? (baseLeft - 11.0)
                  : (baseLeft + (seg.durationDays * dayColumnWidth) + 11.0);
          final double y = (tIdx * taskRowHeight) + (taskRowHeight / 2);
          return Offset(x, y);
        }
      }
    }
    return Offset.zero;
  }

  Color _getSegmentColor(String segmentId) {
    for (var task in tasks) {
      for (var seg in task.pipeline) {
        if (seg.id == segmentId) return getStatusColor(seg.status);
      }
    }
    return const Color(0xFF475569);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..isAntiAlias = true;

    // Render committed tracking dependency layout lines
    for (var dep in dependencies) {
      final startPos = _getNodeOffset(dep.fromSegmentId, dep.fromLeft);
      final endPos = _getNodeOffset(dep.toSegmentId, dep.toLeft);

      if (startPos != Offset.zero && endPos != Offset.zero) {
        paint.color = _getSegmentColor(dep.fromSegmentId).withOpacity(0.55);

        final path = Path()..moveTo(startPos.dx, startPos.dy);
        final controlOffset = (startPos.dx - endPos.dx).abs() * 0.45;

        final cp1X =
            startPos.dx + (dep.fromLeft ? -controlOffset : controlOffset);
        final cp2X = endPos.dx + (dep.toLeft ? -controlOffset : controlOffset);

        path.cubicTo(cp1X, startPos.dy, cp2X, endPos.dy, endPos.dx, endPos.dy);
        canvas.drawPath(path, paint);
      }
    }

    // Render smooth bezier preview path during node layout dragging actions
    if (draggingFromSegmentId != null &&
        currentDragPosition != null &&
        isDraggingFromLeft != null) {
      final startPos = _getNodeOffset(
        draggingFromSegmentId!,
        isDraggingFromLeft!,
      );
      if (startPos != Offset.zero) {
        paint.color = _getSegmentColor(
          draggingFromSegmentId!,
        ).withOpacity(0.75);

        final path = Path()..moveTo(startPos.dx, startPos.dy);
        final controlOffset =
            (startPos.dx - currentDragPosition!.dx).abs() * 0.45;
        final cp1X =
            startPos.dx +
            (isDraggingFromLeft! ? -controlOffset : controlOffset);

        path.quadraticBezierTo(
          cp1X,
          startPos.dy,
          currentDragPosition!.dx,
          currentDragPosition!.dy,
        );
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GanttLinkPainter oldDelegate) => true;
}
