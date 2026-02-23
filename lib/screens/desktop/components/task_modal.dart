// ── Task Modal ────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/member.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/providers/member_provider.dart';
import 'package:smooflow/screens/desktop/components/avatar_widget.dart';
import 'package:smooflow/screens/desktop/components/modal_components.dart';
import 'package:smooflow/screens/desktop/components/modal_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Brand
  static const blue       = Color(0xFF2563EB);
  static const blueHover  = Color(0xFF1D4ED8);
  static const blue100    = Color(0xFFDBEAFE);
  static const blue50     = Color(0xFFEFF6FF);
  static const teal       = Color(0xFF38BDF8);

  // Semantic
  static const green      = Color(0xFF10B981);
  static const green50    = Color(0xFFECFDF5);
  static const amber      = Color(0xFFF59E0B);
  static const amber50    = Color(0xFFFEF3C7);
  static const red        = Color(0xFFEF4444);
  static const red50      = Color(0xFFFEE2E2);
  static const purple     = Color(0xFF8B5CF6);
  static const purple50   = Color(0xFFF3E8FF);

  // Neutrals
  static const slate50    = Color(0xFFF8FAFC);
  static const slate100   = Color(0xFFF1F5F9);
  static const slate200   = Color(0xFFE2E8F0);
  static const slate300   = Color(0xFFCBD5E1);
  static const slate400   = Color(0xFF94A3B8);
  static const slate500   = Color(0xFF64748B);
  static const ink        = Color(0xFF0F172A);
  static const ink2       = Color(0xFF1E293B);
  static const ink3       = Color(0xFF334155);
  static const white      = Colors.white;

  // Dimensions
  static const sidebarW  = 220.0;
  static const topbarH   = 52.0;
  static const detailW   = 400.0;

  // Radius
  static const r   = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class TaskModal extends ConsumerStatefulWidget {
  final List<Project> projects;
  final String? preselectedProjectId;
  final int nextId;

  const TaskModal({required this.projects, this.preselectedProjectId, required this.nextId});

  @override
  ConsumerState<TaskModal> createState() => _TaskModalState();
}

class _TaskModalState extends ConsumerState<TaskModal> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  late String? _projectId;
  String? _assigneeId;
  DateTime? _due;
  TaskPriority _priority = TaskPriority.normal;
  bool _saving = false;

  bool _autoProgress = false;

  @override
  void initState() {
    super.initState();
    _projectId = widget.preselectedProjectId;
  }

  @override
  void dispose() { _name.dispose(); _desc.dispose(); super.dispose(); }

  List<Member> get _members => ref.watch(memberNotifierProvider).members;

  Future<void> _submit() async {
    // if (_name.text.trim().isEmpty || _projectId == null) return;
    // setState(() => _saving = true);

    // final assignees = _assigneeId != null ? [_assigneeId!] : <String>[];

    // try {
    //   final newTask = Task.create(
    //     name: _name.text.trim(),
    //     description: _desc.text.trim(),
    //     dueDate: null,
    //     assignees: assignees,
    //     projectId: _projectId!,
    //   );

    //   await ref.read(createProjectTaskProvider(newTask));

    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Task created")));
    // } catch(e) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to create Task")));
    // }
    // setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    
    return ModalShell(
      icon: Icons.assignment_outlined,
      iconColor: _T.blue,
      title: 'New Task',
      subtitle: 'Initializes in the Initialized stage',
      onClose: () => Navigator.pop(context),
      onSave: _saving ? null : _submit,
      saveLabel: _saving ? 'Creating…' : 'Create Task',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ModalField(
          label: 'Task Name', required: true,
          child: ModalInput(ctrl: _name, hint: 'e.g. Hero banner — Spring campaign'),
        ),
        const SizedBox(height: 16),
        ModalField(
          label: 'Description',
          child: ModalTextarea(ctrl: _desc, hint: 'Deliverable details, dimensions, notes…'),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ModalField(
            label: 'Project', required: true,
            child: ModalDropdown<String?>(
              value: _projectId,
              items: widget.projects.map((p) => DropdownMenuItem(
                value: p.id,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(p.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  ]
                ),
              )).toList(),
              onChanged: (v) => setState(() => _projectId = v!),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: ModalField(
            label: 'Assign To',
            child: _members.isEmpty
                ? const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : ModalDropdown<String?>(
                    value: _assigneeId,
                    items: _members.map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Row(children: [
                        AvatarWidget(initials: m.initials, color: m.color, size: 20),
                        const SizedBox(width: 8),
                        Text(m.name, style: const TextStyle(fontSize: 13)),
                      ]),
                    )).toList(),
                    onChanged: (v) => setState(() => _assigneeId = v),
                  ),
          )),
        ]),
        const SizedBox(height: 16),
        // ModalField(
        //   label: "Workflow Settings",
        //   child: Container(
        //     padding: const EdgeInsets.all(16),
        //     decoration: BoxDecoration(
        //       color: _autoProgress
        //           ? _T.blue.withOpacity(0.05)
        //           : const Color(0xFFF8FAFC),
        //       borderRadius: BorderRadius.circular(12),
        //       border: Border.all(
        //         color: _autoProgress
        //             ? _T.blue.withOpacity(0.3)
        //             : const Color(0xFFE2E8F0),
        //         width: _autoProgress ? 2 : 1,
        //       ),
        //     ),
        //     child: Row(
        //       children: [
        //         Container(
        //           padding: const EdgeInsets.all(8),
        //           decoration: BoxDecoration(
        //             color: _autoProgress
        //                 ? _T.blue.withOpacity(0.15)
        //                 : Colors.grey.shade200,
        //             borderRadius: BorderRadius.circular(8),
        //           ),
        //           child: Icon(
        //             Icons.auto_awesome_rounded,
        //             size: 20,
        //             color: _autoProgress
        //                 ? _T.blue
        //                 : Colors.grey.shade500,
        //           ),
        //         ),
        //         const SizedBox(width: 12),
        //         Expanded(
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: [
        //               const Text(
        //                 'Auto-progress',
        //                 style: TextStyle(
        //                   fontSize: 14,
        //                   fontWeight: FontWeight.w600,
        //                   color: Color(0xFF0F172A),
        //                 ),
        //               ),
        //               const SizedBox(height: 2),
        //               Text(
        //                 'Move to next stage automatically',
        //                 style: TextStyle(
        //                   fontSize: 12,
        //                   color: Colors.grey.shade600,
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //         Switch(
        //           value: _autoProgress,
        //           onChanged: (value) {
        //             setState(() {
        //               _autoProgress = value;
        //             });
        //           },
        //           activeColor: _T.blue,
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
        // const SizedBox(height: 16),
        // Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        //   Expanded(child: ModalField(
        //     label: 'Due Date',
        //     child: GestureDetector(
        //       onTap: () async {
        //         final d = await showDatePicker(
        //           context: context,
        //           initialDate: DateTime.now().add(const Duration(days: 7)),
        //           firstDate: DateTime.now(), lastDate: DateTime(2028),
        //           builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _T.blue)), child: child!),
        //         );
        //         if (d != null) setState(() => _due = d);
        //       },
        //       child: Container(
        //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        //         decoration: BoxDecoration(color: _T.slate50, border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
        //         child: Row(children: [
        //           const Icon(Icons.calendar_today_outlined, size: 14, color: _T.slate400),
        //           const SizedBox(width: 8),
        //           Text(_due != null ? fmtDate(_due!) : 'Select date', style: TextStyle(fontSize: 13, color: _due != null ? _T.ink : _T.slate400)),
        //         ]),
        //       ),
        //     ),
        //   )),
        //   const SizedBox(width: 12),
        //   Expanded(child: ModalField(
        //     label: 'Priority',
        //     child: ModalDropdown<TaskPriority>(
        //       value: _priority,
        //       items: TaskPriority.values.map((p) => DropdownMenuItem(
        //         value: p,
        //         child: Text(_priorityLabel(p), style: const TextStyle(fontSize: 13)),
        //       )).toList(),
        //       onChanged: (v) => setState(() => _priority = v!),
        //     ),
        //   )),
        // ]),
      ]),
    );
  }
}