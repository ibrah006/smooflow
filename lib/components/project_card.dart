import 'package:flutter/material.dart';
import 'package:smooflow/constants.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String dueDate;
  final double progress;
  final List<String> members;
  final int extraMembers;

  const ProjectCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.dueDate,
    required this.progress,
    required this.members,
    this.extraMembers = 0,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and progress %
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${(progress * 100).round()}%",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Complete",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status + Due Date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Due: $dueDate",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),

          const SizedBox(height: 12),

          // Members Row
          Row(
            children: [
              // Avatars
              if (members.isEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    Icon(Icons.person_off_outlined, size: 20),
                    Text("None Assigned", style: textTheme.labelMedium),
                  ],
                ),
              ...members
                  .take(3)
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(m),
                      ),
                    ),
                  ),
              if (extraMembers > 0)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    "+$extraMembers",
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                  ),
                ),

              const Spacer(),

              // Colored dots
              Row(
                children: [
                  _dot(Colors.blue),
                  _dot(Colors.green),
                  _dot(Colors.yellow),
                  _dot(Colors.pink),
                  _dot(Colors.red),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2),
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}
