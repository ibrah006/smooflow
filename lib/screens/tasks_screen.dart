import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:smooflow/components/task_tile.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/providers/task_provider.dart';
import 'package:smooflow/screens/create_task_screen.dart';
import 'package:smooflow/screens/task_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final String projectId;
  const TasksScreen({super.key, required this.projectId});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool isEditingMode = false;

  late final Future<List<Task>> tasks;

  @override
  void initState() {
    super.initState();
  }

  gotoCreateTaskScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(projectId: widget.projectId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    try {
      tasks = ref.watch(tasksByProjectProvider(widget.projectId));
    } catch (e) {
      // Already initialized
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Tasks"),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: gotoCreateTaskScreen,
                  child: Text("Create Task"),
                ),
              ];
            },
          ),
          SizedBox(width: 15),
        ],
      ),
      body: FutureBuilder(
        future: tasks,
        builder: (context, snapshot) {
          if (snapshot.data != null && snapshot.data!.isEmpty) {
            return Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 1.65,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 20,
                  children: [
                    SvgPicture.asset(
                      "assets/icons/no_tasks_icon.svg",
                      width: 100,
                    ),
                    Text(
                      "No tasks",
                      style: textTheme.headlineLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Click the button below to create a task",
                      style: textTheme.titleMedium!.copyWith(
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: gotoCreateTaskScreen,
                        child: Text("Create Task"),
                      ),
                    ),
                    SizedBox(height: kToolbarHeight),
                  ],
                ),
              ),
            );
          }

          return ListView(
            children: [
              SizedBox(height: 20),
              if (snapshot.data != null)
                ...snapshot.data!.map((task) {
                  return TaskTile(task);
                }),
            ],
          );
        },
      ),
    );
  }
}
