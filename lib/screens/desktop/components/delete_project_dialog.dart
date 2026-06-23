import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/desktop/components/notification_toast.dart';

class _T {
  static const Color white = Colors.white;
  static const red = Color(0xFFEF4444);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color ink = Color(0xFF0F172A);
  static const Color ink3 = Color(0xFF1E293B);
  static const Color blue = Color(0xFF2563EB);
  static const double r = 8.0;
}

class DeleteProjectDialog extends ConsumerStatefulWidget {
  final Project project;

  const DeleteProjectDialog({required this.project});

  @override
  ConsumerState<DeleteProjectDialog> createState() =>
      _DeleteProjectDialogState();
}

class _DeleteProjectDialogState extends ConsumerState<DeleteProjectDialog> {
  bool _isLoading = false;

  Future<void> _handleDelete() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(projectNotifierProvider.notifier)
          .delete(widget.project.id);

      if (mounted) {
        Navigator.of(context).pop(); // Close the confirmation dialog
        AppToast.show(
          message: 'Project deleted',
          icon: Icons.delete_forever_rounded,
          color: _T.red,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          message: 'Failed to delete project. Try again.',
          icon: Icons.error_outline_rounded,
          color: _T.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _T.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _T.slate200, width: 1),
      ),
      child: Container(
        width: 420, // Clean fixed layout alignment suitable for desktop windows
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Warning Vector Indicator Layout
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _T.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: _T.red,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Delete Project',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _T.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Warning Text Details
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  color: _T.slate600,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                    text: widget.project.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _T.ink,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '? This action will permanently remove the project configuration records. This cannot be undone.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button Row with adaptive Loading States
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: _T.slate500,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.red,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _T.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Delete Project',
                              style: TextStyle(
                                color: _T.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
