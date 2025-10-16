// This is the Project screen tailored for the production department
// The regular project screen can be opened using AddProjectScreen.view

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/project_progress_indicator.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/create_task_screen.dart';
import 'package:smooflow/screens/project_timeline_screen.dart';
import 'package:smooflow/screens/tasks_screen.dart';
import 'package:smooflow/sections/project_timeline_section.dart';

class ProductionProjectScreen extends ConsumerWidget {
  final String projectId;
  ProductionProjectScreen({super.key, required this.projectId});

  final GlobalKey<ProjectTimelineMilestonesSectionState>
  projectTimelineMilestoneSectionKey = GlobalKey();

  @override
  Widget build(BuildContext context, ref) {
    final textTheme = Theme.of(context).textTheme;

    final Project project = ref.watch(projectByIdProvider(projectId))!;

    // Necessary for project details screen
    ref.watch(projectNotifierProvider.notifier).selectedProject = project;

    final status =
        ref
            .watch(projectNotifierProvider)
            .firstWhere((p) => p.id == project.id)
            .status;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Column(
          children: [
            Text(project.name),
            Text(
              "Ongoing Project",
              style: textTheme.bodyMedium!.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) {
              HapticFeedback.lightImpact();
              return List.generate(
                3,
                (index) => PopupMenuItem(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                [
                                  ProjectTimelineScreen(projectId: projectId),
                                  CreateTaskScreen(projectId: projectId),
                                  TasksScreen(projectId: projectId),
                                ][index],
                      ),
                    );
                  },
                  child: Text(
                    ["View Timelines", "Create Task", "View Tasks"][index],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  "Project Information",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 14),
                // Project Progress Rate
                ...progressRateSection(context, project),
                const SizedBox(height: 10),

                // Client Company
                Row(
                  spacing: 5,
                  children: [
                    Icon(Icons.apartment_rounded),
                    const Text(
                      "Client Company*",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(project.client.name, style: textTheme.titleLarge),
                const SizedBox(height: 20),

                // Project Description
                const Text(
                  "Project Description",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  project.description ?? "N/A",
                  maxLines: 4,
                  style: textTheme.bodyMedium!.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),

                // Project timeline / progress indicator
                SizedBox(height: 25),
                ProjectProgressIndicator(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Estimated Materials",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 23,
                          width: 23,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Color(0xFF4fabfe),
                            border: Border.all(
                              color: Color(0xFFa8d3fe),
                              width: 2,
                            ),
                          ),
                        ),
                        Icon(Icons.info, color: Color(0xFFd6ebfd)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Image.asset("assets/images/box_open.png", width: 115),
                SizedBox(height: 10),
                Text(
                  "No Estimated Materials",
                  style: textTheme.titleMedium!.copyWith(
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                SizedBox(height: 15),
                SizedBox(
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 40,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text("Add"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> progressRateSection(BuildContext context, Project project) {
    final textTheme = Theme.of(context).textTheme;
    try {
      return [
        Text("Progress Rate", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(
          spacing: 12,
          children: [
            SizedBox(
              width: 135,
              child: LinearProgressIndicator(
                value: project.progressRate,
                borderRadius: BorderRadius.circular(10),
                minHeight: 10,
                color: colorPrimary,
                backgroundColor: colorPrimary.withValues(alpha: 0.1),
              ),
            ),
            Text(
              "${(project.progressRate * 100).toStringAsFixed(0)}%",
              style: textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: colorPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
      ];
    } catch (e) {
      return [];
    }
  }
}
