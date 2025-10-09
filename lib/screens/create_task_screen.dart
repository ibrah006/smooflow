import 'dart:math';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/models/user.dart';
import 'package:smooflow/providers/progress_log_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/repositories/users_repo.dart';
import 'package:smooflow/screens/project_timeline_screen.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  final String projectId;
  const CreateTaskScreen({super.key, required this.projectId});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  // final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _priority;
  DateTime? _dueDate;
  String? _selectedProgressLogId;
  List<User> _selectedAssignees = [];

  final List<String> priorities = ["Low", "Medium", "High", "Critical"];
  // final List<String> assignees = ["Ali Yusuf", "Liam Scott", "Emma Brown"];

  late final Future<List<User>> users;

  late final Future<List<ProgressLog>> progressLogs;

  // loading will also be true for progressLogs future snapshot.data == null
  bool _isLoading = false;

  // Show a snackbar with error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[600]),
    );
  }

  // Validate and Create Function
  void validateAndCreate() async {
    if (_titleController.text.trim().isEmpty) {
      _showError("Task name is required.");
      return;
    }

    if (_selectedProgressLogId == null) {
      _showError("Please select a Progress Stage.");
    }

    // if (_priority == null || _priority!.isEmpty) {
    //   _showError("Please select a priority.");
    //   return;
    // }

    // if (_assignee == null || _assignee!.isEmpty) {
    //   _showError("Please select a project head.");
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    final newTask = Task.create(
      name: _titleController.text.trim(),
      description: _descController.text.trim(),
      progressLogId: _selectedProgressLogId!,
      assignees: _selectedAssignees.map((user) => user.id).toList(),
      projectId: widget.projectId,
      // TODO
      // priority: _priority,
      dueDate: _dueDate,
    );

    try {
      await ref
          .read(projectNotifierProvider.notifier)
          .createTask(task: newTask);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to Create Task.")));

      return;
    }

    debugPrint("✅ Task Created: $newTask");

    setState(() {
      _isLoading = false;
    });

    // Navigate back
    Navigator.pop(context);

    // Optionally: clear the form
    _titleController.clear();
    _descController.clear();
    _priority = null;
    _selectedAssignees = [];
    _dueDate = null;
    _selectedProgressLogId = null;
  }

  InputDecoration _inputDecoration(String hint, {Color? backgroundColor}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: backgroundColor != null,
      fillColor: backgroundColor,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorError),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorBorderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorBorderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: colorBorderDark, width: 1.2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    users = UsersRepo.getUsers();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // This project's progress logs
    try {
      progressLogs = ref.read(
        progressLogsByProjectProvider(
          ProgressLogsByProviderArgs(
            widget.projectId,
            ensureLatestProgressLogData: false,
          ),
        ),
      );
    } catch (e) {
      // Not initialized yet
      Scaffold(body: Center(child: Text("Loading...")));
    }

    return FutureBuilder(
      future: progressLogs,
      builder: (context, snapshot) {
        return LoadingOverlay(
          isLoading: _isLoading || snapshot.data == null,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Create Task"),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Task Title
                            const Text(
                              "Task Name*",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _titleController,
                              decoration: _inputDecoration("Task title"),
                            ),
                            const SizedBox(height: 16),

                            // Associated with progress stage
                            Row(
                              spacing: 10,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Row(
                                        spacing: 5,
                                        children: [
                                          Icon(Icons.timeline_rounded),
                                          const Text(
                                            "Progress Stage*",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        value: _selectedProgressLogId,
                                        items:
                                            (snapshot.data?.map(
                                                      (log) => DropdownMenuItem(
                                                        value: log.id,
                                                        child: Text(
                                                          "${log.status.name[0].toUpperCase()}${log.status.name.substring(1)}",
                                                        ),
                                                      ),
                                                    ) ??
                                                    [])
                                                .toList(),
                                        onChanged:
                                            snapshot.data == null
                                                ? null
                                                : (val) => setState(
                                                  () =>
                                                      _selectedProgressLogId =
                                                          val,
                                                ),
                                        decoration: _inputDecoration(""),
                                        icon: Transform.rotate(
                                          angle: pi / 2,
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      // Priority Dropdown
                                      const Row(
                                        spacing: 5,
                                        children: [
                                          Icon(Icons.low_priority),
                                          Text(
                                            "Priority",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        value: _priority,
                                        items:
                                            priorities
                                                .map(
                                                  (p) => DropdownMenuItem(
                                                    value: p,
                                                    child: Text(p),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged:
                                            (val) =>
                                                setState(() => _priority = val),
                                        decoration: _inputDecoration(""),
                                        icon: Transform.rotate(
                                          angle: pi / 2,
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Description
                            const Text(
                              "Description",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _descController,
                              maxLines: 4,
                              decoration: _inputDecoration("Description"),
                            ),
                            const SizedBox(height: 16),

                            // Assignee Dropdown
                            const Row(
                              spacing: 5,
                              children: [
                                Icon(Icons.people_rounded),
                                Text(
                                  "Assignees",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FutureBuilder(
                              future: users,
                              builder: (context, snapshot) {
                                return snapshot.data == null
                                    ? Text("No Users found")
                                    : DropdownSearch<User>.multiSelection(
                                      decoratorProps: DropDownDecoratorProps(
                                        decoration: _inputDecoration(""),
                                      ),
                                      itemAsString: (usr) => usr.name,
                                      compareFn:
                                          (User a, User b) => a.id == b.id,
                                      items:
                                          (str, loadProps) =>
                                              snapshot.data?.toList() ?? [],
                                      selectedItems: _selectedAssignees,
                                      onChanged:
                                          (usrs) => setState(
                                            () => _selectedAssignees = usrs,
                                          ),
                                      // dropdownBuilder: (context, selectedItems) {
                                      //   // return Text();
                                      // },
                                    );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      // No Timeline found Info/Warning
                      if (snapshot.data != null && snapshot.data!.isEmpty)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorPending.withValues(alpha: 0.08),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade100,
                                  blurRadius: 3,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline, color: colorPending),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Create Timelines",
                                      style: textTheme.titleMedium!.copyWith(
                                        color: colorPending,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width -
                                          80,
                                      child: Text(
                                        "Cannot create Tasks without any active progress timeline(s)",
                                        style: textTheme.bodySmall,
                                        overflow: TextOverflow.fade,
                                        maxLines: 3,
                                      ),
                                    ),
                                    SizedBox(height: 17),
                                    GestureDetector(
                                      child: Text(
                                        "Try again after adding timelines",
                                        style: textTheme.bodySmall!.copyWith(
                                          decoration: TextDecoration.underline,
                                          decorationColor: colorPending,
                                          color: colorPending,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ).copyWith(bottom: 35),
                  child: Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            disabledBackgroundColor: Colors.grey.shade200,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            textStyle: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed:
                              snapshot.data != null && snapshot.data!.isNotEmpty
                                  ? validateAndCreate
                                  : null,
                          child: Text("Create Task"),
                        ),
                      ),
                      if (!(snapshot.data != null && snapshot.data!.isNotEmpty))
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              disabledBackgroundColor: Colors.grey.shade200,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              textStyle: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder:
                                      (context) => ProjectTimelineScreen(
                                        projectId: widget.projectId,
                                      ),
                                ),
                                (Route<dynamic> route) => route.isFirst,
                              );
                            },

                            child: Text("Add Timeline"),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
