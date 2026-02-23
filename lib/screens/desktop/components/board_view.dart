// ─────────────────────────────────────────────────────────────────────────────
// BOARD VIEW
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/desktop/components/task_card.dart';
import 'package:smooflow/screens/desktop/constants.dart';
import 'package:smooflow/screens/desktop/data/design_stage_info.dart';

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

class BoardView extends StatelessWidget {
  final List<Task> tasks;
  final List<Project> projects;
  final int? selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  final VoidCallback onAddTask;
  final FocusNode addTaskFocusNode;
  bool isAddingTask;
  final String? selectedProjectId;

  BoardView({required this.tasks, required this.projects, required this.selectedTaskId, required this.onTaskSelected, required this.onAddTask, required this.addTaskFocusNode, required this.isAddingTask, required this.selectedProjectId});

  @override
  Widget build(BuildContext context) {

    return Container(
      color: _T.slate50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        children: kStages.map((si) {
          final stageTasks = tasks.where((t) => t.status == si.stage).toList();
          return _KanbanLane(
            stageInfo: si,
            tasks: stageTasks,
            projects: projects,
            selectedTaskId: selectedTaskId,
            onTaskSelected: onTaskSelected,
            showAddTaskBtn: si.label == "Initialized",
            addTaskFocusNode: kStages.indexOf(si) == 0? addTaskFocusNode : null,
            isAddingTask: kStages.indexOf(si) == 0? isAddingTask : null,
            selectedProjectId: selectedProjectId
            // Only allow adding from Initialized lane
            // onAddTask: si.stage == TaskStatus.pending ? onAddTask : null,
          );
        }).toList(),
      ),
    );
  }
}

class _KanbanLane extends ConsumerStatefulWidget {
  final DesignStageInfo stageInfo;
  final List<Task> tasks;
  final List<Project> projects;
  final int? selectedTaskId;
  final ValueChanged<int> onTaskSelected;
  final bool showAddTaskBtn;
  // final VoidCallback? onAddTask;
  final FocusNode? addTaskFocusNode;
  bool? isAddingTask;
  String? selectedProjectId;

  _KanbanLane({required this.stageInfo, required this.tasks, required this.projects, required this.selectedTaskId, required this.onTaskSelected, required this.showAddTaskBtn, required this.addTaskFocusNode, required this.isAddingTask, required this.selectedProjectId});

  @override
  ConsumerState<_KanbanLane> createState() => _KanbanLaneState();
}

class _KanbanLaneState extends ConsumerState<_KanbanLane> {

  String? newTaskName;

  void onAddTask() {
    print("can request focus: ${widget.addTaskFocusNode?.canRequestFocus}");

    widget.addTaskFocusNode?.requestFocus();
    setState(() {
      widget.isAddingTask = true;
    });    
  }

  void onDismiss() {
    setState(() {
      widget.isAddingTask = false;
    });
  }

  void onCreated(Task task) {
    setState(() {
      widget.isAddingTask = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.stageInfo.stage == TaskStatus.clientApproved;

    print("widget.addTaskFocusNode!.hasFocus: ${widget.addTaskFocusNode?.hasFocus}");

    return Container(
      width: 258,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: _T.white,
        border: Border.all(color: _T.slate200),
        borderRadius: BorderRadius.circular(_T.rLg),
      ),
      child: Column(
        children: [
          // Lane header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _T.slate100))),
            child: Row(
              children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: widget.stageInfo.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.stageInfo.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _T.ink))),
                if (isApproved) ...[
                  Icon(Icons.lock_outline, size: 12, color: widget.stageInfo.color),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isApproved ? widget.stageInfo.bg : _T.slate100,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('${widget.tasks.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isApproved ? widget.stageInfo.color : _T.slate500)),
                ),
              ],
            ),
          ),

          // Cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                if (widget.tasks.isEmpty)
                  _LaneEmpty()
                else
                  ...widget.tasks.map((t) {
                    final proj = widget.projects.cast<Project?>().firstWhere((p) => p!.id == t.projectId, orElse: () => null) ?? widget.projects.first;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskCard(
                        task: t,
                        project: proj,
                        isSelected: widget.selectedTaskId == t.id,
                        onTap: () => widget.onTaskSelected(t.id),
                        selectedProjectId: widget.selectedProjectId
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Add button (Initialized lane only)
          if (widget.showAddTaskBtn)
            if (widget.isAddingTask == true) Focus(
              focusNode: widget.addTaskFocusNode,
              autofocus: true,
              child: TaskCard.add(
                onCreated: onCreated,
                onDismiss: onDismiss,
                projects: ref.watch(projectNotifierProvider),
                selectedProjectId: widget.selectedProjectId
              ),
            )
            else Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: _AddCardButton(onTap: onAddTask),
              ),
          
        ],
      ),
    );
  }
}

class _LaneEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(Icons.assignment_outlined, size: 28, color: _T.slate300),
        SizedBox(height: 8),
        Text('No tasks here', style: TextStyle(fontSize: 12, color: _T.slate300)),
      ],
    ),
  );
}

class _AddCardButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCardButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_T.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_T.r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: _T.slate200, width: 1.5),
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 13, color: _T.slate400),
              SizedBox(width: 6),
              Text('Add task', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: _T.slate400)),
            ],
          ),
        ),
      ),
    );
  }
}