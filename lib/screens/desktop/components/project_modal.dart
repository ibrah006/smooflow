// ── Project Modal ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/company.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/repositories/company_repo.dart';
import 'package:smooflow/providers/company_provider.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/desktop/components/modal_components.dart';
import 'package:smooflow/screens/desktop/components/modal_shell.dart';
import 'package:smooflow/screens/desktop/helpers/dashboard_helpers.dart';

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

class ProjectModal extends ConsumerStatefulWidget {
  final Future<void> Function(Project) onSave;
  const ProjectModal({required this.onSave});
  @override
  ConsumerState<ProjectModal> createState() => _ProjectModalState();
}

class _ProjectModalState extends ConsumerState<ProjectModal> {
  final _name  = TextEditingController();
  final _desc  = TextEditingController();
  Color _color = _T.blue;
  DateTime? _due;
  bool _saving = false;
  Company? _client;

  static const _colors = [_T.blue, _T.purple, _T.green, _T.amber, _T.red, Color(0xFF0EA5E9)];

  // final List<Company> _clients = [...CompanyRepo.companies];
 
  @override
  void dispose() { _name.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _client == null) return;
    setState(() => _saving = true);

    // Optional: Unfocus keyboard
    FocusScope.of(context).unfocus();

    // Proceed with form submission

    try {
      await ref
        .read(projectNotifierProvider.notifier)
        .create(
          Project.create(
            name: _name.text,
            description: _desc.text,
            // TODO: let user assign incharge men when creating project
            assignedManagers: [],
            client: _client!,
            priority: 1,
            dueDate: _due,
            estimatedProductionStart: DateTime.now(),
          ),
        );
        // Notify organization state about this adding of a project to update projectsLastAdded
        ref.read(organizationNotifierProvider.notifier).projectAdded();

        if (mounted) Navigator.pop(context);
    } catch(e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to Create Project")));
      return;
    }

    setState(() => _saving = true);
    
  }

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyListProvider);

    final _clients = companyState.companies;

    return ModalShell(
      icon: Icons.folder_outlined,
      iconColor: _T.blue,
      title: 'New Project',
      subtitle: 'Create a project to group design tasks',
      onClose: () => Navigator.pop(context),
      onSave: _saving ? null : _submit,
      saveLabel: _saving ? 'Creating…' : 'Create Project',
      child: Column(children: [
        ModalField(
          label: 'Project Name', required: true,
          child: ModalInput(ctrl: _name, hint: 'e.g. Spring Campaign 2026'),
        ),
        const SizedBox(height: 16),
        ModalField(
          label: 'Customer',
          required: true,
          child: _clients.isEmpty
              ? FilledButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add),
                style: FilledButton.styleFrom(
                  textStyle: TextStyle(fontWeight: FontWeight.w500)
                ),
                label: Text("Add Client"))
              : ModalDropdown<Company?>(
                  value: _client,
                  items: _clients.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.name, style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() => _client = v),
                ),
        ),
        const SizedBox(height: 16),
        ModalField(
          label: 'Description',
          child: ModalTextarea(ctrl: _desc, hint: 'What is this project about?'),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ModalField(
            label: 'Due Date',
            child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(), lastDate: DateTime(2028),
                  builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _T.blue)), child: child!),
                );
                if (d != null) setState(() => _due = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(color: _T.slate50, border: Border.all(color: _T.slate200), borderRadius: BorderRadius.circular(_T.r)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: _T.slate400),
                  const SizedBox(width: 8),
                  Text(_due != null ? fmtDate(_due!) : 'Select date', style: TextStyle(fontSize: 13, color: _due != null ? _T.ink : _T.slate400)),
                ]),
              ),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: ModalField(
            label: 'Colour',
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: _colors.map((c) => GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: _color == c ? _T.ink : Colors.transparent, width: 2)),
                  child: _color == c ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
              )).toList(),
            ),
          )),
        ]),
      ]),
    );
  }
}