// ─────────────────────────────────────────────────────────────────────────────
// create_task_screen.dart
//
// Full-page desktop task creation screen.
//
// LAYOUT
// ──────
//   Topbar (58 px, white, slate200 bottom border)
//   └── Body: horizontal split
//       ├── LEFT  (flexible)  — form, scrollable, 3 section-cards
//       └── RIGHT (320 px)    — live summary panel, updates on every keystroke
//
// FIELDS
// ──────
//   Required:
//     • Task name
//     • Project        (dropdown, pre-populated from initialProject)
//     • Priority       (3-chip inline picker: Urgent / High / Normal)
//
//   Optional:
//     • Reference (Ref)
//     • Size  W × H cm (two number inputs side-by-side)
//     • Quantity        (only enabled when both W and H are filled in)
//
// RULES
// ─────
//   • Qty is disabled + visually ghosted until size has non-zero values
//   • When size is cleared, Qty is also cleared automatically
//   • Validation runs on submit; fields are not nagged while pristine
//   • Save button shows inline spinner while creating
//
// DESIGN SYSTEM
// ─────────────
//   Token class _T, _SectionCard anatomy, _SmooField focus-border,
//   _FieldLabel, FilledButton / OutlinedButton buttons — all identical
//   to printer_screen.dart, invite_member_screen.dart, clients_screen.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue      = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100   = Color(0xFFDBEAFE);
  static const blue50    = Color(0xFFEFF6FF);
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
  static const r         = 8.0;
  static const rLg       = 12.0;
  static const rXl       = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY METADATA
// ─────────────────────────────────────────────────────────────────────────────
class _PriMeta {
  final TaskPriority value;
  final String       label;
  final String       sub;
  final Color        color, bg;
  final IconData     icon;
  const _PriMeta({
    required this.value, required this.label, required this.sub,
    required this.color, required this.bg,    required this.icon,
  });
}

const _kPriorities = [
  _PriMeta(
    value: TaskPriority.urgent, label: 'Urgent', sub: 'Needs immediate attention',
    color: _T.red,    bg: _T.red50,
    icon: Icons.local_fire_department_outlined,
  ),
  _PriMeta(
    value: TaskPriority.high,   label: 'High',   sub: 'Important, soon',
    color: _T.amber,  bg: _T.amber50,
    icon: Icons.keyboard_double_arrow_up_rounded,
  ),
  _PriMeta(
    value: TaskPriority.normal, label: 'Normal', sub: 'Standard queue',
    color: _T.slate500, bg: _T.slate100,
    icon: Icons.remove_rounded,
  ),
];

_PriMeta _priMeta(TaskPriority p) =>
    _kPriorities.firstWhere((m) => m.value == p);

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DesignCreateTaskScreen extends ConsumerStatefulWidget {
  /// Pre-selected project — null means "no pre-selection".
  final String? initialProject;

  const DesignCreateTaskScreen({super.key, this.initialProject});

  @override
  ConsumerState<DesignCreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<DesignCreateTaskScreen> {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _refCtrl  = TextEditingController();
  final _wCtrl    = TextEditingController();
  final _hCtrl    = TextEditingController();
  final _qtyCtrl  = TextEditingController();

  // ── Form state ─────────────────────────────────────────────────────────────
  Project?      _project;
  TaskPriority? _priority;
  bool          _submitted = false;   // true → show validation errors
  bool          _saving    = false;

  // ── Derived ────────────────────────────────────────────────────────────────
  bool get _hasSize {
    final w = double.tryParse(_wCtrl.text.trim()) ?? 0;
    final h = double.tryParse(_hCtrl.text.trim()) ?? 0;
    return w > 0 && h > 0;
  }

  bool get _nameOk     => _nameCtrl.text.trim().isNotEmpty;
  bool get _projectOk  => _project != null;
  bool get _priorityOk => _priority != null;
  bool get _formOk     => _nameOk && _projectOk && _priorityOk;

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _project = widget.initialProject!=null? ref.watch(projectByIdProvider(widget.initialProject!)) : null;
    });
    // Rebuild summary on every keystroke
    for (final c in [_nameCtrl, _refCtrl, _wCtrl, _hCtrl, _qtyCtrl]) {
      c.addListener(_onFieldChange);
    }
  }

  void _onFieldChange() {
    // If size is cleared, clear qty too.
    if (!_hasSize && _qtyCtrl.text.isNotEmpty) {
      _qtyCtrl.clear();
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _refCtrl, _wCtrl, _hCtrl, _qtyCtrl]) {
      c.removeListener(_onFieldChange);
      c.dispose();
    }
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formOk) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final reference = _refCtrl.text.trim();

    try {
      final w   = double.tryParse(_wCtrl.text.trim());
      final h   = double.tryParse(_hCtrl.text.trim());
      final qty = int.tryParse(_qtyCtrl.text.trim());

      final newTask = Task.create(
        name: _nameCtrl.text,
        description: "",
        dueDate: null,
        assignees: [],
        projectId: _project!.id,
        priority: _priority?? TaskPriority.normal,
        ref: reference.isEmpty? null : reference,
        size: "$w×${h} cm",
        quantity: qty
      );

      // await ref.read(createProjectTaskProvider(newTask));
      await ref.watch(projectNotifierProvider.notifier).createTask(task: newTask);

      ref.watch(taskNotifierProvider.notifier).loadTaskToMemory(newTask);

      if (mounted) {
        _snack('Task created successfully', isError: false);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('Failed to create task. Please try again.', isError: true);
      }
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          size: 15, color: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ]),
      backgroundColor: _T.ink,
      behavior:        SnackBarBehavior.floating,
      margin:          const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r)),
      duration: const Duration(seconds: 4),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectNotifierProvider);

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(
        children: [
          // ── Topbar ─────────────────────────────────────────────────────
          _Topbar(onBack: () => Navigator.of(context).pop()),

          // ── Body split ────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── LEFT: form ──────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 20, 40),
                    child: ConstrainedBox(
                      // Cap form width so it doesn't stretch absurdly on 4 K
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page heading
                          const Text(
                            'New Task',
                            style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: _T.ink, letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Fill in the task details below. Required fields are marked *.',
                            style: TextStyle(
                                fontSize: 13, color: _T.slate400,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 24),

                          // ── Section 1: Basics ─────────────────────────
                          _SectionCard(
                            icon:      Icons.assignment_outlined,
                            iconColor: _T.blue,
                            iconBg:    _T.blue50,
                            title:     'Task Details',
                            subtitle:  'Name, project and priority',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // Task name
                                _SmooField(
                                  controller: _nameCtrl,
                                  label:      'Task Name',
                                  hint:       'e.g. Banner 3×6m — Grand Opening',
                                  icon:       Icons.drive_file_rename_outline_rounded,
                                  required:   true,
                                  error: _submitted && !_nameOk
                                      ? 'Task name is required'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Project
                                _FieldLabel.required('Project'),
                                const SizedBox(height: 7),
                                _ProjectDropdown(
                                  projects: projects,
                                  value:    _project,
                                  error:    _submitted && !_projectOk,
                                  onChanged: (p) => setState(() => _project = p),
                                ),
                                const SizedBox(height: 16),

                                // Priority
                                _FieldLabel('Priority'),
                                const SizedBox(height: 9),
                                _PriorityPicker(
                                  selected:   _priority,
                                  onSelected: (p) => setState(() => _priority = p),
                                  showError:  _submitted && !_priorityOk,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Section 2: Print Specifications ───────────
                          _SectionCard(
                            icon:      Icons.straighten_outlined,
                            iconColor: _T.purple,
                            iconBg:    _T.purple50,
                            title:     'Print Specifications',
                            subtitle:  'Optional — reference, dimensions and quantity',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // Reference
                                _SmooField(
                                  controller: _refCtrl,
                                  label:      'Reference (Ref)',
                                  hint:       'e.g. PO-2024-0491',
                                  icon:       Icons.tag_rounded,
                                  required:   false,
                                ),
                                const SizedBox(height: 16),

                                // Size row
                                _SizeRow(wCtrl: _wCtrl, hCtrl: _hCtrl),
                                const SizedBox(height: 16),

                                // Quantity
                                _QtyField(
                                  controller: _qtyCtrl,
                                  enabled:    _hasSize,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── RIGHT: summary + action bar ─────────────────────────
                _SummaryPanel(
                  name:     _nameCtrl.text.trim(),
                  project:  _project,
                  priority: _priority,
                  ref:      _refCtrl.text.trim(),
                  sizeW:    _wCtrl.text.trim(),
                  sizeH:    _hCtrl.text.trim(),
                  qty:      _qtyCtrl.text.trim(),
                  saving:   _saving,
                  canSave:  _formOk || !_submitted,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave:   _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPBAR
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final VoidCallback onBack;
  const _Topbar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color:  _T.white,
        border: Border(bottom: BorderSide(color: _T.slate200)),
      ),
      child: Row(children: [
        // Back button
        Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(_T.r),
          child: InkWell(
            onTap:        onBack,
            borderRadius: BorderRadius.circular(_T.r),
            child: Container(
              height: 34, width: 34,
              decoration: BoxDecoration(
                color:  _T.slate100,
                borderRadius: BorderRadius.circular(_T.r),
                border: Border.all(color: _T.slate200),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 17, color: _T.ink3),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Icon + dual-line title
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color:  _T.blue50,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _T.blue.withOpacity(0.2)),
          ),
          child: const Icon(Icons.add_task_rounded, size: 16, color: _T.blue),
        ),
        const SizedBox(width: 12),
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Task',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: _T.ink, letterSpacing: -0.2)),
            Text('New task in the pipeline',
                style: TextStyle(
                  fontSize: 10.5, color: _T.slate400,
                  fontWeight: FontWeight.w500)),
          ],
        ),

        const Spacer(),

        // Breadcrumb-style context label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:        _T.slate100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.view_kanban_outlined, size: 13, color: _T.slate400),
            SizedBox(width: 5),
            Text('Board → New Task',
                style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600,
                  color: _T.slate400)),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD — white card with icon header + slate100 divider + content
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor, iconBg;
  final String   title, subtitle;
  final Widget   child;

  const _SectionCard({
    required this.icon,      required this.iconColor, required this.iconBg,
    required this.title,     required this.subtitle,  required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rXl),
        border: Border.all(color: _T.slate200),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color:        iconBg,
                  borderRadius: BorderRadius.circular(9),
                  border:       Border.all(color: iconColor.withOpacity(0.2)),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: _T.ink, letterSpacing: -0.2)),
                    Text(subtitle,
                        style: const TextStyle(
                          fontSize: 11.5, color: _T.slate400,
                          fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ]),
          ),
          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child:   Divider(height: 1, color: _T.slate100),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child:   child,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectDropdown extends StatelessWidget {
  final List<Project> projects;
  final Project?      value;
  final bool          error;
  final ValueChanged<Project?> onChanged;

  const _ProjectDropdown({
    required this.projects, required this.value,
    required this.error,    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Project>(
      value:         value,
      isExpanded:    true,
      hint: const Text('Select a project',
          style: TextStyle(fontSize: 13, color: _T.slate400)),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          size: 18, color: _T.slate400),
      style: const TextStyle(fontSize: 13, color: _T.ink, fontWeight: FontWeight.w500),
      dropdownColor:  _T.white,
      borderRadius:   BorderRadius.circular(_T.rLg),
      decoration: InputDecoration(
        prefixIcon: value != null? null : Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: value != null
              ? null
              : const Icon(Icons.folder_outlined, size: 15, color: _T.slate400),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 0),
        filled:        true,
        fillColor:     error ? _T.red50 : _T.slate50,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_T.r),
            borderSide: const BorderSide(color: _T.slate200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_T.r),
            borderSide: BorderSide(
                color: error ? _T.red : _T.slate200,
                width: error ? 1.5 : 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_T.r),
            borderSide: const BorderSide(color: _T.blue, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_T.r),
            borderSide: const BorderSide(color: _T.red, width: 1.5)),
        errorText: error ? 'Please select a project' : null,
        errorStyle: const TextStyle(
            fontSize: 11, color: _T.red, fontWeight: FontWeight.w500),
      ),
      items: projects.map((p) => DropdownMenuItem<Project>(
        value: p,
        child: Row(children: [
          const SizedBox(width: 9),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Text(p.name),
        ]),
      )).toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY PICKER — inline chip row (no scroll, 3 options only)
// ─────────────────────────────────────────────────────────────────────────────
class _PriorityPicker extends StatelessWidget {
  final TaskPriority?          selected;
  final ValueChanged<TaskPriority?> onSelected;
  final bool                   showError;

  const _PriorityPicker({
    required this.selected,
    required this.onSelected,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip row
        Row(children: _kPriorities.map((m) {
          final active = selected == m.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: m.value == TaskPriority.normal ? 0 : 8,
              ),
              child: GestureDetector(
                onTap: () => onSelected(active ? null : m.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: active ? m.bg : _T.white,
                    borderRadius: BorderRadius.circular(_T.rLg),
                    border: Border.all(
                      color: active
                          ? m.color.withOpacity(0.5)
                          : (showError ? _T.red.withOpacity(0.4) : _T.slate200),
                      width: active ? 1.5 : 1,
                    ),
                    boxShadow: active
                        ? [BoxShadow(
                            color:      m.color.withOpacity(0.12),
                            blurRadius: 10,
                            offset:     const Offset(0, 3))]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(m.icon, size: 14,
                            color: active ? m.color : _T.slate400),
                        const SizedBox(width: 6),
                        Text(m.label,
                            style: TextStyle(
                              fontSize:   13,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: active ? m.color : _T.ink3,
                            )),
                        if (active) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.check_circle_rounded,
                              size: 13, color: m.color),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      Text(m.sub,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: active
                                ? m.color.withOpacity(0.7)
                                : _T.slate400,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList()),

        // Error message
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: const [
              Icon(Icons.error_outline_rounded, size: 12, color: _T.red),
              SizedBox(width: 4),
              Text('Please select a priority',
                  style: TextStyle(
                      fontSize: 11, color: _T.red, fontWeight: FontWeight.w500)),
            ]),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIZE ROW — W × H cm  (two number inputs + "×" separator + "cm" suffix)
// ─────────────────────────────────────────────────────────────────────────────
class _SizeRow extends StatelessWidget {
  final TextEditingController wCtrl, hCtrl;
  const _SizeRow({required this.wCtrl, required this.hCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Size',
            optional: true, optionalNote: 'Width × Height'),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Width
            Expanded(
              child: _NumField(
                controller: wCtrl,
                hint:       'Width',
                prefix:     Icons.swap_horiz_rounded,
              ),
            ),

            // × separator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('×',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: _T.slate300,
                    height: 1,
                  )),
            ),

            // Height
            Expanded(
              child: _NumField(
                controller: hCtrl,
                hint:       'Height',
                prefix:     Icons.swap_vert_rounded,
              ),
            ),

            // cm suffix badge
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color:        _T.slate100,
                borderRadius: BorderRadius.circular(_T.r),
                border:       Border.all(color: _T.slate200),
              ),
              child: const Text('cm',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      _T.slate500,
                  )),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUANTITY FIELD — gated on size having values
// ─────────────────────────────────────────────────────────────────────────────
class _QtyField extends StatelessWidget {
  final TextEditingController controller;
  final bool                  enabled;
  const _QtyField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const _FieldLabel('Quantity', optional: true),
          const SizedBox(width: 8),
          if (!enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color:        _T.amber50,
                borderRadius: BorderRadius.circular(99),
                border:       Border.all(color: _T.amber.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.straighten_outlined, size: 10, color: _T.amber),
                SizedBox(width: 4),
                Text('Size required first',
                    style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      color:      _T.amber,
                    )),
              ]),
            ),
        ]),
        const SizedBox(height: 7),
        AnimatedOpacity(
          opacity:  enabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: _NumField(
            controller: controller,
            hint:       'e.g. 50',
            prefix:     Icons.inventory_2_outlined,
            enabled:    enabled,
            suffix:     'pcs',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY PANEL (right side)
// Updates live as the user types — the "corporate review" panel.
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryPanel extends StatelessWidget {
  final String       name, ref, sizeW, sizeH, qty;
  final Project?     project;
  final TaskPriority? priority;
  final bool         saving, canSave;
  final VoidCallback onCancel, onSave;

  const _SummaryPanel({
    required this.name,     required this.project,  required this.priority,
    required this.ref,      required this.sizeW,    required this.sizeH,
    required this.qty,      required this.saving,   required this.canSave,
    required this.onCancel, required this.onSave,
  });

  bool get _hasSize {
    final w = double.tryParse(sizeW) ?? 0;
    final h = double.tryParse(sizeH) ?? 0;
    return w > 0 && h > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 316,
      decoration: const BoxDecoration(
        color:  _T.white,
        border: Border(left: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Panel header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate200)),
            ),
            child: Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color:        _T.slate100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.preview_outlined,
                    size: 15, color: _T.slate500),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Task Summary',
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      _T.ink,
                      )),
                  Text('Live preview',
                      style: TextStyle(
                        fontSize:   10.5,
                        color:      _T.slate400,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ]),
          ),

          // ── Summary content ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Task name
                  _SummaryRow(
                    icon:  Icons.drive_file_rename_outline_rounded,
                    label: 'Task Name',
                    child: name.isNotEmpty
                        ? Text(name,
                            style: const TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                              color:      _T.ink,
                            ))
                        : const Text('—',
                            style: TextStyle(
                                fontSize: 13, color: _T.slate300)),
                  ),
                  const SizedBox(height: 12),

                  // Project
                  _SummaryRow(
                    icon:  Icons.folder_outlined,
                    label: 'Project',
                    child: project != null
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: project!.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(project!.name,
                                style: const TextStyle(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w600,
                                  color:      _T.ink,
                                )),
                          ])
                        : const Text('—',
                            style: TextStyle(
                                fontSize: 13, color: _T.slate300)),
                  ),
                  const SizedBox(height: 12),

                  // Priority
                  _SummaryRow(
                    icon:  Icons.flag_outlined,
                    label: 'Priority',
                    child: priority != null
                        ? _PriorityBadge(priority!)
                        : const Text('—',
                            style: TextStyle(
                                fontSize: 13, color: _T.slate300)),
                  ),

                  // ── Optional fields ─────────────────────────────────
                  if (ref.isNotEmpty || _hasSize) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: _T.slate100),
                    ),
                    const Text('Print specs',
                        style: TextStyle(
                          fontSize:      10,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 0.6,
                          color:         _T.slate400,
                        )),
                    const SizedBox(height: 10),
                  ],

                  if (ref.isNotEmpty) ...[
                    _SummaryRow(
                      icon:  Icons.tag_rounded,
                      label: 'Ref',
                      child: Text(ref,
                          style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                            color:      _T.ink,
                          )),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_hasSize) ...[
                    _SummaryRow(
                      icon:  Icons.straighten_outlined,
                      label: 'Size',
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 13, color: _T.ink,
                              fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(text: sizeW),
                            const TextSpan(
                                text: ' × ',
                                style: TextStyle(
                                  color:      _T.slate400,
                                  fontWeight: FontWeight.w400,
                                )),
                            TextSpan(text: sizeH),
                            const TextSpan(
                                text: ' cm',
                                style: TextStyle(
                                  fontSize:   11,
                                  color:      _T.slate500,
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ),
                      ),
                    ),
                    if (qty.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SummaryRow(
                        icon:  Icons.inventory_2_outlined,
                        label: 'Qty',
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 13, color: _T.ink,
                                fontWeight: FontWeight.w600),
                            children: [
                              TextSpan(text: qty),
                              const TextSpan(
                                  text: ' pcs',
                                  style: TextStyle(
                                    fontSize:   11,
                                    color:      _T.slate500,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // Status badge — always "Initialized" for a new task
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:        _T.slate50,
                      borderRadius: BorderRadius.circular(_T.rLg),
                      border:       Border.all(color: _T.slate200),
                    ),
                    child: Row(children: [
                      Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color:        _T.slate100,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.schedule_outlined,
                            size: 15, color: _T.slate400),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Initial status',
                                style: TextStyle(
                                  fontSize:   10,
                                  fontWeight: FontWeight.w600,
                                  color:      _T.slate400,
                                  letterSpacing: 0.3,
                                )),
                            SizedBox(height: 2),
                            Text('Initialized',
                                style: TextStyle(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w700,
                                  color:      _T.ink3,
                                )),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _T.slate200)),
            ),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor:         _T.blue,
                    disabledBackgroundColor: _T.slate200,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_T.r)),
                  ),
                  icon: saving
                      ? const SizedBox(
                          width: 15, height: 15,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.add_task_rounded, size: 17),
                  label: Text(
                    saving ? 'Creating…' : 'Create Task',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: saving ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _T.slate500,
                    side: const BorderSide(color: _T.slate200),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_T.r)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY ROW — icon + label (left) + content (right)
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Widget   child;
  const _SummaryRow({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color:        _T.slate100,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 14, color: _T.slate500),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                  fontSize:      10,
                  fontWeight:    FontWeight.w600,
                  color:         _T.slate400,
                  letterSpacing: 0.3,
                )),
            const SizedBox(height: 2),
            child,
          ],
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY BADGE (used in summary panel)
// ─────────────────────────────────────────────────────────────────────────────
class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBadge(this.priority);

  @override
  Widget build(BuildContext context) {
    final m = _priMeta(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color:        m.bg,
        borderRadius: BorderRadius.circular(99),
        border:       Border.all(color: m.color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(color: m.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(m.label,
            style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w700,
              color:      m.color,
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMOO TEXT FIELD — focus-animated border, optional/required badge
// ─────────────────────────────────────────────────────────────────────────────
class _SmooField extends StatefulWidget {
  final TextEditingController controller;
  final String                label, hint;
  final IconData              icon;
  final bool                  required;
  final String?               error;

  const _SmooField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.required = false,
    this.error,
  });

  @override
  State<_SmooField> createState() => _SmooFieldState();
}

class _SmooFieldState extends State<_SmooField> {
  final _focus   = FocusNode();
  bool  _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.required)
          _FieldLabel.required(widget.label)
        else
          _FieldLabel(widget.label, optional: !widget.required),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _focused ? _T.white : _T.slate50,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color: hasError
                  ? _T.red
                  : (_focused ? _T.blue : _T.slate200),
              width: (_focused || hasError) ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller:  widget.controller,
            focusNode:   _focus,
            style: const TextStyle(
                fontSize: 13, color: _T.ink, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText:  widget.hint,
              hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
              prefixIcon: Icon(widget.icon, size: 16, color: _T.slate400),
              border:        InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 13, horizontal: 12),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  size: 11, color: _T.red),
              const SizedBox(width: 4),
              Text(widget.error!,
                  style: const TextStyle(
                      fontSize: 11, color: _T.red,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NUM FIELD — numeric input with focus border, optional trailing suffix badge
// ─────────────────────────────────────────────────────────────────────────────
class _NumField extends StatefulWidget {
  final TextEditingController controller;
  final String                hint;
  final IconData              prefix;
  final bool                  enabled;
  final String?               suffix;

  const _NumField({
    required this.controller,
    required this.hint,
    required this.prefix,
    this.enabled = true,
    this.suffix,
  });

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  final _focus   = FocusNode();
  bool  _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: widget.enabled
            ? (_focused ? _T.white : _T.slate50)
            : _T.slate100,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(
          color: _focused && widget.enabled ? _T.blue : _T.slate200,
          width: _focused && widget.enabled ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller:   widget.controller,
            focusNode:    _focus,
            enabled:      widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: TextStyle(
              fontSize:   13,
              color:      widget.enabled ? _T.ink : _T.slate400,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText:  widget.hint,
              hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
              prefixIcon: Icon(widget.prefix, size: 15,
                  color: widget.enabled ? _T.slate400 : _T.slate300),
              border:         InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 13, horizontal: 12),
            ),
          ),
        ),
        if (widget.suffix != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(widget.suffix!,
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                  color: widget.enabled ? _T.slate500 : _T.slate300,
                )),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD LABEL — with optional "required *" or "Optional" annotation
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String  text;
  final bool    optional;
  final bool    isRequired;
  final String? optionalNote;

  const _FieldLabel(this.text, {this.optional = false, this.optionalNote})
      : isRequired = false;

  const _FieldLabel.required(this.text)
      : optional      = false,
        isRequired    = true,
        optionalNote  = null;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(text,
          style: const TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      _T.ink3,
          )),
      if (isRequired) ...[
        const SizedBox(width: 3),
        const Text('*',
            style: TextStyle(
              color:      _T.red,
              fontSize:   13,
              fontWeight: FontWeight.w700,
            )),
      ],
      if (optional) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color:        _T.slate100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            optionalNote ?? 'Optional',
            style: const TextStyle(
              fontSize:   9.5,
              fontWeight: FontWeight.w600,
              color:      _T.slate400,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    ],
  );
}