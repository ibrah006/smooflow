import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/task_tile.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/custom_button.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/create_task_screen.dart';

class TasksScreen extends ConsumerWidget {
  final String projectId;
  const TasksScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, ref) {
    final tasks = ref.watch(projectByIdProvider(projectId))!.tasks;

    return Scaffold(
      appBar: AppBar(
        title: Text("Tasks"),
        actions: [
          CustomButton.icon(
            icon: Icons.add_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTaskScreen(projectId: projectId),
                ),
              );
            },
          ),
          SizedBox(width: 15),
        ],
      ),
      body: Column(
        spacing: 10,
        children: [
          SizedBox(),
          ...tasks.map((task) {
            return TaskTile(task);
          }),
        ],
      ),
    );
  }
}
