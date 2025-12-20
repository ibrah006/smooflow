import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/screens/add_project_progress_screen.dart';
import 'package:smooflow/core/app_routes.dart';
import 'package:smooflow/core/args/add_project_progress_args.dart';

class HelpTimeline extends ConsumerWidget {
  final String projectId;
  const HelpTimeline({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, ref) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        spacing: 20,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(),
          Icon(Icons.info_rounded, size: 60, color: colorPrimary),
          Text(
            "How to Use the Timeline",
            style: textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Image.asset("assets/images/help_timeline.png", width: 225),
          // Padding(
          //   padding: EdgeInsets.symmetric(
          //     horizontal: MediaQuery.of(context).size.width * 0.05,
          //   ),
            // child: 
            Text(
              "The timeline shows the sequence of stages and milestones for a project.",
              style: textTheme.bodyLarge!.copyWith(color: Colors.grey.shade900),
              textAlign: TextAlign.center,
            ),
          // ),
          // Padding(
          //   padding: EdgeInsets.symmetric(
          //     horizontal: MediaQuery.of(context).size.width * 0.05,
          //   ),
          //   child: SizedBox(
          //     width: double.infinity,
          //     child: FilledButton(
          //       onPressed: () {
          //         Navigator.pushNamed(
          //           context,
          //           AppRoutes.addProjectProgress,
          //           arguments: AddProjectProgressArgs(projectId),
          //         );
          //       },
          //       style: FilledButton.styleFrom(
          //         padding: const EdgeInsets.symmetric(vertical: 12),
          //         textStyle: textTheme.titleMedium,
          //       ),
          //       child: Text("Add Milestone"),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
