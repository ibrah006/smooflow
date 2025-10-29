import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:smooflow/components/project_progress_indicator.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/enums/priorities.dart';
import 'package:smooflow/models/company.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/organization_provider.dart';
import 'package:smooflow/providers/project_provider.dart';
import 'package:smooflow/screens/create_client_screen.dart';
import 'package:smooflow/screens/create_task_screen.dart';
import 'package:smooflow/screens/google_sheet_viewer.dart';
import 'package:smooflow/screens/project_timeline_screen.dart';
import 'package:smooflow/screens/stock_entry_screen.dart';
import 'package:smooflow/screens/tasks_screen.dart';
import 'package:smooflow/sections/project_timeline_section.dart';
import 'package:smooflow/repositories/company_repo.dart';

const DEFAULT_PRIORITY = PriorityLevel.low;

// Can screen to create project or view project (project details)
class AddProjectScreen extends ConsumerStatefulWidget {
  // Add project screen
  AddProjectScreen({Key? key}) : super(key: key) {
    isReadMode = false;
  }

  late final String projectId;

  late final bool isReadMode;

  // Open Project screen in read mode (ie., just view project info)
  // Project details screen
  AddProjectScreen.view({Key? key, required this.projectId}) {
    isReadMode = true;
  }

  @override
  ConsumerState<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends ConsumerState<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final GlobalKey<ProjectTimelineMilestonesSectionState>
  projectTimelineMilestoneSectionKey = GlobalKey();

  // bool _isFormDisabled = false;

  // not for .view mode, only during project creation
  bool _isLoading = false;

  late final TextEditingController _projectNameController;

  late final TextEditingController _projectDescriptionController;

  Company? selectedClient;
  String? selectedProjectType = "Digital Advertising";
  late PriorityLevel selectedPriority;

  final List<String> projectTypes = [
    "Digital Advertising",
    "Web Development",
    "Mobile App",
    "Branding",
  ];

  bool _showErrorSnackbar = false;
  bool get showErrorSnackBar => _showErrorSnackbar;
  set showErrorSnackBar(bool newValue) {
    setState(() {
      _showErrorSnackbar = newValue;
    });
    if (_showErrorSnackbar) {
      Future.delayed(Duration(seconds: 4)).then((value) {
        setState(() {
          _showErrorSnackbar = false;
        });
      });
    }
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
    // TODO: implement initState
    super.initState();

    final project =
        widget.isReadMode
            ? ref.read(projectByIdProvider(widget.projectId))
            : null;

    _projectNameController = TextEditingController(
      text: widget.isReadMode ? project!.name : '',
    );
    _projectDescriptionController = TextEditingController(
      text: widget.isReadMode ? project!.description : '',
    );
  }

  _projectScope({Project? project, required Widget content}) {
    if (widget.isReadMode && project == null) {
      throw "Forbidden use of _projectScope function, no (selected) project instance passed into the function to view project in just view mode (ie., Project details screen)";
    }

    if (widget.isReadMode) {
      ref.watch(projectNotifierProvider.notifier).selectedProject = project!;
    }
    return content;
  }

  gotoCreateClientScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => CreateClientScreen()),
      (Route<dynamic> route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Company> clients = [...CompanyRepo.companies, Company.sample()];

    final textTheme = Theme.of(context).textTheme;

    late final Project project;
    try {
      project = ref.watch(projectByIdProvider(widget.projectId))!;
    } catch (e) {
      // Project "Add" Mode
    }

    // set initial priority level, if any
    try {
      selectedPriority =
          widget.isReadMode
              ? PriorityLevel.values[project.priority]
              : DEFAULT_PRIORITY;
    } catch (e) {
      // value already set
    }

    // Set initial status if any
    late final String status;
    if (widget.isReadMode) {
      status =
          ref
              .watch(projectNotifierProvider)
              .firstWhere((p) => p.id == project.id)
              .status;

      try {
        project.progressRate;
      } catch (e) {
        ref
            .read(projectNotifierProvider.notifier)
            .getProjectProgressRate(widget.projectId);
      }
    }

    return _projectScope(
      project: widget.isReadMode ? project : null,
      content: Scaffold(
        appBar:
            _isLoading
                ? null
                : AppBar(
                  automaticallyImplyLeading: true,
                  title: Column(
                    children: [
                      Text(
                        widget.isReadMode
                            ? project.name
                            : "Create a New Project",
                      ),
                      Text(
                        widget.isReadMode
                            ? "Ongoing Project"
                            : "Create advertising & printing project",
                        style: textTheme.bodyMedium!.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    if (widget.isReadMode)
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert),
                        itemBuilder: (context) {
                          HapticFeedback.lightImpact();
                          return List.generate(
                            4,
                            (index) => PopupMenuItem(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            [
                                              ProjectTimelineScreen(
                                                projectId: project.id,
                                              ),
                                              CreateTaskScreen(
                                                projectId: project.id,
                                              ),
                                              TasksScreen(
                                                projectId: widget.projectId,
                                              ),
                                              StockEntryScreen.stockin(),
                                            ][index],
                                  ),
                                );
                              },
                              child: Text(
                                [
                                  "View Timelines",
                                  "Create Task",
                                  "View Tasks",
                                  "Add Material Stock Entry",
                                ][index],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      ListView(
                        physics: ClampingScrollPhysics(),
                        children: [
                          const SizedBox(height: 16),

                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Project Information",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (widget.isReadMode)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 5,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorPending.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: textTheme.labelMedium!
                                              .copyWith(color: colorPending),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: widget.isReadMode ? 14 : 4),
                                // Project Progress Rate
                                if (widget.isReadMode)
                                  ...progressRateSection(project),
                                if (!widget.isReadMode) ...[
                                  const Text(
                                    "Enter basic project details and specifications",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Project Name
                                  const Text(
                                    "Project Name*",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _projectNameController,
                                    decoration: _inputDecoration(
                                      "Enter project name",
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "Project name is required";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                const SizedBox(height: 10),

                                // Client Company
                                Row(
                                  spacing: 5,
                                  children: [
                                    Icon(Icons.apartment_rounded),
                                    const Text(
                                      "Client Company*",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (widget.isReadMode)
                                  Text(
                                    project.client.name,
                                    style: textTheme.titleLarge,
                                  )
                                else
                                  Row(
                                    spacing: 10,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: DropdownButtonFormField<Company>(
                                          value: selectedClient,
                                          hint: const Text(
                                            "Select or add client",
                                          ),
                                          decoration: _inputDecoration(""),
                                          disabledHint: Text(
                                            "No Clients found",
                                            style: textTheme.titleMedium!
                                                .copyWith(
                                                  color: Colors.grey.shade400,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                          ),
                                          icon: Transform.rotate(
                                            angle: pi / 2,
                                            child: Icon(
                                              Icons.chevron_right_rounded,
                                            ),
                                          ),
                                          validator:
                                              (value) =>
                                                  value == null
                                                      ? "Client is required"
                                                      : null,
                                          items:
                                              clients
                                                  .map(
                                                    (
                                                      client,
                                                    ) => DropdownMenuItem(
                                                      value: client,
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            client.isSample
                                                                ? "Add New Client"
                                                                : client.name,
                                                            style:
                                                                !client.isSample
                                                                    ? null
                                                                    : textTheme
                                                                        .titleMedium!
                                                                        .copyWith(
                                                                          color:
                                                                              colorPrimary,
                                                                        ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          onChanged: (value) {
                                            if (value?.isSample == true) {
                                              gotoCreateClientScreen();
                                              return;
                                            }
                                            setState(
                                              () => selectedClient = value,
                                            );
                                          },
                                        ),
                                      ),
                                      if (clients.isEmpty)
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 13,
                                              horizontal: 10,
                                            ),
                                          ),
                                          onPressed: gotoCreateClientScreen,
                                          child: Text(
                                            "Add Client",
                                            style: textTheme.titleMedium!
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                const SizedBox(height: 20),

                                // Project Type & Priority
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            spacing: 5,
                                            children: [
                                              Icon(Icons.type_specimen_rounded),
                                              const Text(
                                                "Project Type",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<String>(
                                            value: selectedProjectType,
                                            decoration: _inputDecoration(
                                              "",
                                              backgroundColor: colorBorderDark,
                                            ),
                                            icon: Transform.rotate(
                                              angle: pi / 2,
                                              child: Icon(
                                                Icons.chevron_right_rounded,
                                              ),
                                            ),
                                            // validator:
                                            //     (value) =>
                                            //         value == null
                                            //             ? "Project type is required"
                                            //             : null,
                                            items:
                                                projectTypes
                                                    .map(
                                                      (type) =>
                                                          DropdownMenuItem(
                                                            value: type,
                                                            child: Text(type),
                                                          ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                (value) => setState(
                                                  () =>
                                                      selectedProjectType =
                                                          value,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            spacing: 5,
                                            children: [
                                              Icon(
                                                [
                                                  Icons.low_priority_rounded,
                                                  Icons.warning_amber_rounded,
                                                  Icons.priority_high,
                                                ][PriorityLevel.values.indexOf(
                                                  selectedPriority,
                                                )],
                                              ),
                                              const Text(
                                                "Priority Level*",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<
                                            PriorityLevel
                                          >(
                                            value: selectedPriority,
                                            decoration: _inputDecoration(""),
                                            validator:
                                                (value) =>
                                                    value == null
                                                        ? "Priority level is required"
                                                        : null,
                                            icon: Transform.rotate(
                                              angle: pi / 2,
                                              child: Icon(
                                                Icons.chevron_right_rounded,
                                              ),
                                            ),
                                            items:
                                                PriorityLevel.values
                                                    .map(
                                                      (
                                                        priority,
                                                      ) => DropdownMenuItem(
                                                        value: priority,
                                                        child: Text(
                                                          "${priority.name[0].toUpperCase()}${priority.name.substring(1)}",
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                (value) => setState(
                                                  () =>
                                                      selectedPriority = value!,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Project Description
                                const Text(
                                  "Project Description",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 6),
                                if (widget.isReadMode)
                                  Text(
                                    project.description ?? "N/A",
                                    maxLines: 4,
                                    style: textTheme.bodyMedium!.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                                  )
                                else
                                  TextField(
                                    controller: _projectDescriptionController,
                                    enabled: !widget.isReadMode,
                                    maxLines: 4,
                                    decoration: _inputDecoration(
                                      "Describe project objectives, requirements, and key deliverables...",
                                    ),
                                  ),

                                // Project timeline / progress indicator
                                if (widget.isReadMode) ...[
                                  SizedBox(height: 25),
                                  ProjectProgressIndicator(),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Timelines/Milestones section
                          if (widget.isReadMode)
                            ProjectTimelineMilestonesSection.view(
                              key: projectTimelineMilestoneSectionKey,
                            )
                          else
                            ProjectTimelineMilestonesSection(
                              key: projectTimelineMilestoneSectionKey,
                            ),
                        ],
                      ),

                      // Custom error Snackbar
                      if (showErrorSnackBar)
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorErrorBackground,
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
                              Icon(Icons.error_outline, color: colorError),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Failed to Create Project",
                                    style: textTheme.titleMedium!.copyWith(
                                      color: colorError,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Try again after filling all the required inputs",
                                    style: textTheme.bodySmall,
                                  ),
                                  SizedBox(height: 17),
                                  GestureDetector(
                                    onTap: () {
                                      showErrorSnackBar = false;
                                    },
                                    child: Text(
                                      "Try again",
                                      style: textTheme.bodySmall!.copyWith(
                                        decoration: TextDecoration.underline,
                                        decorationColor: colorError,
                                        color: colorError,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Actions
                // Save draft and Create project
                if (!widget.isReadMode)
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
                      spacing: 11,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.25,
                              ),
                            ),
                            child: Text("Save as Draft"),
                          ),
                        ),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.all(18),
                              textStyle: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: validateAndCreate,
                            child: Text("Create Project"),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> progressRateSection(Project project) {
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

  void validateAndCreate() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    final isTimelineValid = validateTimelineSection();

    if (!isValid || !isTimelineValid) {
      // Show error UI
      showErrorSnackBar = true;
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Optional: Unfocus keyboard
    FocusScope.of(context).unfocus();

    // Proceed with form submission

    final timelineData = projectTimelineMilestoneSectionKey.currentState!.data;

    try {
      await ref
          .read(projectNotifierProvider.notifier)
          .create(
            Project.create(
              name: _projectNameController.text,
              description: _projectDescriptionController.text,
              // TODO: let user assign incharge men when creating project
              assignedManagers: [],
              client: selectedClient!,
              priority: PriorityLevel.values.indexOf(selectedPriority),
              dueDate: timelineData.deadline,
              estimatedProductionStart: timelineData.startDate,
            ),
          );

      // Notify organization state about this adding of a project to update projectsLastAdded
      ref.read(organizationNotifierProvider.notifier).projectAdded();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to Create Project")));
      return;
    }

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context);
  }

  bool validateTimelineSection() {
    String? error;

    final timelineData = projectTimelineMilestoneSectionKey.currentState!.data;

    final startDate = timelineData.startDate;
    final deadline = timelineData.deadline;

    if (startDate == null) {
      error = "Start date is required.";
    } else if (deadline == null) {
      error = "Deadline is required.";
    } else if (deadline.isBefore(startDate)) {
      error = "Deadline must be after the start date.";
    }

    if (error != null) {
      // Show error using Snackbar, Dialog, etc.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return false;
    }

    return true;
  }
}
