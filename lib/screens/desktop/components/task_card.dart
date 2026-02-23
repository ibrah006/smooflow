// ─────────────────────────────────────────────────────────────────────────────
// TASK CARD
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/micro_widgets.dart';
import 'package:smooflow/screens/desktop/components/priority_chip_row.dart';
import 'package:smooflow/screens/desktop/components/priority_pill.dart';
import 'package:smooflow/screens/desktop/components/project_chip_row.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (identical to your _T class in design_dashboard.dart)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue      = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100   = Color(0xFFDBEAFE);
  static const blue50    = Color(0xFFEFF6FF);
  static const teal      = Color(0xFF38BDF8);

  static const green     = Color(0xFF10B981);
  static const green50   = Color(0xFFECFDF5);
  static const amber     = Color(0xFFF59E0B);
  static const amber50   = Color(0xFFFEF3C7);
  static const red       = Color(0xFFEF4444);
  static const red50     = Color(0xFFFEE2E2);
  static const purple    = Color(0xFF8B5CF6);
  static const purple50  = Color(0xFFF3E8FF);

  static const slate50   = Color(0xFFF8FAFC);
  static const slate100  = Color(0xFFF1F5F9);
  static const slate200  = Color(0xFFE2E8F0);
  static const slate300  = Color(0xFFCBD5E1);
  static const slate400  = Color(0xFF94A3B8);
  static const slate500  = Color(0xFF64748B);
  static const ink       = Color(0xFF0F172A);
  static const ink2      = Color(0xFF1E293B);
  static const ink3      = Color(0xFF334155);
  static const white     = Colors.white;

  static const sidebarW = 220.0;
  static const topbarH  = 52.0;
  static const detailW  = 400.0;

  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class TaskCard extends ConsumerStatefulWidget {
  // ── normal card fields ────────────────────────────────────────────────────
  final Task? task;
  final Project? project;
  final bool isSelected;
  final VoidCallback? onTap;

  // ── creation card fields ──────────────────────────────────────────────────
  final bool isAddTask;
  final List<Project> addProjects;
  final void Function(Task)? onCreated;
  final VoidCallback? onDismiss;

  final String? selectedProjectId;

  // Normal card
  const TaskCard({
    required Task task,
    required Project project,
    required this.isSelected,
    required this.onTap,
    required this.selectedProjectId
  })  : task = task,
        project = project,
        isAddTask = false,
        addProjects = const [],
        onCreated = null,
        onDismiss = null;

  // Creation card
  const TaskCard.add({
    required List<Project> projects,
    required void Function(Task) onCreated,
    required VoidCallback onDismiss,
    required this.selectedProjectId
  })  : task = null,
        project = null,
        isSelected = false,
        onTap = null,
        isAddTask = true,
        addProjects = projects,
        onCreated = onCreated,
        onDismiss = onDismiss;

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard>
    with SingleTickerProviderStateMixin {
  // ── creation-card state ───────────────────────────────────────────────────
  final _nameCtrl    = TextEditingController();
  final _nameFocus   = FocusNode();
  late String?        _selectedProjectId;
  TaskPriority       _selectedPriority = TaskPriority.normal;
  bool               _showProjectPicker = false;
  bool               _nameTouched = false;

  /// only for _buildCreationCard
  bool _isLoading = false;

  // ── animation ─────────────────────────────────────────────────────────────
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _fadeIn =
      CurvedAnimation(parent: _ac, curve: Curves.easeOut);
  late final Animation<Offset> _slideIn = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));

  final popupKey = GlobalKey<CustomPopupState>();

  @override
  void initState() {
    super.initState();
    if (widget.isAddTask) {
      _selectedProjectId =
          widget.selectedProjectId?? (widget.addProjects.isNotEmpty? widget.addProjects.first.id : null);
      // Auto-focus the name field after the card animates in
      _ac.forward().then((_) {
        if (mounted) _nameFocus.requestFocus();
      });
      _nameCtrl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _ac.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  Color get _priorityColor => switch (widget.task?.priority ?? _selectedPriority) {
    TaskPriority.urgent => _T.red,
    TaskPriority.high   => _T.amber,
    TaskPriority.normal => _T.slate200,
  };

  Project? get _currentProject => widget.addProjects.cast<Project?>()
      .firstWhere((p) => p!.id == _selectedProjectId, orElse: () => null);

  bool get _canSubmit => _nameCtrl.text.trim().isNotEmpty && _currentProject != null;

  void _submit() async {
    if (!_canSubmit) {
      setState(() => _nameTouched = true);
      _nameFocus.requestFocus();

      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      final newTask = Task.create(
        name: _nameCtrl.text,
        description: "",
        dueDate: null,
        assignees: [],
        projectId: _selectedProjectId!,
        priority: _selectedPriority
      );

      await ref.read(createProjectTaskProvider(newTask));
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to create task, e: ${e.toString()}")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _dismiss() => widget.onDismiss?.call();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (widget.isAddTask) return _buildCreationCard();
    return _buildNormalCard();
  }

  // ── NORMAL CARD ───────────────────────────────────────────────────────────
  Widget _buildNormalCard() {
    final task    = widget.task!;
    final project = widget.project!;
    final d       = task.dueDate;
    final now     = DateTime.now();
    final isOverdue = d != null && d.isBefore(now);
    final isSoon    = d != null && !isOverdue && d.difference(now).inDays <= 3;

    Member? member;
    try {
      member = ref.watch(memberNotifierProvider).members
          .firstWhere((m) => task.assignees.contains(m.id));
    } catch (_) {
      member = null;
    }

    return Material(
      color: _T.white,
      borderRadius: BorderRadius.circular(_T.r),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(_T.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isSelected ? _T.blue : _T.slate200,
              width: widget.isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(_T.r),
            boxShadow: widget.isSelected
                ? [BoxShadow(color: _T.blue.withOpacity(0.12), blurRadius: 8, spreadRadius: 1)]
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Priority accent bar — animates colour change
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 3,
                  margin: widget.isSelected ? const EdgeInsets.all(2) : null,
                  decoration: BoxDecoration(
                    color: _priorityColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(_T.r),
                      bottomLeft: Radius.circular(_T.r),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _T.ink,
                                height: 1.4)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: project.color,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(project.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: _T.slate400)),
                          ),
                        ]),
                        const SizedBox(height: 9),
                        Row(children: [
                          PriorityPill(priority: task.priority),
                          const SizedBox(width: 6),
                          if (member != null)
                            AvatarWidget(
                                initials: member.initials,
                                color: member.color,
                                size: 20),
                          const Spacer(),
                          if (d != null)
                            Row(children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 10,
                                  color: isOverdue
                                      ? _T.red
                                      : isSoon
                                          ? _T.amber
                                          : _T.slate400),
                              const SizedBox(width: 4),
                              Text(fmtDate(d),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isOverdue || isSoon
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isOverdue
                                          ? _T.red
                                          : isSoon
                                              ? _T.amber
                                              : _T.slate400)),
                            ]),
                        ]),
                      ],
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

  // ── CREATION CARD ─────────────────────────────────────────────────────────
  Widget _buildCreationCard() {

    final projects = ref.watch(projectNotifierProvider);

    final bool nameEmpty = _nameCtrl.text.trim().isEmpty;
    final bool showError = _nameTouched && nameEmpty;

    late final Project? p;
    try {
      p = projects.firstWhere((p)=> p.id == _selectedProjectId);
    } catch(e) {
      p = null;
    }

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.escape) _dismiss();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: _T.white,
              border: Border.all(
                color: _T.blue.withOpacity(0.45),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(_T.rLg),
              boxShadow: [
                BoxShadow(
                  color: _T.blue.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Animated priority accent bar ──────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentForPriority(_selectedPriority),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(_T.rLg),
                      bottomLeft: Radius.circular(_T.rLg),
                    ),
                  ),
                ),
                
                // ── Card body ─────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                
                        // ── Project picker ────────────────────────────
                
                        if (widget.selectedProjectId == null) ... [
                          ProjectChipRow(
                            projects: projects,
                            selectedId: _selectedProjectId,
                            onChanged: (projectId) {
                              setState(() {
                                _selectedProjectId = projectId;
                              });
                            },
                            disabled: _isLoading
                          ),
                          const SizedBox(height: 18),
                        ],
                
                        // ── Priority picker ───────────────────────────
                        PriorityRadioRow(
                          selected: _selectedPriority,
                          onChanged: (p) =>
                              setState(() => _selectedPriority = p),
                          disabled: _isLoading
                        ),
                        const SizedBox(height: 10),
    
                        // ── Task name input ───────────────────────────
                        TextField(
                          enabled: !_isLoading,
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _T.ink,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Task name…',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _T.slate300,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            errorText: showError ? 'Name required' : null,
                            errorStyle: const TextStyle(fontSize: 10.5, height: 1.2),
                            suffixIconConstraints: _isLoading? BoxConstraints.tight(Size(20, 20)) : null,
                            suffixIcon: _isLoading? CircularProgressIndicator(strokeWidth: 2.5) : null
                          ),
                          onSubmitted: (_) => _submit(),
                          textInputAction: TextInputAction.done,
                        ),
                        if (_isLoading) Text("Creating Task...", style: TextStyle(
                          fontSize: 12,
                          color: _T.blue,
                          fontWeight: FontWeight.w500
                        ))
                
                        // ── Actions ───────────────────────────────────
                        // Row(
                        //   children: [
                        //     // Submit
                        //     Expanded(
                        //       child: GestureDetector(
                        //         onTap: _submit,
                        //         child: AnimatedContainer(
                        //           duration: const Duration(milliseconds: 160),
                        //           padding: const EdgeInsets.symmetric(
                        //               vertical: 7),
                        //           decoration: BoxDecoration(
                        //             color: _canSubmit
                        //                 ? _T.blue
                        //                 : _T.slate200,
                        //             borderRadius:
                        //                 BorderRadius.circular(_T.r),
                        //           ),
                        //           child: Row(
                        //             mainAxisAlignment:
                        //                 MainAxisAlignment.center,
                        //             children: [
                        //               Icon(
                        //                 Icons.add_rounded,
                        //                 size: 14,
                        //                 color: _canSubmit
                        //                     ? Colors.white
                        //                     : _T.slate400,
                        //               ),
                        //               const SizedBox(width: 5),
                        //               Text(
                        //                 'Add task',
                        //                 style: TextStyle(
                        //                   fontSize: 12.5,
                        //                   fontWeight: FontWeight.w700,
                        //                   color: _canSubmit
                        //                       ? Colors.white
                        //                       : _T.slate400,
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //     const SizedBox(width: 7),
                        //     // Dismiss
                        //     GestureDetector(
                        //       onTap: _dismiss,
                        //       child: Container(
                        //         width: 30,
                        //         height: 30,
                        //         decoration: BoxDecoration(
                        //           border:
                        //               Border.all(color: _T.slate200),
                        //           borderRadius:
                        //               BorderRadius.circular(_T.r),
                        //         ),
                        //         child: const Icon(Icons.close_rounded,
                        //             size: 14, color: _T.slate400),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
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