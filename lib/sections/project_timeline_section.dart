import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/providers/project_provider.dart';

class ProjectTimelineMilestonesSection extends ConsumerStatefulWidget {
  late final bool isReadMode;

  ProjectTimelineMilestonesSection({Key? key}) : super(key: key) {
    isReadMode = false;
  }

  ProjectTimelineMilestonesSection.view({Key? key}) : super(key: key) {
    isReadMode = true;
  }

  @override
  ConsumerState<ProjectTimelineMilestonesSection> createState() =>
      ProjectTimelineMilestonesSectionState();
}

class ProjectTimelineMilestonesSectionState
    extends ConsumerState<ProjectTimelineMilestonesSection> {
  static final List<Map<String, dynamic>> _milestones = [
    {
      "title": "Initial Concept Review",
      "due": "Due: 3 days from start",
      "color": colorPrimary,
    },
    {
      "title": "Client Approval",
      "due": "Due: 7 days from start",
      "color": colorPending,
    },
  ];

  final ProjectTimelineMilestonesData data = ProjectTimelineMilestonesData(
    // TODO: change this to initial value when milestones fundtionality is added
    milestones: _milestones,
  );

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          data.startDate = picked;
        } else {
          data.deadline = picked;
        }
      });
    }
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

  Widget _milestoneItem(Map<String, dynamic> milestone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundDarker,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: milestone["color"],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  milestone["due"],
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13.5),
                ),
              ],
            ),
          ),
          const Icon(Icons.drag_handle, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _numberBox(String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: colorBorderDark),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "0",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    late final Project project;
    try {
      project = ref.watch(currentProjectProvider);
    } catch (e) {
      // Project "Add" Mode
    }

    return Container(
      color: backgroundDarker,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            "Timeline & Milestones",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            "Set project dates and critical milestones",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Start Date & Deadline
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Start Date*",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    if (widget.isReadMode)
                      Text(
                        project.estimatedProductionStart?.formatDisplay ??
                            "N/A",
                      )
                    else
                      GestureDetector(
                        onTap: () => _pickDate(context, true),
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: _dateDecoration(
                              "dd / mm / yyyy",
                              hintColor: Colors.black87,
                              backgroundColor: Colors.white,
                            ),
                            controller: TextEditingController(
                              text:
                                  data.startDate == null
                                      ? ""
                                      : DateFormat(
                                        "dd / MM / yyyy",
                                      ).format(data.startDate!),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Deadline*",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    if (widget.isReadMode)
                      Text(project.estimatedSiteFixing?.formatDisplay ?? "N/A")
                    else
                      GestureDetector(
                        onTap: () => _pickDate(context, false),
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: _dateDecoration(
                              "dd / mm / yyyy",
                              hintColor: Colors.black87,
                              backgroundColor: Colors.white,
                            ),
                            controller: TextEditingController(
                              text:
                                  data.deadline == null
                                      ? ""
                                      : DateFormat(
                                        "dd / MM / yyyy",
                                      ).format(data.deadline!),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Key Milestones
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: colorBorderDark),
          //     borderRadius: BorderRadius.circular(12),
          //     color: Colors.white,
          //   ),
          //   child: Column(
          //     children: [
          //       Row(
          //         children: [
          //           const Expanded(
          //             child: Text(
          //               "Key Milestones",
          //               style: TextStyle(
          //                 fontWeight: FontWeight.w600,
          //                 fontSize: 15,
          //               ),
          //             ),
          //           ),
          //           TextButton(
          //             onPressed: () {},
          //             child: Row(
          //               children: [
          //                 Icon(Icons.add_rounded, size: 22),
          //                 const Text(
          //                   "Add Milestone",
          //                   style: TextStyle(
          //                     fontWeight: FontWeight.bold,
          //                     fontSize: 15,
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 12),
          //       ...data.milestones.map(_milestoneItem).toList(),
          //     ],
          //   ),
          // ),
          const SizedBox(height: 24),

          // Estimated Duration
          const Text(
            "Estimated Duration",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _numberBox("Days"),
              const SizedBox(width: 12),
              _numberBox("Hours"),
              const SizedBox(width: 12),
              _numberBox("Minutes"),
            ],
          ),
        ],
      ),
    );
  }
}

class ProjectTimelineMilestonesData {
  DateTime? _startDate;

  // Getter
  DateTime? get startDate => _startDate;

  // Setter
  set startDate(DateTime? value) {
    print("we're setting the value of start date: ${value}");
    _startDate = value;
  }

  DateTime? deadline;

  // Optional: duration fields if they are editable
  // Unimplemented
  int estimatedDays = 0;
  int estimatedHours = 0;
  int estimatedMinutes = 0;

  final List<Map<String, dynamic>> milestones;

  ProjectTimelineMilestonesData({required this.milestones});
}
