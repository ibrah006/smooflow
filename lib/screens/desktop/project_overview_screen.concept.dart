import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/task_provider.dart'; // Ensure access to your design tokens like _T

class PipelineSegment {
  final TaskStatus status;
  int startDayOffset; // Grid index offset from baseline timeline start
  int durationDays; // Span size in grid units

  PipelineSegment({
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

// Controls whether a specific department allows concurrent jobs or functions as a strict single-task pipeline
class PipelineRule {
  final TaskStatus status;
  bool
  isExclusive; // If true, two tasks cannot share this stage on the same calendar day

  PipelineRule({required this.status, this.isExclusive = false});
}

class DesktopProjectOverviewScreen extends ConsumerStatefulWidget {
  final String? selectedProjectId;
  final dynamic
  project; // Replace 'dynamic' with your structural 'Project' model class type token safely

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

  // Configuration constants for the Gantt timeline viewport metrics
  static const double _dayColumnWidth = 72.0;
  static const double _taskRowHeight = 44.0;
  static const int _timelineDaysRange = 30;

  late DateTime _timelineStartDate;

  // Global organizational pipeline constraints mapping
  List<PipelineRule> _pipelineRules = [];

  // Active Project Production Lines
  List<ProjectTask> _activeTasks = [];

  // Unscheduled Backlog pool waiting to be dragged/dropped into active production chart execution tracks
  List<ProjectTask> _unassignedBacklog = [];

  // Global state-tracking variables for active background creation interactions
  String? _activeCreatingTaskId;
  DateTime? _creationStartDay;
  double _gridDragAccumulator = 0.0;

  // Track dragging/resizing state handles globally so they persist over build cycles
  final Map<String, double> _dragAccumulators = {};
  final Map<String, double> _leftResizeAccumulators = {};
  final Map<String, double> _rightResizeAccumulators = {};

  @override
  void initState() {
    super.initState();
    // Anchor timeline starting point to today at midnight or fallback safely to project creation metrics
    final now = DateTime.now();
    _timelineStartDate = DateTime(now.year, now.month, now.day);

    // Default organizational rules: Design and Printing are typically single-team operational bottlenecks
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

    // Seed Unscheduled Backlog Queue
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

    // Seed Initial Active Production Lines
    _activeTasks = [
      ProjectTask(
        id: 'task-201',
        name: 'Flagship Store Front Signage',
        pipeline: [
          PipelineSegment(
            status: TaskStatus.designing,
            startDayOffset: 0,
            durationDays: 3,
          ),
          PipelineSegment(
            status: TaskStatus.waitingApproval,
            startDayOffset: 3,
            durationDays: 2,
          ),
          PipelineSegment(
            status: TaskStatus.printing,
            startDayOffset: 5,
            durationDays: 4,
          ),
        ],
      ),
    ];
  }

  // ── ADVANCED CORE PROCESSING: HAZARD DETECTION AND SYSTEM COLLISION CHECKING ──

  bool _isPipelineHazardPresent(
    ProjectTask targetTask,
    PipelineSegment targetSegment,
  ) {
    // Check if the business rule ignores concurrent execution restrictions for this stage
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

          // Structural Check for Overlapping Execution Cycles
          bool zeroOverlaps =
              targetStart >= currentEnd || targetEnd <= currentStart;
          if (!zeroOverlaps)
            return true; // Hazard discovered! Structural bottleneck block triggered.
        }
      }
    }
    return false;
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    super.dispose();
  }

  String _getPriorityLabel(int priority) {
    if (priority >= 3) return 'CRITICAL';
    if (priority == 2) return 'HIGH';
    if (priority == 1) return 'MEDIUM';
    return 'LOW';
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 3) return const Color(0xFFEF4444); // Slate Red
    if (priority == 2) return const Color(0xFFF97316); // Amber Orange
    if (priority == 1) return const Color(0xFF3B82F6); // Tech Blue
    return const Color(0xFF64748B); // Cool Slate Neutral
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

    // ── Business Data Extraction Mapping Layer (Requested Requirements) ──
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

    // Filter out invalid task items or instances missing clear date structural references to avoid breaks
    final timelineTasks =
        filteredTasks
            .where((t) => t.dueDate != null || t.createdAt != null)
            .toList();

    // Calculate completion metadata configurations cleanly
    final totalCount = timelineTasks.length;
    final completedCount =
        timelineTasks.where((t) => t.status == 'completed').length;
    final double completionPercent =
        totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Container(
      color: const Color(
        0xFFF8FAFC,
      ), // Strict premium light background contrast profile
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // ── LEFT SIDEBAR: STRATEGIC METADATA CONTROL BOARD
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
                // Project Identifier Badges & Structural Layout Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(
                          widget.project.priority,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getPriorityLabel(widget.project.priority),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: _getPriorityColor(widget.project.priority),
                        ),
                      ),
                    ),
                    Text(
                      widget.project.status.toString().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.project.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Project Descriptions Block
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
                      widget.project.description ??
                          'No operational parameters or structural descriptors declared for this workspace initialization profile.',
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

                // Due Date Meta Panel Fields
                const Text(
                  'DEADLINE HORIZON',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.project.dueDate != null
                          ? DateFormat(
                            'MMMM dd, yyyy',
                          ).format(widget.project.dueDate!)
                          : 'Unscheduled Track',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 32),

                // Health Progress Ring Components
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
                            ), // Active Emerald Green
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
                          '${totalCount - completedCount} open assignments tracking',
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
          // ── RIGHT CANVAS: INTERACTIVE HIGH-DENSITY GANTT CHART TIMELINE
          // ═══════════════════════════════════════════════════════════════════
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Filter Context Header Anchor Panel Layout
                Container(
                  height: 56,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Operational Schedule Gantt Model',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Row(
                        children: [
                          _buildLegendDot(const Color(0xFF10B981), 'Completed'),
                          const SizedBox(width: 16),
                          _buildLegendDot(
                            const Color(0xFF3B82F6),
                            'Pending / Active',
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Drag blocks horizontally to shift horizons',
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

                // Scrollable Gantt Workspace Grid Blocks Layout Matrix
                Expanded(
                  child:
                      timelineTasks.isEmpty
                          ? const Center(
                            child: Text(
                              'No active structured tasks discovered matching this timeline deployment criteria.',
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
                                    _timelineDaysRange * _dayColumnWidth +
                                    240, // Base task label layout padding spacing allocation parameter offset
                                child: Column(
                                  children: [
                                    // Gantt Timeline Calendar X-Axis Scale Indicator Line Header Row
                                    _buildTimelineCalendarHeader(),

                                    // Interactive Row Rows Iterations Stack View Builder Block
                                    // ...timelineTasks
                                    //     .map((tt) => Text(tt.name))
                                    //     .toList(),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: timelineTasks.length,
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (context, index) {
                                          final task = timelineTasks[index];
                                          return _buildGanttInteractiveTaskRow(
                                            task,
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

  // ── Supporting Structural Grid Builders ────────────────────────────────────

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineCalendarHeader() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Blank placeholder bounding frame offsetting task labels column safely
          Container(
            width: 240,
            padding: EdgeInsets.only(left: 24),
            alignment: Alignment.centerLeft,
            child: Text(
              'TASK STRUCTURAL LINE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          // Day Increment Render Blocks loop iterations
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

  // ── REFACTORED HIGH-DENSITY INTERACTIVE TASK ROW ──
  Widget _buildGanttInteractiveTaskRow(dynamic task, int index) {
    final String taskId = task.id.toString();

    // Safely anchor timeline boundaries
    final taskStart =
        task.createdAt != null
            ? DateTime(
              task.createdAt!.year,
              task.createdAt!.month,
              task.createdAt!.day,
            )
            : _timelineStartDate;

    final taskEnd =
        task.dueDate != null
            ? DateTime(
              task.dueDate!.year,
              task.dueDate!.month,
              task.dueDate!.day,
            )
            : taskStart.add(const Duration(days: 1));

    int startOffsetDays = taskStart.difference(_timelineStartDate).inDays;
    int durationDays = taskEnd.difference(taskStart).inDays;

    if (durationDays <= 0) durationDays = 1;

    // Viewport bounds clipping rules
    if (startOffsetDays < 0) {
      durationDays += startOffsetDays;
      startOffsetDays = 0;
    }

    final double leftSpacingPosition =
        240 + (startOffsetDays * _dayColumnWidth);
    final double barWidthSize = durationDays * _dayColumnWidth;

    final Color barCoreColor =
        task.status == 'completed'
            ? const Color(0xFF10B981)
            : const Color(0xFF3B82F6);

    // Initialize map keys for persistent drag memory structures if absent
    _dragAccumulators.putIfAbsent(taskId, () => 0.0);
    _leftResizeAccumulators.putIfAbsent(taskId, () => 0.0);
    _rightResizeAccumulators.putIfAbsent(taskId, () => 0.0);

    // Determine if this exact row is currently being interactively created from scratch
    final bool isCurrentlySpawning = _activeCreatingTaskId == taskId;

    return Container(
      height: _taskRowHeight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        color: Colors.white,
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // 1. DYNAMIC INTERACTIVE GRID CANVAS (DRAG TO CREATE/EXTEND)
          // ═══════════════════════════════════════════════════════════════════
          Positioned.fill(
            child: Row(
              children: [
                const SizedBox(width: 240), // Offset past labels column
                ...List.generate(_timelineDaysRange, (i) {
                  final cellDate = _timelineStartDate.add(Duration(days: i));

                  return Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.cell,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (_) {
                          setState(() {
                            _activeCreatingTaskId = taskId;
                            _creationStartDay = cellDate;
                            _gridDragAccumulator = 0.0;

                            // Initialize / clear out existing data metrics
                            task.createdAt = cellDate;
                            task.dueDate = cellDate.add(
                              const Duration(days: 1),
                            );
                          });
                        },
                        onPanUpdate: (details) {
                          if (_activeCreatingTaskId != taskId ||
                              _creationStartDay == null)
                            return;

                          _gridDragAccumulator += details.delta.dx;
                          final int deltaDays =
                              (_gridDragAccumulator / _dayColumnWidth).round();

                          if (deltaDays != 0) {
                            setState(() {
                              final calculatedEnd = _creationStartDay!.add(
                                Duration(days: deltaDays + 1),
                              );
                              // Ensure sequence integrity: block cannot have negative duration
                              if (calculatedEnd.isAfter(_creationStartDay!)) {
                                task.dueDate = calculatedEnd;
                              }
                            });
                            _gridDragAccumulator = 0.0;
                          }
                        },
                        onPanEnd: (_) {
                          setState(() {
                            _activeCreatingTaskId = null;
                            _creationStartDay = null;
                          });
                        },
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                isCurrentlySpawning
                                    ? const Color(0xFFEFF6FF).withOpacity(0.4)
                                    : Colors.transparent,
                            border: const Border(
                              right: BorderSide(
                                color: Color(0xFFF1F5F9),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // 2. STATIC METADATA ROW LABELS
          // ═══════════════════════════════════════════════════════════════════
          Positioned(
            left: 0,
            width: 240,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                task.name.toString(),
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

          // ═══════════════════════════════════════════════════════════════════
          // 3. INTERACTIVE TIMELINE BLOCK (RENDER ONLY IF TIMELINES ARE VALID)
          // ═══════════════════════════════════════════════════════════════════
          if (task.createdAt != null)
            Positioned(
              left: leftSpacingPosition + 4,
              width: barWidthSize - 8,
              height: 28,
              child: Tooltip(
                message:
                    '${task.name}\nStart: ${DateFormat('MM/dd').format(taskStart)}\nEnd: ${DateFormat('MM/dd').format(taskEnd)}',
                preferBelow: false,
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 50,
                  ), // Subtle snapping visual interpolation
                  decoration: BoxDecoration(
                    color: barCoreColor.withOpacity(
                      isCurrentlySpawning ? 0.70 : 0.85,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          isCurrentlySpawning
                              ? const Color(0xFF2563EB)
                              : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: barCoreColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Row(
                      children: [
                        // ── LEFT RESIZE HANDLE ──
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: GestureDetector(
                            onHorizontalDragStart:
                                (_) => _leftResizeAccumulators[taskId] = 0.0,
                            onHorizontalDragUpdate: (details) {
                              _leftResizeAccumulators[taskId] =
                                  (_leftResizeAccumulators[taskId] ?? 0.0) +
                                  details.delta.dx;
                              final int daysShift =
                                  ((_leftResizeAccumulators[taskId] ?? 0.0) /
                                          _dayColumnWidth)
                                      .round();

                              if (daysShift != 0) {
                                final DateTime proposedStart = (task.createdAt
                                        as DateTime)
                                    .add(Duration(days: daysShift));
                                if (proposedStart.isBefore(
                                  task.dueDate as DateTime,
                                )) {
                                  setState(() {
                                    task.createdAt = proposedStart;
                                  });
                                  _leftResizeAccumulators[taskId] = 0.0;
                                }
                              }
                            },
                            child: Container(
                              width: 10,
                              color: Colors.white.withOpacity(0.15),
                              child: const Center(
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── BODY DRAG ZONE ──
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.move,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragStart:
                                  (_) => _dragAccumulators[taskId] = 0.0,
                              onHorizontalDragUpdate: (details) {
                                _dragAccumulators[taskId] =
                                    (_dragAccumulators[taskId] ?? 0.0) +
                                    details.delta.dx;
                                final int daysShiftDelta =
                                    ((_dragAccumulators[taskId] ?? 0.0) /
                                            _dayColumnWidth)
                                        .round();

                                if (daysShiftDelta != 0) {
                                  final DateTime updatedCreatedDate =
                                      (task.createdAt as DateTime).add(
                                        Duration(days: daysShiftDelta),
                                      );
                                  final DateTime updatedDueDate =
                                      task.dueDate != null
                                          ? (task.dueDate as DateTime).add(
                                            Duration(days: daysShiftDelta),
                                          )
                                          : updatedCreatedDate.add(
                                            const Duration(days: 1),
                                          );

                                  setState(() {
                                    task.createdAt = updatedCreatedDate;
                                    if (task.dueDate != null)
                                      task.dueDate = updatedDueDate;
                                  });
                                  _dragAccumulators[taskId] = 0.0;
                                }
                              },
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6.0),
                                    child: IgnorePointer(
                                      child: Text(
                                        task.status.toString().toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── RIGHT RESIZE HANDLE ──
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: GestureDetector(
                            onHorizontalDragStart:
                                (_) => _rightResizeAccumulators[taskId] = 0.0,
                            onHorizontalDragUpdate: (details) {
                              _rightResizeAccumulators[taskId] =
                                  (_rightResizeAccumulators[taskId] ?? 0.0) +
                                  details.delta.dx;
                              final int daysShift =
                                  ((_rightResizeAccumulators[taskId] ?? 0.0) /
                                          _dayColumnWidth)
                                      .round();

                              if (daysShift != 0) {
                                final DateTime proposedEnd = (task.dueDate
                                        as DateTime)
                                    .add(Duration(days: daysShift));
                                if (proposedEnd.isAfter(
                                  task.createdAt as DateTime,
                                )) {
                                  setState(() {
                                    task.dueDate = proposedEnd;
                                  });
                                  _rightResizeAccumulators[taskId] = 0.0;
                                }
                              }
                            },
                            child: Container(
                              width: 10,
                              color: Colors.white.withOpacity(0.15),
                              child: const Center(
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 10,
                                  color: Colors.white60,
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
            ),
        ],
      ),
    );
  }
}
