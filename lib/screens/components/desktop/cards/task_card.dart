import 'package:flutter/material.dart';

enum TaskStatus {
  pending,
  inProgress,
  waitingApproval,
  approved,
  revision,
}

class TaskCard extends StatelessWidget {
  final String id;
  final String name;
  final String? description;
  final String projectName;
  final TaskStatus status;
  final String? assignee;
  final String? priority;
  final int artworkCount;
  final DateTime createdAt;
  final VoidCallback onTap;
  final VoidCallback? onUploadArtwork;
  final VoidCallback? onMoveToNextStage;

  const TaskCard({
    Key? key,
    required this.id,
    required this.name,
    this.description,
    required this.projectName,
    required this.status,
    this.assignee,
    this.priority,
    required this.artworkCount,
    required this.createdAt,
    required this.onTap,
    this.onUploadArtwork,
    this.onMoveToNextStage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.folder_rounded,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                projectName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (priority != null) _buildPriorityBadge(priority!),
                    const SizedBox(width: 12),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.image_rounded,
                      '$artworkCount artworks',
                      const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 16),
                    if (assignee != null)
                      _buildInfoChip(
                        Icons.person_outline_rounded,
                        assignee!,
                        const Color(0xFF64748B),
                      ),
                    const SizedBox(width: 16),
                    _buildInfoChip(
                      Icons.schedule_rounded,
                      _formatDate(createdAt),
                      const Color(0xFF64748B),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (onUploadArtwork != null)
                      OutlinedButton.icon(
                        onPressed: onUploadArtwork,
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text('Upload'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(color: Color(0xFF4F46E5)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    if (onMoveToNextStage != null && status != TaskStatus.approved)
                      ElevatedButton.icon(
                        onPressed: onMoveToNextStage,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Next Stage'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    IconData icon;

    switch (priority.toLowerCase()) {
      case 'critical':
        color = const Color(0xFFEF4444);
        icon = Icons.priority_high_rounded;
        break;
      case 'high':
        color = const Color(0xFFF59E0B);
        icon = Icons.keyboard_arrow_up_rounded;
        break;
      case 'medium':
        color = const Color(0xFF3B82F6);
        icon = Icons.drag_handle_rounded;
        break;
      default:
        color = const Color(0xFF64748B);
        icon = Icons.keyboard_arrow_down_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    Color color;
    Color bgColor;
    String label;
    IconData icon;

    switch (status) {
      case TaskStatus.pending:
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        label = 'Pending';
        icon = Icons.schedule_rounded;
        break;
      case TaskStatus.inProgress:
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        label = 'In Progress';
        icon = Icons.autorenew_rounded;
        break;
      case TaskStatus.waitingApproval:
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFF3E8FF);
        label = 'Pending Approval';
        icon = Icons.hourglass_empty_rounded;
        break;
      case TaskStatus.approved:
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        label = 'Approved';
        icon = Icons.check_circle_rounded;
        break;
      case TaskStatus.revision:
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        label = 'Revision Needed';
        icon = Icons.edit_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return const Color(0xFF64748B);
      case TaskStatus.inProgress:
        return const Color(0xFFF59E0B);
      case TaskStatus.waitingApproval:
        return const Color(0xFF8B5CF6);
      case TaskStatus.approved:
        return const Color(0xFF10B981);
      case TaskStatus.revision:
        return const Color(0xFFEF4444);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}