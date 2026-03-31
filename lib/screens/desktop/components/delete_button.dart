import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/enums/task_priority.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/desktop/components/action_buttons.dart';
import 'package:smooflow/screens/desktop/components/notification_toast.dart';
import 'package:smooflow/screens/desktop/design_create_task_screen.concept.dart';

class _T {
  static const blue = Color(0xFF2563EB);
  static const blueHover = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);
  static const teal = Color(0xFF38BDF8);
  static const green = Color(0xFF10B981);
  static const green50 = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const red50 = Color(0xFFFEE2E2);
  static const purple = Color(0xFF8B5CF6);
  static const purple50 = Color(0xFFF3E8FF);
  static const indigo = Color(0xFF6366F1);
  static const indigo50 = Color(0xFFEEF2FF);
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
  static const sidebarW = 220.0;
  static const topbarH = 52.0;
  static const detailW = 400.0;
  static const r = 8.0;
  static const rLg = 12.0;
  static const rXl = 16.0;
}

class DeleteButton extends StatefulWidget {
  final Task task;
  final Function() onDelete;
  const DeleteButton({super.key, required this.task, required this.onDelete});

  @override
  State<DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<DeleteButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter:
          (_) => setState(() {
            _isHovering = true;
          }),
      onExit:
          (_) => setState(() {
            _isHovering = false;
          }),
      child: InkWell(
        onTap: () {
          showDeleteTaskDialog(
            context,
            task: widget.task,
            onDelete: widget.onDelete,
          );
        },
        child: GestureDetector(
          child: Container(
            padding: EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _isHovering ? _T.red50.withValues(alpha: 0.5) : null,
              borderRadius: BorderRadius.circular(_T.r),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: _isHovering ? _T.red : _T.slate400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DELETE TASK DIALOG
//
// Usage:
//   final confirmed = await showDeleteTaskDialog(context, task: task);
//   if (confirmed == true) { /* proceed with deletion */ }
//
// Design notes:
//   • Shown via showDialog with a custom barrierColor — no Route push
//   • No Material elevation shadow — flat border only, matches lane cards
//   • Back button / close: AnimatedContainer hover pattern
//   • Typography, spacing, and color tokens identical to create_task_screen.dart
//   • Destructive primary action uses _T.red family, not _T.blue
// ─────────────────────────────────────────────────────────────────────────────

/// Entry point — call this from anywhere to show the dialog.
Future<bool?> showDeleteTaskDialog(
  BuildContext context, {
  required Task task,
  required Function() onDelete,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.35),
    barrierDismissible: true,
    builder: (_) => _DeleteTaskDialog(task: task, onDelete: onDelete),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _DeleteTaskDialog extends ConsumerStatefulWidget {
  final Task task;
  final Function() onDelete;
  const _DeleteTaskDialog({required this.task, required this.onDelete});

  @override
  ConsumerState<_DeleteTaskDialog> createState() => _DeleteTaskDialogState();
}

class _DeleteTaskDialogState extends ConsumerState<_DeleteTaskDialog> {
  bool _deleting = false;

  Future<void> _confirm() async {
    setState(() => _deleting = true);
    try {
      // Replace with your actual delete call, e.g.:
      await ref.read(taskNotifierProvider.notifier).delete(widget.task.id);
      // await Future.delayed(const Duration(milliseconds: 600)); // stub
      if (mounted) Navigator.of(context).pop(true);

      // Close detail panel
      widget.onDelete();
    } catch (e) {
      print("failed to delte task ${widget.task.id}: $e");
      if (mounted) {
        setState(() => _deleting = false);
        AppToast.show(
          message: 'Failed to delete task',
          subtitle: 'Please try again',
          icon: Icons.error_outline_rounded,
          color: _T.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            decoration: BoxDecoration(
              color: _T.white,
              borderRadius: BorderRadius.circular(_T.rXl),
              border: Border.all(color: _T.slate200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogHeader(
                  task: widget.task,
                  onClose:
                      _deleting ? null : () => Navigator.of(context).pop(false),
                ),
                _DialogBody(task: widget.task),
                _DialogFooter(
                  deleting: _deleting,
                  onCancel:
                      _deleting ? null : () => Navigator.of(context).pop(false),
                  onConfirm: _deleting ? null : _confirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _DialogHeader extends StatelessWidget {
  final Task task;
  final VoidCallback? onClose;

  const _DialogHeader({required this.task, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _T.slate100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Destructive icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _T.red50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _T.red.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: _T.red,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete Task',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _T.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This action cannot be undone.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _T.slate400,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BODY
// ─────────────────────────────────────────────────────────────────────────────
class _DialogBody extends ConsumerWidget {
  final Task task;
  const _DialogBody({required this.task});

  @override
  Widget build(BuildContext context, ref) {
    final projectName = ref.watch(projectByIdProvider(task.projectId))!.name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task identity card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _T.slate50,
              borderRadius: BorderRadius.circular(_T.r),
              border: Border.all(color: _T.slate200),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _T.slate100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    size: 15,
                    color: _T.slate500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _T.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.ref != null || projectName != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (projectName != null)
                              _MetaChip(
                                icon: Icons.folder_outlined,
                                label: projectName,
                              ),
                            if (task.ref != null && projectName != null)
                              const SizedBox(width: 6),
                            if (task.ref != null)
                              _MetaChip(
                                icon: Icons.tag_rounded,
                                label: task.ref!,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (task.priority != null) ...[
                  const SizedBox(width: 10),
                  _PriorityDot(task.priority!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Warning message
          const Text(
            'Are you sure you want to permanently delete this task? '
            'All associated data including assignees, comments, and '
            'attachments will be removed.',
            style: TextStyle(fontSize: 12.5, color: _T.slate500, height: 1.55),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────
class _DialogFooter extends StatelessWidget {
  final bool deleting;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const _DialogFooter({
    required this.deleting,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _T.slate100)),
      ),
      child: Row(
        children: [
          // Cancel — ghost button
          Expanded(child: _GhostButton(label: 'Cancel', onTap: onCancel)),
          const SizedBox(width: 10),
          // Confirm delete — destructive primary button
          Expanded(
            child: _DestructiveButton(
              label: deleting ? 'Deleting…' : 'Delete Task',
              icon: deleting ? null : Icons.delete_outline_rounded,
              loading: deleting,
              enabled: !deleting,
              onTap: onConfirm ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLOSE BUTTON — AnimatedContainer hover, matches _BackButton
// ─────────────────────────────────────────────────────────────────────────────
class _CloseButton extends StatefulWidget {
  final VoidCallback? onTap;
  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered && enabled ? _T.slate100 : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: _hovered && enabled ? _T.slate200 : Colors.transparent,
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 14,
            color: _hovered && enabled ? _T.ink2 : _T.slate400,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESTRUCTIVE BUTTON — red variant of _PrimaryButton
// ─────────────────────────────────────────────────────────────────────────────
class _DestructiveButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool loading, enabled;
  final VoidCallback onTap;

  const _DestructiveButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onTap,
    this.icon,
  });

  @override
  State<_DestructiveButton> createState() => _DestructiveButtonState();
}

class _DestructiveButtonState extends State<_DestructiveButton> {
  bool _hovered = false;

  // Slightly darkened red on hover
  static const _redHover = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final bg = widget.enabled ? (_hovered ? _redHover : _T.red) : _T.slate100;

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
                  width: 13,
                  height: 13,
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
                const SizedBox(width: 6),
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
// META CHIP — small icon + label tag shown under the task name
// ─────────────────────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: _T.slate400),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: _T.slate400,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIORITY DOT — compact coloured dot shown in the task card corner
// ─────────────────────────────────────────────────────────────────────────────
class _PriorityDot extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityDot(this.priority);

  @override
  Widget build(BuildContext context) {
    final m = priMeta(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: m.bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: m.color.withOpacity(0.25)),
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
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: m.color,
            ),
          ),
        ],
      ),
    );
  }
}

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
