import 'package:flutter/material.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/project_args.dart';

class ProjectCard extends StatefulWidget {
  final String id;
  final String name;
  final String? description;
  final String? client;
  final int totalTasks;
  final int completedTasks;
  final DateTime createdAt;

  const ProjectCard({
    Key? key,
    required this.id,
    required this.name,
    this.description,
    this.client,
    required this.totalTasks,
    required this.completedTasks,
    required this.createdAt,
  }) : super(key: key);

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  double get completionPercentage =>
      widget.totalTasks == 0 ? 0 : (widget.completedTasks / widget.totalTasks * 100);

  void onTap() {
    AppRoutes.navigateTo(
      context,
      AppRoutes.designProjectDetailsScreen,
      arguments: ProjectArgs(projectId: widget.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.client != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.business_rounded,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.client!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: colorPrimary,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.description != null)
              Text(
                widget.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              )
            else
              Text(
                'No description',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const Spacer(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.totalTasks} ${widget.totalTasks == 1 ? 'Task' : 'Tasks'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completionPercentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            _getProgressColor(completionPercentage),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getProgressColor(completionPercentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getProgressColor(completionPercentage).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${completionPercentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _getProgressColor(completionPercentage),
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

  Color _getProgressColor(double percentage) {
    if (percentage == 100) {
      return const Color(0xFF10B981); // Green
    } else if (percentage >= 50) {
      return const Color(0xFF3B82F6); // Blue
    } else if (percentage > 0) {
      return const Color(0xFFF59E0B); // Orange
    } else {
      return const Color(0xFF64748B); // Gray
    }
  }
}