import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/enums/status.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/project_provider.dart';

class ProjectProgressIndicator extends ConsumerStatefulWidget {
  const ProjectProgressIndicator();

  @override
  _ProjectProgressIndicatorState createState() =>
      _ProjectProgressIndicatorState();
}

class _ProjectProgressIndicatorState
    extends ConsumerState<ProjectProgressIndicator> {
  final List<String> steps = ["design", "printing", "finishing", "application"];

  Map<Status, double> get _statusIndicatorValues => Map.fromIterable(
    Status.values,
    key: (element) => element,
    value: (element) => _getIndicatorValue(element),
  );

  // Get the progress indicator value for the specific status
  double _getIndicatorValue(Status status) {
    switch (status) {
      case Status.planning || Status.cancelled:
        return 0;
      case Status.design:
        return 0.10;
      case Status.production:
        return 0.40;
      case Status.finishing:
        return 0.65;
      case Status.application:
        return 0.90;
      case Status.finished:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final textTheme = Theme.of(context).textTheme;

    final project =
        ref.watch(projectNotifierProvider.notifier).selectedProject!;

    final status =
        ref
            .watch(projectNotifierProvider)
            .firstWhere((p) => p.id == project.id)
            .status;

    double indicatorValue;
    try {
      indicatorValue =
          _statusIndicatorValues[Status.values.byName(status.toLowerCase())]!;
    } catch (e) {
      indicatorValue = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress Bar
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.blue.withOpacity(0.2),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Stack(
            children: [
              Container(
                height: 8,
                width: screenWidth,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                height: 8,
                width: (screenWidth - 40) * indicatorValue,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      colorPrimary.withValues(alpha: 0.15),
                      colorPrimary,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 5),

        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final progressStepLabel =
                "${steps[index][0].toUpperCase()}${steps[index].substring(1)}";
            return Expanded(
              child: Text(
                progressStepLabel,
                style: TextStyle(
                  fontWeight:
                      steps.contains(status.toLowerCase()) &&
                              steps.indexOf(status.toLowerCase()) == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 10),

        // Change Status
        // FilledButton(
        //   onPressed: () {},
        //   style: FilledButton.styleFrom(
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(20),
        //     ),
        //   ),
        //   child: Text("Change Status"),
        // ),
      ],
    );
  }
}

class StatusBottomSheet extends ConsumerStatefulWidget {
  final Project project;
  const StatusBottomSheet({Key? key, required this.project}) : super(key: key);

  @override
  ConsumerState<StatusBottomSheet> createState() => _StatusBottomSheetState();
}

class _StatusBottomSheetState extends ConsumerState<StatusBottomSheet> {
  late String _selectedStatus;

  final List<Map<String, dynamic>> statuses = [
    {"label": "Planning", "icon": Icons.event_note, "color": colorPrimary},
    {
      "label": "Design",
      "icon": Icons.monitor_rounded,
      "color": colorPositiveStatus,
    },
    {"label": "Production", "icon": Icons.print, "color": Colors.teal},
    {"label": "Finishing", "icon": Icons.build_circle, "color": colorPending},
    {"label": "Application", "icon": Icons.layers, "color": Colors.indigo},
    {
      "label": "Finished",
      "icon": Icons.check_circle,
      "color": colorPositiveStatus,
    },
    {"label": "Cancelled", "icon": Icons.cancel, "color": colorError},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.project.status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicator
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          Text(
            "Change Project Status",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Status list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: statuses.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final status = statuses[index];
                final isSelected = _selectedStatus == status["label"];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStatus = status["label"];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      spacing: 15,
                      children: [
                        Icon(
                          status["icon"],
                          color:
                              isSelected
                                  ? status["label"] == "Finished"
                                      ? colorPositiveStatus
                                      : status["label"] == "Cancelled"
                                      ? colorError
                                      : colorPrimary
                                  : null,
                        ),
                        Text(
                          status["label"],
                          style: TextStyle(
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? status["label"] == "Finished"
                                        ? colorPositiveStatus
                                        : status["label"] == "Cancelled"
                                        ? colorError
                                        : colorPrimary
                                    : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Confirm button
          SafeArea(
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
                onPressed: () async {
                  if (widget.project.status != _selectedStatus) {
                    await ref
                        .read(projectNotifierProvider.notifier)
                        .updateStatus(
                          projectId: widget.project.id,
                          newStatus: _selectedStatus,
                        );
                  }
                  Navigator.pop(context, _selectedStatus);
                },
                child: const Text("Update Status"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
