import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/providers/progress_log_provider.dart';
import 'package:smooflow/providers/project_provider.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  final String projectId;
  const CreateTaskScreen({super.key, required this.projectId});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _priority;
  String? _assignee;
  DateTime? _dueDate;
  String? _selectedProgressLogId;

  final List<String> priorities = ["Low", "Medium", "High", "Critical"];
  final List<String> assignees = ["Ali Yusuf", "Liam Scott", "Emma Brown"];

  late final Future<List<ProgressLog>> progressLogs;

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

    final newTask = Task.create(
      name: _titleController.text.trim(),
      description: _descController.text.trim(),
      progressLogId: _selectedProgressLogId!,
      // TODO
      assignees: [],
      projectId: widget.projectId,
      // TODO
      // priority: _priority,
      dueDate: _dueDate,
    );

    await ref.read(projectNotifierProvider.notifier).createTask(task: newTask);

    debugPrint("✅ Task Created: $newTask");

    // Navigate back
    Navigator.pop(context);

    // Optionally: clear the form
    _titleController.clear();
    _descController.clear();
    _priority = null;
    _assignee = null;
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
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Task"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                  const Text(
                    "Progress stage*",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder(
                    future: progressLogs,
                    builder: (context, snapshot) {
                      return DropdownButtonFormField<String>(
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
                                  () => _selectedProgressLogId = val,
                                ),
                        decoration: _inputDecoration(""),
                        icon: Transform.rotate(
                          angle: pi / 2,
                          child: Icon(Icons.chevron_right_rounded),
                        ),
                      );
                    },
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

                  // Priority Dropdown
                  const Text(
                    "Priority",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _priority,
                    items:
                        priorities
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _priority = val),
                    decoration: _inputDecoration(""),
                    icon: Transform.rotate(
                      angle: pi / 2,
                      child: Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Assignee Dropdown
                  const Text(
                    "Project Head",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _assignee,
                    items:
                        assignees
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _priority = val),
                    decoration: _inputDecoration(""),
                    icon: Transform.rotate(
                      angle: pi / 2,
                      child: Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.all(18),
                  textStyle: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: validateAndCreate,
                child: Text("Create Task"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
