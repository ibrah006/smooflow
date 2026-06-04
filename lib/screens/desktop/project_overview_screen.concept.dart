import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/task_provider.dart';

class PipelineSegment {
  final String id;
  final TaskStatus status;
  int startDayOffset;
  int durationDays;

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
  final ScrollController _timelineScrollController = ScrollController();

  static const double _dayColumnWidth = 72.0;
  static const double _taskRowHeight = 64.0;
  static const int _timelineDaysRange = 30;

  late DateTime _timelineStartDate;

  List<PipelineRule> _pipelineRules = [];
  List<ProjectTask> _activeTasks = [];
  List<ProjectTask> _unassignedBacklog = [];

  // Track which segment is being hovered for the add stage button
  Map<String, String?> _hoveredSegmentId = {};

  // Track drag state per segment
  Map<String, double> _dragAccumulators = {};
  Map<String, double> _leftResizeAccumulators = {};
  Map<String, double> _rightResizeAccumulators = {};

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

    _unassignedBacklog = [
      ProjectTask(
        id: 'task-101',
        name: 'Airport Lightbox Vinyl Print',
        pipeline: [],
      ),
      ProjectTask(
        id: 'task-102',
        name: 'Vehicle Wrap - 3 Delivery Vans',
        pipeline: [],
      ),
      ProjectTask(
        id: 'task-103',
        name: 'Exhibition Fabric Wall Display',
        pipeline: [],
      ),
    ];

    _activeTasks = [
      ProjectTask(
        id: 'task-201',
        name: 'Flagship Store Front Signage',
        pipeline: [
          PipelineSegment(
            id: 'seg-1',
            status: TaskStatus.designing,
            startDayOffset: 0,
            durationDays: 3,
          ),
          PipelineSegment(
            id: 'seg-2',
            status: TaskStatus.waitingApproval,
            startDayOffset: 3,
            durationDays: 2,
          ),
          PipelineSegment(
            id: 'seg-3',
            status: TaskStatus.printing,
            startDayOffset: 5,
            durationDays: 4,
          ),
        ],
      ),
    ];
  }

  bool _isPipelineHazardPresent(
    ProjectTask targetTask,
    PipelineSegment targetSegment,
  ) {
    final rule = _pipelineRules.firstWhere(
      (r) => r.status == targetSegment.status,
    );
    if (!rule.isExclusive) return false;

    final targetStart = targetSegment.startDayOffset;
    final targetEnd = targetSegment.startDayOffset + targetSegment.durationDays;

    for (var task in _activeTasks) {
      if (task.id == targetTask.id) continue;
      for (var segment in task.pipeline) {
        if (segment.status == targetSegment.status) {
          final currentStart = segment.startDayOffset;
          final currentEnd = segment.startDayOffset + segment.durationDays;

          bool hasOverlap =
              !(targetStart >= currentEnd || targetEnd <= currentStart);
          if (hasOverlap) return true;
        }
      }
    }
    return false;
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.designing:
        return const Color(0xFF3B82F6); // Blue
      case TaskStatus.waitingApproval:
        return const Color(0xFFF97316); // Orange
      case TaskStatus.printing:
        return const Color(0xFF8B5CF6); // Purple
      case TaskStatus.installing:
        return const Color(0xFF10B981); // Green
      default:
        return const Color(0xFF64748B); // Gray
    }
  }

  String _getStatusLabel(TaskStatus status) {
    return status.toString().split('.').last.toUpperCase();
  }

  void _addNewSegment(ProjectTask task, PipelineSegment afterSegment) {
    setState(() {
      final newStartOffset =
          afterSegment.startDayOffset + afterSegment.durationDays;
      final nextStatus = _getNextStatus(afterSegment.status);

      final newSegment = PipelineSegment(
        id: 'seg-${DateTime.now().millisecondsSinceEpoch}',
        status: nextStatus,
        startDayOffset: newStartOffset,
        durationDays: 3, // Default duration
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

  @override
  void dispose() {
    _timelineScrollController.dispose();
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
          // ═══════════════════════════════════════════════════════════════════
          // LEFT SIDEBAR
          // ═══════════════════════════════════════════════════════════════════
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
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PROJECT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: const Color(0xFF3B82F6),
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
                              Color(0xFF10B981),
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

          // ═══════════════════════════════════════════════════════════════════
          // RIGHT CANVAS: GANTT CHART
          // ═══════════════════════════════════════════════════════════════════
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  height: 56,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Project Timeline - Interactive Gantt Chart',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Drag blocks to move • Drag edges to resize • Click + to add stages',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Gantt Chart
                Expanded(
                  child:
                      _activeTasks.isEmpty
                          ? const Center(
                            child: Text(
                              'No tasks found.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          )
                          : Scrollbar(
                            controller: _timelineScrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _timelineScrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: SizedBox(
                                width:
                                    _timelineDaysRange * _dayColumnWidth + 240,
                                child: Column(
                                  children: [
                                    _buildTimelineCalendarHeader(),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _activeTasks.length,
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (context, index) {
                                          return _buildTaskRow(
                                            _activeTasks[index],
                                            index,
                                          );
                                        },
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
        color: Color(0xFFF1F5F9),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 240,
            padding: const EdgeInsets.only(left: 24),
            alignment: Alignment.centerLeft,
            child: const Text(
              'TASK',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
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
                            ? const Color(0xFFF8FAFC)
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
                              ? const Color(0xFF3B82F6)
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
                              ? const Color(0xFF3B82F6)
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
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        color: Colors.white,
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Grid background
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

          // Task label
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),

          // Pipeline segments (blocks)
          Positioned.fill(
            child: Stack(
              children: [
                ...task.pipeline.asMap().entries.map((entry) {
                  final int segmentIndex = entry.key;
                  final PipelineSegment segment = entry.value;
                  return _buildSegmentBlock(task, segment, segmentIndex);
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
  ) {
    final String blockId = '${task.id}-${segment.id}';
    final double leftPosition =
        240 + (segment.startDayOffset * _dayColumnWidth) + 4;
    final double blockWidth = (segment.durationDays * _dayColumnWidth) - 8;
    final Color blockColor = _getStatusColor(segment.status);

    _dragAccumulators.putIfAbsent(blockId, () => 0.0);
    _leftResizeAccumulators.putIfAbsent(blockId, () => 0.0);
    _rightResizeAccumulators.putIfAbsent(blockId, () => 0.0);

    final bool isHovered = _hoveredSegmentId[task.id] == segment.id;

    return Positioned(
      left: leftPosition,
      top: 8,
      width: blockWidth,
      height: 48,
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _hoveredSegmentId[task.id] = segment.id;
          });
        },
        onExit: (_) {
          setState(() {
            _hoveredSegmentId[task.id] = null;
          });
        },
        child: Tooltip(
          message:
              '${_getStatusLabel(segment.status)}\n${segment.durationDays} days',
          preferBelow: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: blockColor.withOpacity(isHovered ? 0.9 : 0.8),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: blockColor.withOpacity(isHovered ? 0.4 : 0.2),
                  blurRadius: isHovered ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Left resize handle
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 8,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        _leftResizeAccumulators[blockId] = 0.0;
                      },
                      onHorizontalDragUpdate: (details) {
                        _leftResizeAccumulators[blockId] =
                            (_leftResizeAccumulators[blockId] ?? 0.0) +
                            details.delta.dx;
                        final int daysShift =
                            ((_leftResizeAccumulators[blockId] ?? 0.0) /
                                    _dayColumnWidth)
                                .round();

                        if (daysShift != 0) {
                          setState(() {
                            final newStart = segment.startDayOffset + daysShift;
                            final maxStart =
                                segment.startDayOffset +
                                segment.durationDays -
                                1;
                            if (newStart <= maxStart) {
                              segment.startDayOffset = newStart;
                              segment.durationDays -= daysShift;
                            }
                          });
                          _leftResizeAccumulators[blockId] = 0.0;
                        }
                      },
                      child: Container(
                        color: Colors.white.withOpacity(0.1),
                        child: const Center(
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 8,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Main drag area
                Positioned(
                  left: 8,
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.move,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) {
                        _dragAccumulators[blockId] = 0.0;
                      },
                      onHorizontalDragUpdate: (details) {
                        _dragAccumulators[blockId] =
                            (_dragAccumulators[blockId] ?? 0.0) +
                            details.delta.dx;
                        final int daysShift =
                            ((_dragAccumulators[blockId] ?? 0.0) /
                                    _dayColumnWidth)
                                .round();

                        if (daysShift != 0) {
                          setState(() {
                            segment.startDayOffset += daysShift;
                          });
                          _dragAccumulators[blockId] = 0.0;
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Center(
                            child: Text(
                              _getStatusLabel(segment.status),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Right resize handle
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 8,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {
                        _rightResizeAccumulators[blockId] = 0.0;
                      },
                      onHorizontalDragUpdate: (details) {
                        _rightResizeAccumulators[blockId] =
                            (_rightResizeAccumulators[blockId] ?? 0.0) +
                            details.delta.dx;
                        final int daysShift =
                            ((_rightResizeAccumulators[blockId] ?? 0.0) /
                                    _dayColumnWidth)
                                .round();

                        if (daysShift != 0) {
                          setState(() {
                            final newDuration =
                                segment.durationDays + daysShift;
                            if (newDuration > 0) {
                              segment.durationDays = newDuration;
                            }
                          });
                          _rightResizeAccumulators[blockId] = 0.0;
                        }
                      },
                      child: Container(
                        color: Colors.white.withOpacity(0.1),
                        child: const Center(
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 8,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Add stage button (appears on hover)
                if (isHovered && segmentIndex == task.pipeline.length - 1)
                  Positioned(
                    right: -20,
                    top: 50 / 2 - 16,
                    child: Tooltip(
                      message: 'Add next stage',
                      child: GestureDetector(
                        onTap: () => _addNewSegment(task, segment),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
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
}
