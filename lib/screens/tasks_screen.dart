import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/components/task_tile.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/custom_button.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/create_task_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final String projectId;
  const TasksScreen({super.key, required this.projectId});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool isEditingMode = false;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(projectByIdProvider(widget.projectId))!.tasks;

    return Scaffold(
      appBar: AppBar(
        title: Text("Tasks"),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                CreateTaskScreen(projectId: widget.projectId),
                      ),
                    );
                  },
                  child: Text("Create Task"),
                ),
              ];
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
