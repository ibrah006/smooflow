// lib/widgets/status_indicator_dialog.dart
import 'package:flutter/material.dart';
import '../enums/progress_status.dart';

class TaskStatusIndicatorDialog extends StatelessWidget {
  const TaskStatusIndicatorDialog({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const TaskStatusIndicatorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Indicators',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Understanding job statuses',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
          
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Each job has a status indicator that shows its current state. Here\'s what each status means:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
          
                    // Status Items
                    _buildStatusItem(
                      status: ProgressStatus.completed,
                      title: 'Completed',
                      description: 'Job has been successfully completed and verified',
                      icon: Icons.check_rounded,
                    ),
          
                    const SizedBox(height: 16),
          
                    _buildStatusItem(
                      status: ProgressStatus.inProgress,
                      title: 'In Progress',
                      description: 'Job is currently being worked on',
                      icon: Icons.remove_rounded,
                    ),
          
                    const SizedBox(height: 16),
          
                    _buildStatusItem(
                      status: ProgressStatus.issues,
                      title: 'Has Issues',
                      description: 'Job encountered problems that need attention',
                      icon: Icons.priority_high_rounded,
                    ),
          
                    const SizedBox(height: 16),
          
                    _buildStatusItem(
                      status: ProgressStatus.pending,
                      title: 'Pending',
                      description: 'Job is waiting to be started or is scheduled',
                      icon: null,
                    ),
          
                    const SizedBox(height: 24),
          
                    const Divider(color: Color(0xFFF1F5F9)),
          
                    const SizedBox(height: 20),
          
                    // Example Job Card
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Example Job Card',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
          
                    const SizedBox(height: 12),
          
                    _buildExampleJobCard(),
          
                    const SizedBox(height: 20),
          
                    // Got It Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Got it',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required ProgressStatus status,
    required String title,
    required String description,
    required IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStatusCircle(status, icon: icon, size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCircle(
    ProgressStatus status, {
    required IconData? icon,
    double size = 44,
  }) {
    Color color = _getStatusColor(status);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: icon != null
          ? Icon(icon, color: Colors.white, size: size * 0.5)
          : null,
    );
  }

  Widget _buildExampleJobCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          _buildStatusCircle(
            ProgressStatus.inProgress,
            icon: Icons.remove_rounded,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Large format printing',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ibrahim',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Production',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.completed:
        return const Color(0xFF2563EB);
      case ProgressStatus.issues:
        return const Color(0xFFEF4444);
      case ProgressStatus.inProgress:
        return const Color(0xFFF59E0B);
      case ProgressStatus.pending:
        return const Color(0xFFE2E8F0);
    }
  }
}

// Helper widget to add info button to any screen
class StatusIndicatorInfoButton extends StatelessWidget {
  const StatusIndicatorInfoButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => TaskStatusIndicatorDialog.show(context),
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.help_outline_rounded,
          size: 18,
          color: Color(0xFF64748B),
        ),
      ),
      tooltip: 'Status indicators help',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}