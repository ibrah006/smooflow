// ─────────────────────────────────────────────────────────────────────────────
// create_task_screen.dart — updated to match current design system
//
// Changes from previous version:
//   • Topbar back button: Material/InkWell → AnimatedContainer hover pattern
//   • Topbar breadcrumb: matches _AdminTopbar style (slate400 / "/" / ink2)
//   • Section cards: boxShadow removed — flat border only (matches lane cards)
//   • Summary panel: header/footer border slate200 → slate100
//   • Summary footer: FilledButton/OutlinedButton → custom _ActionButton pair
//   • _snack → AppToast.show (no ScaffoldMessenger dependency)
//   • Priority picker: tightened chip sizing to match board filter pill scale
//   • Project dropdown: fill color slate50 → white, matches _SmooField
//   • All font sizes/weights audited against _AdminTopbar + filter bar
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/notification_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOKENS — unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF1E293B);
  static const ink3 = Color(0xFF334155);
  static const white = Colors.white;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY METADATA — unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _PriMeta {
  final TaskPriority value;
  final String label;
  final String sub;
  final Color color, bg;
  final IconData icon;
  const _PriMeta({
    required this.value,
    required this.label,
    required this.sub,
    required this.color,
    required this.bg,
    required this.icon,
  });
}

const _kPriorities = [
  _PriMeta(
    value: TaskPriority.urgent,
    label: 'Urgent',
    sub: 'Needs immediate attention',
    color: _T.red,
    bg: _T.red50,
    icon: Icons.local_fire_department_outlined,
  ),
  _PriMeta(
    value: TaskPriority.high,
    label: 'High',
    sub: 'Important, soon',
    color: _T.amber,
    bg: _T.amber50,
    icon: Icons.keyboard_double_arrow_up_rounded,
  ),
  _PriMeta(
    value: TaskPriority.normal,
    label: 'Normal',
    sub: 'Standard queue',
    color: _T.slate500,
    bg: _T.slate100,
    icon: Icons.remove_rounded,
  ),
];

_PriMeta priMeta(TaskPriority p) =>
    _kPriorities.firstWhere((m) => m.value == p);

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DesignCreateTaskScreen extends ConsumerStatefulWidget {
  final String? initialProject;
  const DesignCreateTaskScreen({super.key, this.initialProject});

  @override
  ConsumerState<DesignCreateTaskScreen> createState() =>
      _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<DesignCreateTaskScreen> {
  final _nameCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _wCtrl = TextEditingController();
  final _hCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  Project? _project;
  TaskPriority? _priority = TaskPriority.normal;
  bool _submitted = false;
  bool _saving = false;

  bool get _hasSize {
    final w = double.tryParse(_wCtrl.text.trim()) ?? 0;
    final h = double.tryParse(_hCtrl.text.trim()) ?? 0;
    return w > 0 && h > 0;
  }

  bool get _nameOk => _nameCtrl.text.trim().isNotEmpty;
  bool get _projectOk => _project != null;
  bool get _priorityOk => _priority != null;
  bool get _formOk => _nameOk && _projectOk && _priorityOk;

  DateTime? date;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _project =
          widget.initialProject != null
              ? ref.watch(projectByIdProvider(widget.initialProject!))
              : null;
      setState(() {});
    });
    for (final c in [_nameCtrl, _refCtrl, _wCtrl, _hCtrl, _qtyCtrl]) {
      c.addListener(_onFieldChange);
    }
  }

  void _onFieldChange() {
    if (!_hasSize && _qtyCtrl.text.isNotEmpty) _qtyCtrl.clear();
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

  Future<void> _pickDate(DateTime? picked) async {
    if (picked == null) return;
    setState(() => date = picked);
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formOk) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final reference = _refCtrl.text.trim();

    try {
      final w = double.tryParse(_wCtrl.text.trim());
      final h = double.tryParse(_hCtrl.text.trim());
      final qty = int.tryParse(_qtyCtrl.text.trim());

      final newTask = Task.create(
        name: _nameCtrl.text,
        description: '',
        dueDate: null,
        assignees: [],
        projectId: _project!.id,
        priority: _priority ?? TaskPriority.normal,
        ref: reference.isEmpty ? null : reference,
        size: '$w×$h cm',
        quantity: qty,
        date: date,
      );

      await ref
          .watch(projectNotifierProvider.notifier)
          .createTask(task: newTask);
      // ref.watch(taskNotifierProvider.notifier).loadTaskToMemory(newTask);

      if (mounted) {
        AppToast.show(
          message: 'Task created successfully',
          icon: Icons.add_task_rounded,
          color: _T.green,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        print("error caught: $e");
        AppToast.show(
          message: 'Failed to create task',
          subtitle: 'Please try again',
          icon: Icons.error_outline_rounded,
          color: _T.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectNotifierProvider);

    return Scaffold(
      backgroundColor: _T.slate50,
      body: Column(
        children: [
          _Topbar(onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LEFT: form ──────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 20, 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page heading
                          const Text(
                            'New Task',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _T.ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Fill in the task details below. Required fields are marked *.',
                            style: TextStyle(
                              fontSize: 13,
                              color: _T.slate400,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Section 1: Task Details ───────────────────
                          _SectionCard(
                            icon: Icons.assignment_outlined,
                            iconColor: _T.blue,
                            iconBg: _T.blue50,
                            title: 'Task Details',
                            subtitle: 'Name, project and priority',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SmooField(
                                  controller: _nameCtrl,
                                  label: 'Task Name',
                                  hint: 'e.g. Banner 3×6m — Grand Opening',
                                  icon: Icons.drive_file_rename_outline_rounded,
                                  required: true,
                                  error:
                                      _submitted && !_nameOk
                                          ? 'Task name is required'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                _FieldLabel.required('Project'),
                                const SizedBox(height: 7),
                                _ProjectDropdown(
                                  projects: projects,
                                  value: _project,
                                  error: _submitted && !_projectOk,
                                  onChanged:
                                      (p) => setState(() => _project = p),
                                ),
                                const SizedBox(height: 16),
                                _FieldLabel.required('Priority'),
                                const SizedBox(height: 9),
                                _PriorityPicker(
                                  selected: _priority,
                                  onSelected:
                                      (p) => setState(() => _priority = p),
                                  showError: _submitted && !_priorityOk,
                                ),
                                const SizedBox(height: 16),
                                _FieldLabel('Date', optional: true),
                                const SizedBox(height: 7),
                                _DateField(
                                  value: date,
                                  onChange: _pickDate,
                                  onClear: () => setState(() => date = null),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Section 2: Print Specifications ───────────
                          _SectionCard(
                            icon: Icons.straighten_outlined,
                            iconColor: _T.purple,
                            iconBg: _T.purple50,
                            title: 'Print Specifications',
                            subtitle:
                                'Optional — reference, dimensions and quantity',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SmooField(
                                  controller: _refCtrl,
                                  label: 'Reference (Ref)',
                                  hint: 'e.g. PO-2024-0491',
                                  icon: Icons.tag_rounded,
                                  required: false,
                                ),
                                const SizedBox(height: 16),
                                _SizeRow(wCtrl: _wCtrl, hCtrl: _hCtrl),
                                const SizedBox(height: 16),
                                _QtyField(
                                  controller: _qtyCtrl,
                                  enabled: _hasSize,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── RIGHT: summary panel ────────────────────────────────
                _SummaryPanel(
                  name: _nameCtrl.text.trim(),
                  project: _project,
                  priority: _priority,
                  ref: _refCtrl.text.trim(),
                  sizeW: _wCtrl.text.trim(),
                  sizeH: _hCtrl.text.trim(),
                  qty: _qtyCtrl.text.trim(),
                  saving: _saving,
                  canSave: _formOk || !_submitted,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: _submit,
                  date: date,
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
//
// Matches _AdminTopbar design:
//   • Back button: AnimatedContainer hover (slate100 fill, no Material ripple)
//   • Breadcrumb: "Workspace / New Task" — slate400 category, ink2 bold label
//   • Icon badge: blue50 background, blue icon
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final VoidCallback onBack;
  const _Topbar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button — hover pattern from design system
          _BackButton(onTap: onBack),
          const SizedBox(width: 14),

          // Icon badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _T.blue50,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.add_task_rounded, size: 14, color: _T.blue),
          ),
          const SizedBox(width: 10),

          // Breadcrumb — matches _BreadcrumbSection in admin_topbar.dart
          const Text(
            'Workspace',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _T.slate400,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '/',
              style: TextStyle(fontSize: 13, color: _T.slate300),
            ),
          ),
          const Text(
            'New Task',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _T.ink2,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hovered ? _T.slate100 : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: _hovered ? _T.slate200 : _T.slate200),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 15,
            color: _hovered ? _T.ink2 : _T.slate500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD
//
// Shadow removed — flat border only, matching board lane cards.
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(_T.rLg),
        border: Border.all(color: _T.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: iconColor.withOpacity(0.2)),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _T.ink,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _T.slate400,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Divider(height: 1, color: _T.slate100),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT DROPDOWN
//
// Fill color: white (was slate50) — consistent with _SmooField.
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectDropdown extends StatelessWidget {
  final List<Project> projects;
  final Project? value;
  final bool error;
  final ValueChanged<Project?> onChanged;

  const _ProjectDropdown({
    required this.projects,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Project>(
      value: value,
      isExpanded: true,
      hint: const Text(
        'Select a project',
        style: TextStyle(fontSize: 13, color: _T.slate400),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: _T.slate400,
      ),
      style: const TextStyle(
        fontSize: 13,
        color: _T.ink,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: _T.white,
      borderRadius: BorderRadius.circular(_T.rLg),
      decoration: InputDecoration(
        prefixIcon:
            value != null
                ? null
                : const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.folder_outlined,
                    size: 15,
                    color: _T.slate400,
                  ),
                ),
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 0),
        filled: true,
        fillColor: error ? _T.red50 : _T.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide: const BorderSide(color: _T.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide: BorderSide(
            color: error ? _T.red : _T.slate200,
            width: error ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide: const BorderSide(color: _T.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_T.r),
          borderSide: const BorderSide(color: _T.red, width: 1.5),
        ),
        errorText: error ? 'Please select a project' : null,
        errorStyle: const TextStyle(
          fontSize: 11,
          color: _T.red,
          fontWeight: FontWeight.w500,
        ),
      ),
      items:
          projects
              .map(
                (p) => DropdownMenuItem<Project>(
                  value: p,
                  child: Row(
                    children: [
                      const SizedBox(width: 9),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(p.name),
                    ],
                  ),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY PICKER
//
// Chip sizing tightened — vertical padding reduced from 11 → 9 to align with
// the board filter bar's pill scale. Icon size 14 → 13.
// ─────────────────────────────────────────────────────────────────────────────
class _PriorityPicker extends StatelessWidget {
  final TaskPriority? selected;
  final ValueChanged<TaskPriority?> onSelected;
  final bool showError;

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
        Row(
          children:
              _kPriorities.map((m) {
                final active = selected == m.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: m.value == TaskPriority.normal ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onTap: () => onSelected(active ? null : m.value),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: active ? m.bg : _T.white,
                            borderRadius: BorderRadius.circular(_T.r),
                            border: Border.all(
                              color:
                                  active
                                      ? m.color.withOpacity(0.45)
                                      : (showError
                                          ? _T.red.withOpacity(0.35)
                                          : _T.slate200),
                              width: active ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    m.icon,
                                    size: 13,
                                    color: active ? m.color : _T.slate400,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      m.label,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight:
                                            active
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                        color: active ? m.color : _T.ink3,
                                      ),
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    opacity: active ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 140),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      size: 12,
                                      color: m.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                m.sub,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color:
                                      active
                                          ? m.color.withOpacity(0.65)
                                          : _T.slate400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),

        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: const [
                Icon(Icons.error_outline_rounded, size: 12, color: _T.red),
                SizedBox(width: 4),
                Text(
                  'Please select a priority',
                  style: TextStyle(
                    fontSize: 11,
                    color: _T.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIZE ROW — unchanged logic, label updated to use _FieldLabel.optional
// ─────────────────────────────────────────────────────────────────────────────
class _SizeRow extends StatelessWidget {
  final TextEditingController wCtrl, hCtrl;
  const _SizeRow({required this.wCtrl, required this.hCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(
          'Size',
          optional: true,
          optionalNote: 'Width × Height',
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _NumField(
                controller: wCtrl,
                hint: 'Width',
                prefix: Icons.swap_horiz_rounded,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '×',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: _T.slate300,
                ),
              ),
            ),
            Expanded(
              child: _NumField(
                controller: hCtrl,
                hint: 'Height',
                prefix: Icons.swap_vert_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: _T.slate100,
                borderRadius: BorderRadius.circular(_T.r),
                border: Border.all(color: _T.slate200),
              ),
              child: const Text(
                'cm',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _T.slate500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QTY FIELD — unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _QtyField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  const _QtyField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _FieldLabel('Quantity', optional: true),
            const SizedBox(width: 8),
            if (!enabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _T.amber50,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _T.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.straighten_outlined, size: 10, color: _T.amber),
                    SizedBox(width: 4),
                    Text(
                      'Size required first',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _T.amber,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: _NumField(
            controller: controller,
            hint: 'e.g. 50',
            prefix: Icons.inventory_2_outlined,
            enabled: enabled,
            suffix: 'pcs',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY PANEL
//
// Changes:
//   • Header/footer borders: slate200 → slate100 (matches detail panel)
//   • Header icon: slate100 bg (was same) — kept as-is, already correct
//   • Footer buttons: FilledButton/OutlinedButton → _PrimaryButton/_GhostButton
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryPanel extends StatelessWidget {
  final String name, ref, sizeW, sizeH, qty;
  final Project? project;
  final TaskPriority? priority;
  final bool saving, canSave;
  final VoidCallback onCancel, onSave;
  final DateTime? date;

  const _SummaryPanel({
    required this.name,
    required this.project,
    required this.priority,
    required this.ref,
    required this.sizeW,
    required this.sizeH,
    required this.qty,
    required this.saving,
    required this.canSave,
    required this.onCancel,
    required this.onSave,
    required this.date,
  });

  bool get _hasSize {
    final w = double.tryParse(sizeW) ?? 0;
    final h = double.tryParse(sizeH) ?? 0;
    return w > 0 && h > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(left: BorderSide(color: _T.slate200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Panel header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.slate100)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _T.slate100,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.preview_outlined,
                    size: 13,
                    color: _T.slate500,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Summary',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.ink,
                      ),
                    ),
                    Text(
                      'Live preview',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: _T.slate400,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Summary content ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(
                    icon: Icons.drive_file_rename_outline_rounded,
                    label: 'Task Name',
                    child:
                        name.isNotEmpty
                            ? Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _T.ink,
                              ),
                            )
                            : const _Placeholder(),
                  ),
                  const SizedBox(height: 12),

                  _SummaryRow(
                    icon: Icons.folder_outlined,
                    label: 'Project',
                    child:
                        project != null
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: project!.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  project!.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _T.ink,
                                  ),
                                ),
                              ],
                            )
                            : const _Placeholder(),
                  ),
                  const SizedBox(height: 12),

                  _SummaryRow(
                    icon: Icons.flag_outlined,
                    label: 'Priority',
                    child:
                        priority != null
                            ? _PriorityBadge(priority!)
                            : const _Placeholder(),
                  ),

                  const SizedBox(height: 12),
                  _SummaryRow(
                    icon: Icons.event_outlined,
                    label: 'Date',
                    child:
                        date != null
                            ? Text(
                              _DateField.format(date!),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _T.ink,
                              ),
                            )
                            : const _Placeholder(),
                  ),

                  // Optional section divider
                  if (ref.isNotEmpty || _hasSize) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: _T.slate100),
                    ),
                    const Text(
                      'PRINT SPECS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: _T.slate400,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (ref.isNotEmpty) ...[
                    _SummaryRow(
                      icon: Icons.tag_rounded,
                      label: 'Ref',
                      child: Text(
                        ref,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _T.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_hasSize) ...[
                    _SummaryRow(
                      icon: Icons.straighten_outlined,
                      label: 'Size',
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: _T.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(text: sizeW),
                            const TextSpan(
                              text: ' × ',
                              style: TextStyle(
                                color: _T.slate400,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(text: sizeH),
                            const TextSpan(
                              text: ' cm',
                              style: TextStyle(
                                fontSize: 11,
                                color: _T.slate500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (qty.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SummaryRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Qty',
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: _T.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(text: qty),
                              const TextSpan(
                                text: ' pcs',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _T.slate500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 20),

                  // Initial status chip
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _T.slate50,
                      borderRadius: BorderRadius.circular(_T.r),
                      border: Border.all(color: _T.slate200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _T.slate100,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.schedule_outlined,
                            size: 13,
                            color: _T.slate400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Initial status',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: _T.slate400,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Initialized',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _T.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────
          // Uses _PrimaryButton + _GhostButton — same pattern as
          // _FilledActionButton / _GhostButton in detail_panel.dart
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _T.slate100)),
            ),
            child: Column(
              children: [
                _PrimaryButton(
                  label: saving ? 'Creating…' : 'Create Task',
                  icon: saving ? null : Icons.add_task_rounded,
                  loading: saving,
                  enabled: !saving,
                  onTap: onSave,
                ),
                const SizedBox(height: 8),
                _GhostButton(label: 'Cancel', onTap: saving ? null : onCancel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIMARY BUTTON
//
// Blue filled — matches _CreateTaskButton in admin_topbar.dart and
// _FilledActionButton in detail_panel.dart.
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool loading, enabled;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onTap,
    this.icon,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bg =
        widget.enabled ? (_hovered ? _T.blueHover : _T.blue) : _T.slate100;

    return MouseRegion(
      cursor:
          widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(_T.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else if (widget.icon != null)
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.enabled ? Colors.white : _T.slate400,
                ),
              if (!widget.loading && widget.icon != null)
                const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled ? Colors.white : _T.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GHOST BUTTON — matches _GhostButton in detail_panel.dart exactly
// ─────────────────────────────────────────────────────────────────────────────
class _GhostButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _GhostButton({required this.label, this.onTap});

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return MouseRegion(
      cursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _hovered && !disabled ? _T.slate100 : Colors.transparent,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(color: _T.slate200),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: disabled ? _T.slate300 : _T.slate500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SUMMARY WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// Empty value placeholder — "—" in slate300
class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext context) =>
      const Text('—', style: TextStyle(fontSize: 13, color: _T.slate300));
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: _T.slate100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 13, color: _T.slate500),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _T.slate400,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            child,
          ],
        ),
      ),
    ],
  );
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBadge(this.priority);

  @override
  Widget build(BuildContext context) {
    final m = priMeta(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: m.bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: m.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: m.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            m.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: m.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEXT FIELD COMPONENTS — _SmooField, _NumField, _FieldLabel unchanged in logic
// ─────────────────────────────────────────────────────────────────────────────
class _SmooField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool required;
  final String? error;

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
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

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
              color: hasError ? _T.red : (_focused ? _T.blue : _T.slate200),
              width: (_focused || hasError) ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            style: const TextStyle(
              fontSize: 13,
              color: _T.ink,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
              prefixIcon: Icon(widget.icon, size: 15, color: _T.slate400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 11,
                  color: _T.red,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.error!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _T.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NumField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefix;
  final bool enabled;
  final String? suffix;

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
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color:
            widget.enabled ? (_focused ? _T.white : _T.slate50) : _T.slate100,
        borderRadius: BorderRadius.circular(_T.r),
        border: Border.all(
          color: _focused && widget.enabled ? _T.blue : _T.slate200,
          width: _focused && widget.enabled ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: TextStyle(
                fontSize: 13,
                color: widget.enabled ? _T.ink : _T.slate400,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(fontSize: 13, color: _T.slate300),
                prefixIcon: Icon(
                  widget.prefix,
                  size: 14,
                  color: widget.enabled ? _T.slate400 : _T.slate300,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
            ),
          ),
          if (widget.suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                widget.suffix!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.enabled ? _T.slate500 : _T.slate300,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool optional;
  final bool isRequired;
  final String? optionalNote;

  const _FieldLabel(this.text, {this.optional = false, this.optionalNote})
    : isRequired = false;

  const _FieldLabel.required(this.text)
    : optional = false,
      isRequired = true,
      optionalNote = null;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _T.ink3,
        ),
      ),
      if (isRequired) ...[
        const SizedBox(width: 3),
        const Text(
          '*',
          style: TextStyle(
            color: _T.red,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
      if (optional) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: _T.slate100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            optionalNote ?? 'Optional',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: _T.slate400,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DATE FIELD  — type a date OR pick from a positioned calendar popup.
//
// Signature change from original:
//   • Added `onChange` (ValueChanged<DateTime?>) — called on both pick & type.
//     The original `onPick` handler is replaced by this single callback.
//   • `onClear` kept as-is.
//
// Border/color tokens are identical to the original _SmooField style used
// throughout the app. The only visual additions are the right-side icon
// buttons and the calendar popup.
//
// Suggestion: when the field is actively focused (typing mode), consider
// using a solid `_T.blue` border (no opacity) instead of withOpacity(0.55)
// so it visually matches how _SmooField behaves on focus — clearer active
// state without changing the "filled" or "idle" appearances at all.
// ─────────────────────────────────────────────────────────────────────────────

class _DateField extends StatefulWidget {
  final DateTime? value;

  /// Called whenever the date changes — from a calendar pick OR a typed entry.
  /// Receives null when the field is cleared.
  final ValueChanged<DateTime?> onChange;

  final VoidCallback onClear;

  const _DateField({
    required this.value,
    required this.onChange,
    required this.onClear,
  });

  /// Shared formatter — "Jan 15, 2025"
  static String format(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  bool _hovered = false;
  bool _typingMode = false;
  bool _calendarOpen = false;

  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // Calendar popup is ~300 px tall; use to decide above/below.
  static const double _kCalendarH = 316.0;
  static const double _kGap = 6.0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _syncText();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_DateField old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) _syncText();
  }

  @override
  void dispose() {
    _removeOverlay();
    _textCtrl.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _syncText() {
    _textCtrl.text =
        widget.value != null ? _DateField.format(widget.value!) : '';
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _typingMode) _commitTyped();
  }

  // ── Typed input ───────────────────────────────────────────────────────────

  void _commitTyped() {
    if (!mounted) return;
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty) {
      widget.onChange(null);
    } else {
      final parsed = _tryParse(raw);
      if (parsed != null) {
        widget.onChange(parsed);
      } else {
        // Bad input — restore previous value silently.
        _syncText();
      }
    }
    setState(() => _typingMode = false);
  }

  /// Accepts two formats:
  ///   • "Jan 15, 2025"  (canonical — matches the field's own output)
  ///   • "01/15/2025"    (MM/DD/YYYY — common secondary format)
  DateTime? _tryParse(String s) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    // "Jan 15, 2025" or "Jan 15 2025"
    final re = RegExp(r'^([a-zA-Z]{3})\s+(\d{1,2}),?\s+(\d{4})$');
    final m = re.firstMatch(s);
    if (m != null) {
      final mo = months[m.group(1)!.toLowerCase()];
      final d = int.tryParse(m.group(2)!);
      final y = int.tryParse(m.group(3)!);
      if (mo != null && d != null && y != null) {
        try {
          return DateTime(y, mo, d);
        } catch (_) {}
      }
    }

    // "01/15/2025"
    final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final sm = slash.firstMatch(s);
    if (sm != null) {
      final mo = int.tryParse(sm.group(1)!);
      final d = int.tryParse(sm.group(2)!);
      final y = int.tryParse(sm.group(3)!);
      if (mo != null && d != null && y != null) {
        try {
          return DateTime(y, mo, d);
        } catch (_) {}
      }
    }

    return null;
  }

  // ── Calendar overlay ──────────────────────────────────────────────────────

  void _toggleCalendar() {
    if (_calendarOpen) {
      _closeCalendar();
      return;
    }

    // Measure available space below the field to decide positioning.
    final box = context.findRenderObject() as RenderBox?;
    bool showAbove = false;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      final screenH = MediaQuery.of(context).size.height;
      final spaceBelow = screenH - pos.dy - box.size.height;
      showAbove = spaceBelow < _kCalendarH + _kGap + 16;
    }

    // Exit typing mode when switching to calendar.
    if (_typingMode) setState(() => _typingMode = false);
    setState(() => _calendarOpen = true);

    _overlayEntry = OverlayEntry(
      builder:
          (_) => _CalendarPopup(
            layerLink: _layerLink,
            showAbove: showAbove,
            selectedDate: widget.value,
            onPick: (d) {
              widget.onChange(d);
              _closeCalendar();
            },
            onDismiss: _closeCalendar,
          ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeCalendar() {
    _removeOverlay();
    if (mounted) setState(() => _calendarOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ── Typing mode entry ─────────────────────────────────────────────────────

  void _enterTypingMode() {
    _closeCalendar();
    setState(() => _typingMode = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filled = widget.value != null;
    final active = _typingMode || _calendarOpen;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          // ── Border — identical token values to original ─────────────────
          decoration: BoxDecoration(
            color: filled || _hovered || active ? _T.white : _T.slate50,
            borderRadius: BorderRadius.circular(_T.r),
            border: Border.all(
              color:
                  active
                      ? _T.blue.withOpacity(0.55)
                      : filled
                      ? _T.blue.withOpacity(0.45)
                      : _T.slate200,
              width: filled || active ? 1.5 : 1,
            ),
          ),
          child: _typingMode ? _buildTyping() : _buildDisplay(filled),
        ),
      ),
    );
  }

  // ── Display mode ──────────────────────────────────────────────────────────
  Widget _buildDisplay(bool filled) {
    return Row(
      children: [
        // Tappable text area → enters typing mode.
        Expanded(
          child: GestureDetector(
            onTap: _enterTypingMode,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 15,
                    color: filled ? _T.blue : _T.slate400,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      filled
                          ? _DateField.format(widget.value!)
                          : 'Type or pick a date…',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: filled ? FontWeight.w500 : FontWeight.w400,
                        color: filled ? _T.ink : _T.slate300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right-side actions.
        if (filled) ...[
          _FieldDivider(),
          _FieldIconBtn(
            icon: Icons.close_rounded,
            size: 14,
            color: _T.slate400,
            onTap: () {
              widget.onClear();
              _closeCalendar();
            },
          ),
        ] else ...[
          _FieldDivider(),
          _FieldIconBtn(
            icon:
                _calendarOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.calendar_month_outlined,
            size: _calendarOpen ? 16 : 15,
            color: _calendarOpen ? _T.blue : _T.slate400,
            onTap: _toggleCalendar,
          ),
        ],
      ],
    );
  }

  // ── Typing mode ───────────────────────────────────────────────────────────
  Widget _buildTyping() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Icon(Icons.edit_calendar_outlined, size: 14, color: _T.blue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _textCtrl,
            focusNode: _focusNode,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _T.ink,
            ),
            decoration: const InputDecoration(
              // Format hint lives right in the placeholder — always visible
              // before the user starts typing.
              hintText: 'e.g. Jan 15, 2025',
              hintStyle: TextStyle(
                fontSize: 13,
                color: _T.slate300,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (_) => _commitTyped(),
          ),
        ),
        // Format badge — subtle reminder, never intrusive.
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _T.slate100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Mon DD, YYYY',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: _T.slate400,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        _FieldDivider(),
        // Switch to calendar while still in typing mode.
        _FieldIconBtn(
          icon: Icons.calendar_month_outlined,
          size: 15,
          color: _T.slate400,
          onTap: _toggleCalendar,
        ),
        // Confirm typed value.
        _FieldIconBtn(
          icon: Icons.check_rounded,
          size: 15,
          color: _T.green,
          onTap: _commitTyped,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD HELPERS — thin divider + icon button inside the field row
// ─────────────────────────────────────────────────────────────────────────────

class _FieldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 20, color: _T.slate100);
}

class _FieldIconBtn extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;
  const _FieldIconBtn({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
  });
  @override
  State<_FieldIconBtn> createState() => _FieldIconBtnState();
}

class _FieldIconBtnState extends State<_FieldIconBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hov = true),
    onExit: (_) => setState(() => _hov = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 36,
        height: 42,
        decoration: BoxDecoration(
          color: _hov ? _T.slate50 : Colors.transparent,
        ),
        child: Icon(
          widget.icon,
          size: widget.size,
          color: _hov ? _T.ink3 : widget.color,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CALENDAR POPUP  — positioned overlay anchored to the field via LayerLink.
//
// showAbove=false → follower top-left aligns to field bottom-left (default).
// showAbove=true  → follower bottom-left aligns to field top-left.
// A 6 px gap is applied via the offset in both cases.
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarPopup extends StatefulWidget {
  final LayerLink layerLink;
  final bool showAbove;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onDismiss;

  const _CalendarPopup({
    required this.layerLink,
    required this.showAbove,
    required this.selectedDate,
    required this.onPick,
    required this.onDismiss,
  });

  @override
  State<_CalendarPopup> createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<_CalendarPopup> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final ref = widget.selectedDate ?? DateTime.now();
    _month = DateTime(ref.year, ref.month);
  }

  void _prev() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _next() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Monday-first week: Monday=1 → pad=0, Sunday=7 → pad=6
    final startPad = (DateTime(_month.year, _month.month, 1).weekday - 1) % 7;

    return Stack(
      children: [
        // ── Full-screen dismiss barrier ──────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
          ),
        ),

        // ── Anchored popup ───────────────────────────────────────────────────
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          targetAnchor:
              widget.showAbove ? Alignment.topLeft : Alignment.bottomLeft,
          followerAnchor:
              widget.showAbove ? Alignment.bottomLeft : Alignment.topLeft,
          offset: Offset(0, widget.showAbove ? -6 : 6),
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              width: 272,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _T.white,
                borderRadius: BorderRadius.circular(_T.rLg),
                border: Border.all(color: _T.slate200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.09),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Month / year header ────────────────────────────────────
                  Row(
                    children: [
                      _CalNavBtn(
                        icon: Icons.chevron_left_rounded,
                        onTap: _prev,
                      ),
                      Expanded(
                        child: Text(
                          _monthLabel(_month),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _T.ink,
                          ),
                        ),
                      ),
                      _CalNavBtn(
                        icon: Icons.chevron_right_rounded,
                        onTap: _next,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Day-of-week headers — Mon-first ─────────────────────────
                  Row(
                    children:
                        ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                            .map(
                              (lbl) => Expanded(
                                child: Center(
                                  child: Text(
                                    lbl,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _T.slate400,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),

                  const SizedBox(height: 4),

                  // ── Day grid ─────────────────────────────────────────────────
                  _buildGrid(today, daysInMonth, startPad),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(DateTime today, int daysInMonth, int startPad) {
    final cells = <Widget>[
      // Leading empty cells
      for (int i = 0; i < startPad; i++) const SizedBox(),

      // Day cells
      for (int day = 1; day <= daysInMonth; day++)
        _DayCell(
          day: day,
          isToday:
              today.year == _month.year &&
              today.month == _month.month &&
              today.day == day,
          isSelected:
              widget.selectedDate != null &&
              widget.selectedDate!.year == _month.year &&
              widget.selectedDate!.month == _month.month &&
              widget.selectedDate!.day == day,
          onTap: () => widget.onPick(DateTime(_month.year, _month.month, day)),
        ),
    ];

    // Pad last row to a full 7
    while (cells.length % 7 != 0) cells.add(const SizedBox());

    return Column(
      children: [
        for (int r = 0; r < cells.length; r += 7) ...[
          Row(
            children:
                cells.sublist(r, r + 7).map((c) => Expanded(child: c)).toList(),
          ),
          if (r + 7 < cells.length) const SizedBox(height: 2),
        ],
      ],
    );
  }

  static String _monthLabel(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CALENDAR NAVIGATION BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _CalNavBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CalNavBtn({required this.icon, required this.onTap});
  @override
  State<_CalNavBtn> createState() => _CalNavBtnState();
}

class _CalNavBtnState extends State<_CalNavBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hov = true),
    onExit: (_) => setState(() => _hov = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _hov ? _T.slate100 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(widget.icon, size: 16, color: _hov ? _T.ink3 : _T.slate400),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY CELL
// ─────────────────────────────────────────────────────────────────────────────
class _DayCell extends StatefulWidget {
  final int day;
  final bool isToday, isSelected;
  final VoidCallback onTap;
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });
  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hov = true),
    onExit: (_) => setState(() => _hov = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 30,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color:
              widget.isSelected
                  ? _T.blue
                  : _hov
                  ? _T.slate100
                  : widget.isToday
                  ? _T.blue50
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border:
              widget.isToday && !widget.isSelected
                  ? Border.all(color: _T.blue.withOpacity(0.3))
                  : null,
        ),
        child: Center(
          child: Text(
            '${widget.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  widget.isSelected || widget.isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
              color:
                  widget.isSelected
                      ? Colors.white
                      : widget.isToday
                      ? _T.blue
                      : _T.ink3,
            ),
          ),
        ),
      ),
    ),
  );
}
