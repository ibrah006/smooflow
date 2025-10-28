import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/enums/progress_issue.dart';
import 'package:smooflow/enums/status.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/providers/progress_log_provider.dart';
import 'package:smooflow/providers/project_provider.dart';

class AddProjectProgressScreen extends ConsumerStatefulWidget {
  final String projectId;

  // Read mode means the user is viewing a project progress log with minimal write privileges (update description and or issue/error)
  late final bool isReadMode;

  AddProjectProgressScreen(this.projectId, {Key? key}) : super(key: key) {
    isReadMode = false;
  }

  late final ProgressLog progressLog;

  AddProjectProgressScreen.view({
    Key? key,
    required this.progressLog,
    required this.projectId,
  }) : super(key: key) {
    isReadMode = true;
  }

  @override
  ConsumerState<AddProjectProgressScreen> createState() =>
      _AddProjectProgressScreenState();
}

class _AddProjectProgressScreenState
    extends ConsumerState<AddProjectProgressScreen> {
  Status? selectedStatus;
  ProgressIssue selectedIssue = ProgressIssue.none;

  late final Iterable<Status> statuses;

  DateTime? dueDate;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;

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

  InputDecoration _dateDecoration(
    String hint, {
    Color? hintColor,
    Color? backgroundColor,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: backgroundColor != null,
      fillColor: backgroundColor,
      hintStyle: TextStyle(color: hintColor ?? Colors.grey, letterSpacing: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
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
        borderSide: const BorderSide(color: Colors.black, width: 1.2),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dueDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.isReadMode) {
      selectedStatus = widget.progressLog.status;
      _descriptionController.text = widget.progressLog.description ?? "";
      dueDate = widget.progressLog.dueDate;
      selectedIssue = widget.progressLog.issue ?? ProgressIssue.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectByIdProvider(widget.projectId))!;

    try {
      statuses =
          widget.isReadMode
              ? Status.values
              : Status.values.where(
                (status) => status.name != project.status.toLowerCase(),
              );
    } catch (e) {
      // value already set
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: kToolbarHeight + 15,
          title: Column(
            children: [
              // Title
              const Text(
                "Add Project Progress",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const Text(
                "Track the progress of your project",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Status
                  const Text(
                    "Timeline Status*",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Status>(
                    items:
                        statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              "${status.name[0].toUpperCase()}${status.name.substring(1)}",
                            ),
                          );
                        }).toList(),
                    onChanged:
                        widget.isReadMode
                            ? null
                            : (value) {
                              setState(() => selectedStatus = value);
                            },
                    decoration: _inputDecoration("Select updated status"),
                    icon: Transform.rotate(
                      angle: pi / 2,
                      child: Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    maxLines: 4,
                    controller: _descriptionController,
                    decoration: _inputDecoration("Enter update description"),
                    validator: (value) {
                      if (value != null && value.length > 500) {
                        return "Description can't exceed 500 characters.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Due date optional
                  const Text(
                    "Deadline",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: widget.isReadMode ? null : () => _pickDate(context),
                    child: AbsorbPointer(
                      child: TextField(
                        enabled: !widget.isReadMode,
                        decoration: _dateDecoration(
                          "dd / mm / yyyy",
                          hintColor: Colors.black87,
                          backgroundColor: Colors.white,
                        ),
                        controller: TextEditingController(
                          text:
                              dueDate == null
                                  ? ""
                                  : DateFormat(
                                    "dd / MM / yyyy",
                                  ).format(dueDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Issues
                  const Text(
                    "Issues",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ProgressIssue>(
                    value: selectedIssue,
                    items:
                        ProgressIssue.values.map((issue) {
                          return DropdownMenuItem(
                            value: issue,
                            child: Text(
                              "${issue.name[0].toUpperCase()}${issue.name.substring(1)}",
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() => selectedIssue = value ?? selectedIssue);
                    },
                    decoration: _inputDecoration(""),
                    icon: Transform.rotate(
                      angle: pi / 2,
                      child: Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                  const Spacer(),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: validateAndSave,
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void validateAndSave() async {
    if (widget.isReadMode) {
      // TODO: Update Log if any changes made
      // widget.progressLog.description = _descriptionController.text;
      ref
          .read(progressLogNotifierProvider.notifier)
          .updateProgressLog(
            widget.progressLog,
            updateDescription: _descriptionController.text,
            updatedIssue: selectedIssue,
          );
      Navigator.pop(context);
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;

    if (selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a timeline status.")),
      );
      return;
    }

    if (!isValid) {
      // Some form fields failed validation
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Proceed with save logic
    final payload = {
      "status": selectedStatus!.name,
      "description": _descriptionController.text.trim(),
      "issue": selectedIssue.name,
      "dueDate": dueDate?.toIso8601String(),
    };

    print("Saving progress update: $payload");

    final projectId = ref.read(projectByIdProvider(widget.projectId))!.id;

    final newLog = ProgressLog.create(
      projectId: projectId,
      status: selectedStatus!,
      description: _descriptionController.text,
      dueDate: dueDate,
      issue: selectedIssue,
    );

    try {
      final successCode = await ref
          .watch(progressLogNotifierProvider.notifier)
          .createProgressLog(projectId: projectId, newLog: newLog);
      // call project notifier, to update project status and add progress log
      if (successCode == 201) {
        // Only update status of project if successfully created progress log
        ref
            .watch(projectNotifierProvider.notifier)
            .createProgressLog(log: newLog);
      } else if (successCode == 209) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Previous Timeline already corresponds to the new Timeline requested",
            ),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add Timeline")));
    }
  }
}
