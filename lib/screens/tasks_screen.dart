import 'package:card_loading/card_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_launcher_icons/ios.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_overlay/loading_overlay.dart';
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

  gotoCreateTaskScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskScreen(projectId: widget.projectId),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      try {
        tasks = ref.watch(tasksByProjectProvider(widget.projectId));
        setState(() {});
      } catch (e) {
        // Already initialized
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    try {
      tasks;
    } catch (e) {
      return LoadingOverlay(isLoading: true, child: SizedBox());
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

          if (snapshot.data == null) {
            return Column(
              children: [
                SizedBox(height: 20),
                ...List.generate(3, (index) {
                  return CardLoading(
                    height: 65,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(
                      horizontal: 20,
                    ).copyWith(bottom: 10),
                    borderRadius: BorderRadius.circular(20),
                  );
                }),
              ],
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
