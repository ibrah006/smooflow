import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/material.dart';
import 'package:smooflow/core/models/printer.dart';
import 'package:smooflow/core/models/progress_log.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/core/models/work_activity_log.dart';
import 'package:smooflow/core/services/login_service.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/providers/material_provider.dart';
import 'package:smooflow/providers/printer_provider.dart';
import 'package:smooflow/providers/progress_log_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/providers/work_activity_log_providers.dart';

class TaskScreen extends ConsumerStatefulWidget {
  final int taskId;

  const TaskScreen(
    this.taskId,
    {super.key}
  );

  @override
  ConsumerState<TaskScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showAllAssignees = false;

  // ── Design tokens ─────────────────────────────────────────────────────────
  static const Color _bg         = Color(0xFFF8FAFC);
  static const Color _surface    = Color(0xFFFFFFFF);
  static const Color _border     = Color(0xFFE2E8F0);
  static const Color _textPrimary   = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _textMuted     = Color(0xFF94A3B8);
  static const Color _brandBlue     = Color(0xFF2563EB);
  static const Color _green         = Color(0xFF10B981);
  static const Color _amber         = Color(0xFFF59E0B);
  static const Color _red           = Color(0xFFEF4444);
  static const Color _purple        = Color(0xFF8B5CF6);
  static const Color _cyan          = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final currentUser = LoginService.currentUser!;

  Task get task => ref.watch(taskNotifierProvider).firstWhere((t)=> t.id == widget.taskId);

  String get projectName => ref.watch(projectNotifierProvider).firstWhere((p)=> p.id == task.projectId).name;

  Printer? get printerInfo {
    try {
      return ref.watch(printerNotifierProvider).printers.firstWhere((printer)=> printer.id == task.printerId);
    } catch(e) {
      return null;
    }
  }

  MaterialModel? get materialInfo {
    try {
      return ref.watch(materialNotifierProvider).materials.firstWhere((material)=> material.id == task.materialId);
    } catch(e) {
      return null;
    }
  }

  List<ProgressLog> get progressLogs => ref.watch(progressLogNotifierProvider).where((log)=> task.progressLogIds.contains(log.id)).toList();

  List<WorkActivityLog> get activityLogs => ref.watch(workActivityLogNotifierProvider).where((log)=> task.workActivityLogs.contains(log.id)).toList();

  // ── Status helpers ─────────────────────────────────────────────────────────
  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.designing:    return _amber;
      case TaskStatus.printing:     return _brandBlue;
      case TaskStatus.finishing:    return _purple;
      case TaskStatus.installing:   return _cyan;
      case TaskStatus.completed:    return _green;
      case TaskStatus.blocked:    return _red;
      default:                      return _textSecondary;
    }
  }

  Color _statusBg(TaskStatus s) {
    switch (s) {
      case TaskStatus.designing:    return Color(0xFFFEF3C7);
      case TaskStatus.printing:     return Color(0xFFEFF6FF);
      case TaskStatus.finishing:    return Color(0xFFF3E8FF);
      case TaskStatus.installing:   return Color(0xFFECFEFF);
      case TaskStatus.completed:    return Color(0xFFECFDF5);
      case TaskStatus.blocked:    return Color(0xFFFEE2E2);
      default:                      return Color(0xFFF1F5F9);
    }
  }

  IconData _statusIcon(TaskStatus s) {
    switch (s) {
      case TaskStatus.designing:    return Icons.draw_outlined;
      case TaskStatus.printing:     return Icons.print_rounded;
      case TaskStatus.finishing:    return Icons.auto_fix_high_rounded;
      case TaskStatus.installing:   return Icons.handyman_outlined;
      case TaskStatus.completed:    return Icons.check_circle_rounded;
      case TaskStatus.blocked:    return Icons.cancel_rounded;
      default:                      return Icons.radio_button_unchecked;
    }
  }

  bool get _isDueSoon {
    if (task.dueDate == null) return false;
    final diff = task.dueDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 3;
  }

  bool get _isOverdue {
    if (task.dueDate == null) return false;
    return task.dueDate!.isBefore(DateTime.now()) &&
        task.status != TaskStatus.completed;
  }

  // ── Stages list for the status stepper ────────────────────────────────────
  static const List<TaskStatus> _stages = [
    TaskStatus.designing,
    TaskStatus.printing,
    TaskStatus.finishing,
    TaskStatus.installing,
    TaskStatus.completed,
  ];

  int get _currentStageIndex =>
      _stages.indexOf(task.status).clamp(0, _stages.length - 1);

  // ─────────────────────────────────────────────────────────────────────────

  void onEdit() {}
  void onSchedulePrint() {}
  void onStatusChange (TaskStatus status) {

  }
  void onDelete () {}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatusStepper(),
            _buildTabBar(),
            Expanded(
              child: Container(
                color: _bg,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildProductionTab(),
                    _buildActivityTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _surface,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_back_ios_new,
                      color: Color(0xFF475569), size: 20),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Task Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              // More options
              PopupMenuButton<String>(
                offset: Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.more_horiz_rounded,
                      color: Color(0xFF475569), size: 22),
                ),
                onSelected: (v) {
                  if (v == 'edit' && onEdit != null)
                    onEdit!();
                  if (v == 'delete' && onDelete != null)
                    _confirmDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                          size: 20, color: _textSecondary),
                      SizedBox(width: 12),
                      Text('Edit Task'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: false,
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 20, color: _red),
                      SizedBox(width: 12),
                      Text('Delete Task',
                          style: TextStyle(color: _red.withOpacity(0.5))),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          // Task name + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                    height: 1.25,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBg(task.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(task.status),
                        size: 13,
                        color: _statusColor(task.status)),
                    SizedBox(width: 5),
                    Text(
                      task.statusName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(task.status),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          // Meta row — ID · project · due date
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _metaChip(
                Icons.tag,
                'ID ${task.id}',
              ),
              _metaChip(
                Icons.folder_outlined,
                projectName,
              ),
              if (task.dueDate != null)
                _metaChip(
                  Icons.event_rounded,
                  DateFormat('MMM dd, yyyy')
                      .format(task.dueDate!),
                  color: _isOverdue
                      ? _red
                      : _isDueSoon
                          ? _amber
                          : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, {Color? color}) {
    final c = color ?? _textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 13, color: c, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── STATUS STEPPER ─────────────────────────────────────────────────────────
  Widget _buildStatusStepper() {
    final isBlocked =
        task.status == TaskStatus.blocked;

    return Container(
      color: _surface,
      child: Column(
        children: [
          Divider(height: 1, thickness: 1, color: _border),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: isBlocked
                ? _buildCancelledBanner()
                : Row(
                    children: List.generate(_stages.length * 2 - 1, (i) {
                      if (i.isOdd) {
                        // Connector line
                        final stageIndex = i ~/ 2;
                        final filled = stageIndex < _currentStageIndex;
                        return Expanded(
                          child: Container(
                            height: 2,
                            color: filled ? _brandBlue : _border,
                          ),
                        );
                      }
                      final stageIndex = i ~/ 2;
                      final stage = _stages[stageIndex];
                      final isDone = stageIndex < _currentStageIndex;
                      final isCurrent =
                          stageIndex == _currentStageIndex;
                      return _stepDot(
                          stage, isDone, isCurrent, stageIndex);
                    }),
                  ),
          ),
          Divider(height: 1, thickness: 1, color: _border),
        ],
      ),
    );
  }

  Widget _stepDot(
      TaskStatus stage, bool isDone, bool isCurrent, int index) {
    Color dotColor;
    Color dotBg;
    if (isDone) {
      dotColor = _surface;
      dotBg = _brandBlue;
    } else if (isCurrent) {
      dotColor = _statusColor(stage);
      dotBg = _statusBg(stage);
    } else {
      dotColor = _textMuted;
      dotBg = Color(0xFFF1F5F9);
    }

    return GestureDetector(
      onTap: onStatusChange != null
          ? () => _showStatusChangeDialog(stage)
          : null,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: dotBg,
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: _statusColor(stage), width: 2)
                  : null,
            ),
            child: Center(
              child: isDone
                  ? Icon(Icons.check_rounded,
                      size: 16, color: dotColor)
                  : Icon(_statusIcon(stage),
                      size: 15, color: dotColor),
            ),
          ),
          SizedBox(height: 6),
          Text(
            _shortStageName(stage),
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent
                  ? _statusColor(stage)
                  : isDone
                      ? _brandBlue
                      : _textMuted,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  String _shortStageName(TaskStatus s) {
    switch (s) {
      case TaskStatus.designing:  return 'Design';
      case TaskStatus.printing:   return 'Print';
      case TaskStatus.finishing:  return 'Finish';
      case TaskStatus.installing: return 'Install';
      case TaskStatus.completed:  return 'Done';
      default:                    return s.name;
    }
  }

  Widget _buildCancelledBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_rounded, color: _red, size: 20),
          SizedBox(width: 10),
          Text(
            'This task has been cancelled',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB BAR ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: _surface,
      child: TabBar(
        controller: _tabController,
        labelColor: _brandBlue,
        unselectedLabelColor: _textSecondary,
        indicatorColor: _brandBlue,
        dividerColor: Colors.grey.shade200,
        indicatorWeight: 3,
        labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1),
        unselectedLabelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Production'),
          Tab(text: 'Activity'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — OVERVIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        // Description
        if (task.description.isNotEmpty) ...[
          _sectionTitle('Description'),
          SizedBox(height: 10),
          _card(
            child: Text(
              task.description,
              style: TextStyle(
                fontSize: 14,
                color: _textPrimary,
                height: 1.6,
              ),
            ),
          ),
          SizedBox(height: 24),
        ],

        // Key Dates
        _sectionTitle('Key Dates'),
        SizedBox(height: 10),
        _card(
          child: Column(
            children: [
              if (task.dueDate != null)
                _detailRow(
                  icon: Icons.event_rounded,
                  label: 'Due Date',
                  value: DateFormat('MMM dd, yyyy')
                      .format(task.dueDate!),
                  valueColor: _isOverdue
                      ? _red
                      : _isDueSoon
                          ? _amber
                          : null,
                  badge: _isOverdue
                      ? 'Overdue'
                      : _isDueSoon
                          ? 'Due Soon'
                          : null,
                  badgeColor: _isOverdue ? _red : _amber,
                ),
              if (task.dateCompleted != null)
                _detailRow(
                  icon: Icons.check_circle_rounded,
                  label: 'Completed',
                  value: DateFormat('MMM dd, yyyy')
                      .format(task.dateCompleted!),
                  valueColor: _green,
                ),
              if (task.updatedAt != null)
                _detailRow(
                  icon: Icons.update_rounded,
                  label: 'Last Updated',
                  value: DateFormat('MMM dd, yyyy · HH:mm')
                      .format(task.updatedAt!),
                  isLast: true,
                ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Assignees
        // _sectionTitle('Assignees',
        //     trailing: '${task.assignees.length} members'),
        // SizedBox(height: 10),
        // _card(
        //   child: task.assignees.isEmpty
        //       ? _emptyInlineState(
        //           Icons.person_add_outlined,
        //           'No assignees yet',
        //         )
        //       : Column(
        //           children: [
        //             ...(_showAllAssignees
        //                     ? task.assignees
        //                     : task.assignees.take(4).toList())
        //                 .asMap()
        //                 .entries
        //                 .map((e) {
        //               final isLast = e.key ==
        //                   ((_showAllAssignees
        //                           ? task.assignees
        //                           : task.assignees.take(4))
        //                       .length -
        //                       1);
        //               final profile = task.assignees
        //                   .firstWhere(
        //                 (p) => p['id'] == e.value,
        //                 orElse: () => {
        //                   'id': e.value,
        //                   'name': 'User ${e.value}'
        //                 },
        //               );
        //               return _assigneeRow(profile, isLast);
        //             }).toList(),
        //             if (task.assignees.length > 4)
        //               GestureDetector(
        //                 onTap: () => setState(
        //                     () => _showAllAssignees =
        //                         !_showAllAssignees),
        //                 child: Padding(
        //                   padding: EdgeInsets.only(top: 12),
        //                   child: Row(
        //                     mainAxisAlignment:
        //                         MainAxisAlignment.center,
        //                     children: [
        //                       Text(
        //                         _showAllAssignees
        //                             ? 'Show less'
        //                             : 'Show all ${task.assignees.length} assignees',
        //                         style: TextStyle(
        //                           fontSize: 13,
        //                           fontWeight: FontWeight.w600,
        //                           color: _brandBlue,
        //                         ),
        //                       ),
        //                       SizedBox(width: 4),
        //                       Icon(
        //                         _showAllAssignees
        //                             ? Icons.keyboard_arrow_up
        //                             : Icons.keyboard_arrow_down,
        //                         size: 18,
        //                         color: _brandBlue,
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //               ),
        //           ],
        //         ),
        // ),
        // SizedBox(height: 24),

        // Progress Logs
        if (progressLogs.isNotEmpty) ...[
          _sectionTitle('Progress Logs',
              trailing: '${progressLogs.length}'),
          SizedBox(height: 10),
          _card(
            child: Column(
              children: progressLogs
                  .asMap()
                  .entries
                  .map((e) => _progressLogRow(
                        e.value,
                        isLast:
                            e.key == progressLogs.length - 1,
                      ))
                  .toList(),
            ),
          ),
          SizedBox(height: 24),
        ],
      ],
    );
  }

  // Widget _assigneeRow(Map<String, dynamic> profile, bool isLast) {
  //   final name = profile['name'] as String? ?? 'Unknown';
  //   final initials = name
  //       .split(' ')
  //       .take(2)
  //       .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
  //       .join();
  //   final colors = [
  //     Color(0xFF2563EB),
  //     Color(0xFF10B981),
  //     Color(0xFF8B5CF6),
  //     Color(0xFFF59E0B),
  //     Color(0xFF06B6D4),
  //   ];
  //   final avatarColor = colors[name.codeUnitAt(0) % colors.length];

  //   return Padding(
  //     padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 36,
  //           height: 36,
  //           decoration: BoxDecoration(
  //             color: avatarColor.withOpacity(0.15),
  //             shape: BoxShape.circle,
  //           ),
  //           child: Center(
  //             child: Text(
  //               initials,
  //               style: TextStyle(
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.w700,
  //                 color: avatarColor,
  //               ),
  //             ),
  //           ),
  //         ),
  //         SizedBox(width: 12),
  //         Expanded(
  //           child: Text(
  //             name,
  //             style: TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w500,
  //               color: _textPrimary,
  //             ),
  //           ),
  //         ),
  //         Text(
  //           profile['role'] as String? ?? '',
  //           style: TextStyle(fontSize: 12, color: _textMuted),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _progressLogRow(ProgressLog log, {bool isLast = false}) {
    final note = log.description ?? '';
    // final author = log.createdBy ?? 'Unknown';
    final date = log.startDate as DateTime?;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _brandBlue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note,
                    style: TextStyle(
                        fontSize: 14,
                        color: _textPrimary,
                        height: 1.45)),
                SizedBox(height: 4),
                Row(
                  children: [
                    // TODo
                    Text('Unknown',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary)),
                    if (date != null) ...[
                      Text('  ·  ',
                          style: TextStyle(
                              fontSize: 12, color: _textMuted)),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(date),
                        style: TextStyle(
                            fontSize: 12, color: _textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — PRODUCTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProductionTab() {
    final hasProductionData = task.printerId != null ||
        task.productionDuration > 0 ||
        task.productionQuantity != null;

    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        // Schedule print CTA — shown when not yet scheduled
        if (task.printerId == null &&
            task.status != TaskStatus.completed &&
            task.status != TaskStatus.blocked &&
            onSchedulePrint != null) ...[
          _buildScheduleCta(),
          SizedBox(height: 24),
        ],

        // Printer Assignment
        _sectionTitle('Printer'),
        SizedBox(height: 10),
        _card(
          child: printerInfo != null
              ? Column(
                  children: [
                    _detailRow(
                      icon: Icons.print_rounded,
                      label: 'Printer',
                      value: printerInfo!.name,
                    ),
                    if (printerInfo!.location != null)
                      _detailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Section',
                        value: printerInfo!.location!,
                      ),
                    _detailRow(
                      icon: Icons.circle,
                      label: 'Status',
                      value: printerInfo!.statusName,
                      isLast: true,
                    ),
                  ],
                )
              : _emptyInlineState(
                  Icons.print_disabled_rounded,
                  'No printer assigned',
                  subtitle: task.status == TaskStatus.completed
                      ? null
                      : 'Assign a printer to activate this print job',
                ),
        ),
        SizedBox(height: 24),

        // Production Settings
        _sectionTitle('Production Settings'),
        SizedBox(height: 10),
        _card(
          child: Column(
            children: [
              _detailRow(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: task.productionDuration > 0
                    ? '${task.productionDuration} min'
                    : '—',
              ),
              _detailRow(
                icon: Icons.repeat_rounded,
                label: 'Runs',
                value: (task.runs ?? 1).toString(),
              ),
              _detailRow(
                icon: Icons.inventory_2_outlined,
                label: 'Quantity',
                value: task.productionQuantity != null
                    ? '${task.productionQuantity}'
                    : '—',
              ),
              if (materialInfo != null)
                _detailRow(
                  icon: Icons.category_outlined,
                  label: 'Material',
                  value: materialInfo!.name,
                ),
              if (task.productionStartTime != null)
                _detailRow(
                  icon: Icons.schedule_rounded,
                  label: 'Scheduled Start',
                  value: DateFormat('MMM dd, yyyy · HH:mm')
                      .format(task.productionStartTime!),
                ),
              if (task.stockTransactionBarcode != null)
                _detailRow(
                  icon: Icons.qr_code_rounded,
                  label: 'Barcode',
                  value: task.stockTransactionBarcode!,
                  isLast: true,
                  copyable: true,
                ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Actual Production Timeline
        if (task.actualProductionStartTime != null ||
            task.actualProductionEndTime != null) ...[
          _sectionTitle('Actual Timeline'),
          SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                if (task.actualProductionStartTime != null)
                  _detailRow(
                    icon: Icons.play_circle_outline_rounded,
                    label: 'Started',
                    value: DateFormat('MMM dd, yyyy · HH:mm')
                        .format(task.actualProductionStartTime!),
                    valueColor: _brandBlue,
                  ),
                if (task.actualProductionEndTime != null)
                  _detailRow(
                    icon: Icons.stop_circle_outlined,
                    label: 'Finished',
                    value: DateFormat('MMM dd, yyyy · HH:mm')
                        .format(task.actualProductionEndTime!),
                    valueColor: _green,
                    isLast: true,
                  ),
                // Computed duration
                if (task.actualProductionStartTime != null &&
                    task.actualProductionEndTime != null) ...[
                  Divider(height: 20, thickness: 1, color: _border),
                  _buildActualDurationRow(),
                ],
              ],
            ),
          ),
          SizedBox(height: 24),
        ],

        // Deprecated warning
        if (task.isDeprecated) ...[
          _buildDeprecatedBanner(),
          SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildScheduleCta() {
    return GestureDetector(
      onTap: onSchedulePrint,
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _brandBlue.withOpacity(0.25),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.schedule_rounded,
                  color: Colors.white, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule Print Job',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Assign a printer to activate production',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.7), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActualDurationRow() {
    final diff = task.actualProductionEndTime!
        .difference(task.actualProductionStartTime!);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final label = hours > 0
        ? '${hours}h ${minutes}m'
        : '${minutes}m';
    return Row(
      children: [
        Icon(Icons.access_time_rounded,
            size: 16, color: _textSecondary),
        SizedBox(width: 10),
        Text('Total Duration',
            style: TextStyle(fontSize: 13, color: _textSecondary)),
        Spacer(),
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textPrimary)),
      ],
    );
  }

  Widget _buildDeprecatedBanner() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: _amber, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This task has a printer assigned but is no longer in printing status. It may be deprecated.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3 — ACTIVITY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActivityTab() {
    return activityLogs.isEmpty
        ? Center(
            child: _fullEmptyState(
              Icons.history_rounded,
              'No Activity Yet',
              'Actions and changes to this task will appear here.',
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: activityLogs.length,
            itemBuilder: (_, i) {
              return _activityLogRow(
                activityLogs[i],
                isFirst: i == 0,
                isLast: i == activityLogs.length - 1,
              );
            },
          );
  }

  Widget _activityLogRow(
    WorkActivityLog log, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    // final action = log['action'] as String? ?? '';
    final author = log.userId as String? ?? 'System';
    final date = log.start as DateTime?;

    // IconData actionIcon;
    // Color actionColor;
    // if (action.contains('status')) {
    //   actionIcon = Icons.swap_horiz_rounded;
    //   actionColor = _brandBlue;
    // } else if (action.contains('assign')) {
    //   actionIcon = Icons.person_add_outlined;
    //   actionColor = _purple;
    // } else if (action.contains('creat')) {
    //   actionIcon = Icons.add_circle_outline_rounded;
    //   actionColor = _green;
    // } else if (action.contains('delet') || action.contains('remov')) {
    //   actionIcon = Icons.remove_circle_outline_rounded;
    //   actionColor = _red;
    // } else if (action.contains('schedul') || action.contains('print')) {
    //   actionIcon = Icons.print_rounded;
    //   actionColor = _cyan;
    // } else {
    //   actionIcon = Icons.edit_outlined;
    //   actionColor = _textSecondary;
    // }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline spine
          Column(
            children: [
              Container(
                width: 2,
                height: isFirst ? 18 : 0,
                color: Colors.transparent,
              ),
              // Container(
              //   width: 34,
              //   height: 34,
              //   decoration: BoxDecoration(
              //     color: actionColor.withOpacity(0.1),
              //     shape: BoxShape.circle,
              //   ),
              //   child: Center(
              //       child: Icon(actionIcon,
              //           size: 16, color: actionColor)),
              // ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: _border,
                    margin: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  top: isFirst ? 18 : 0,
                  bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   action,
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     color: _textPrimary,
                  //     height: 1.4,
                  //   ),
                  // ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        author,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary,
                        ),
                      ),
                      if (date != null) ...[
                        Text('  ·  ',
                            style: TextStyle(
                                fontSize: 12, color: _textMuted)),
                        Text(
                          DateFormat('MMM dd, HH:mm').format(date),
                          style: TextStyle(
                              fontSize: 12, color: _textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM BAR ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final canSchedule = task.printerId == null &&
        task.status != TaskStatus.completed &&
        task.status != TaskStatus.blocked;

    final canChangeStatus = currentUser.role == "admin" &&
        task.status != TaskStatus.completed &&
        task.status != TaskStatus.blocked;

    if (!canSchedule && !canChangeStatus) {
      return SizedBox.shrink();
    }

    return Container(
      color: _surface,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (canChangeStatus) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showStatusMenu(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    side: BorderSide(color: _border, width: 1.5),
                  ),
                  icon: Icon(Icons.swap_horiz_rounded,
                      size: 19, color: _textSecondary),
                  label: Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                    ),
                  ),
                ),
              ),
              if (canSchedule) SizedBox(width: 12),
            ],
            if (canSchedule)
              Expanded(
                flex: canChangeStatus ? 1 : 1,
                child: ElevatedButton.icon(
                  onPressed: onSchedulePrint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    elevation: 0,
                  ),
                  icon: Icon(Icons.print_rounded, size: 19),
                  label: Text(
                    'Schedule Print',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
    Color? valueColor,
    String? badge,
    Color? badgeColor,
    bool copyable = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _textSecondary),
          SizedBox(width: 10),
          Text(
            label,
            style:
                TextStyle(fontSize: 13, color: _textSecondary),
          ),
          Spacer(),
          if (badge != null && badgeColor != null) ...[
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? _textPrimary,
            ),
          ),
          if (copyable) ...[
            SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(children: [
                      Icon(Icons.check_circle,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('Copied to clipboard'),
                    ]),
                    backgroundColor: _green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child:
                  Icon(Icons.copy_outlined, size: 15, color: _textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyInlineState(IconData icon, String label,
      {String? subtitle}) {
    return Column(
      children: [
        Icon(icon, size: 32, color: _textMuted),
        SizedBox(height: 10),
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textSecondary)),
        if (subtitle != null) ...[
          SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _textMuted)),
        ],
      ],
    );
  }

  Widget _fullEmptyState(
      IconData icon, String title, String subtitle) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: _textMuted),
        ),
        SizedBox(height: 20),
        Text(title,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                letterSpacing: -0.3)),
        SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: _textSecondary, height: 1.5)),
        ),
      ],
    );
  }

  // ── DIALOGS ────────────────────────────────────────────────────────────────
  void _showStatusMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Update Status',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3)),
            SizedBox(height: 16),
            ..._stages.map((s) => _statusOption(s)).toList(),
            SizedBox(height: 4),
            _statusOption(TaskStatus.blocked, isDanger: true),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(TaskStatus status, {bool isDanger = false}) {
    final isCurrent = task.status == status;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (!isCurrent) _showStatusChangeDialog(status);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isCurrent ? _statusBg(status) : Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: isCurrent ? _statusColor(status) : _border,
              width: isCurrent ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _statusBg(status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_statusIcon(status),
                  size: 16, color: _statusColor(status)),
            ),
            SizedBox(width: 12),
            Text(
              status.name[0].toUpperCase() + status.name.substring(1),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isCurrent
                    ? _statusColor(status)
                    : isDanger
                        ? _red
                        : _textPrimary,
              ),
            ),
            Spacer(),
            if (isCurrent)
              Icon(Icons.check_circle_rounded,
                  size: 18, color: _statusColor(status)),
          ],
        ),
      ),
    );
  }

  void _showStatusChangeDialog(TaskStatus newStatus) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Update Status',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3)),
        content: Text(
          'Change status to "${newStatus.name[0].toUpperCase()}${newStatus.name.substring(1)}"?',
          style: TextStyle(color: _textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onStatusChange?.call(newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _statusColor(newStatus),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirm',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Task',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _red,
                letterSpacing: -0.3)),
        content: Text(
          'Are you sure you want to delete "${task.name}"? This action cannot be undone.',
          style: TextStyle(color: _textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}