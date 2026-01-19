import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/custom_button.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/add_project.dart';
import 'package:smooflow/screens/production_project_screen.dart';

class RecentProjectsSection extends ConsumerWidget {
  const RecentProjectsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final recent = ref.watch(projectNotifierProvider.notifier).recent;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorder, width: 1.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, right: 5),
            child: const Text(
              "Recent Projects",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 0),
          const SizedBox(height: 8),
          if (recent.isNotEmpty)
            _projectTile(
              context,
              ref.read(projectByIdProvider(recent[0]!))!,
              icon: Icons.print,
              iconColor: colorPrimary,
              statusColor: Colors.orange.shade700,
              statusBg: Colors.yellow.shade100,
            )
          else
            Center(
              child: SizedBox(
                width: 200,
                child: Column(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/icons/no_projects_icon.svg",
                      height: 50,
                    ),
                    Text(
                      "No projects",
                      style: textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(),
                    Text(
                      "Click the button below to add a new project.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium!.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddProjectScreen(),
                            ),
                          );
                        },
                        child: Text("Add Project"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (recent.length > 1) ...[
            const Divider(height: 0),
            _projectTile(
              context,
              ref.read(projectByIdProvider(recent[1]!))!,
              icon: Icons.image,
              iconColor: colorPositiveStatus,
              statusColor: Colors.green.shade700,
              statusBg: Colors.green.shade100,
            ),
          ],
          if (recent.length > 2) ...[
            const Divider(height: 0),
            _projectTile(
              context,
              ref.read(projectByIdProvider(recent[2]!))!,
              icon: Icons.palette,
              iconColor: colorPurple,
              statusColor: Colors.grey.shade700,
              statusBg: Colors.grey.shade200,
            ),
          ],
        ],
      ),
    );
  }

  Widget _projectTile(
    context,
    Project project, {
    required IconData icon,
    required Color iconColor,
    required Color statusColor,
    required Color statusBg,
  }) {
    return CustomButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AddProjectScreen.view(
                  projectId: project.id,
                ), //ProductionProjectScreen(
            //   projectId: project.id,
            // ),
          ),
        );
      },
      backgroundColor: Colors.white,
      surfaceAnimationColor: colorLight,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Due: ${project.dueDate?.formatDisplay}",
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(width: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                project.status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
