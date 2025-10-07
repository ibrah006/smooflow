import 'package:flutter/material.dart';
import 'package:smooflow/components/border_button.dart';
import 'package:smooflow/components/custom_card.dart';
import 'package:smooflow/constants.dart';
import 'package:smooflow/enums/status.dart';
import 'package:smooflow/extensions/date_time_format.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/screens/add_project.dart';
import 'package:smooflow/screens/create_task_screen.dart';

class ProjectCardV2 extends StatelessWidget {
  final Project project;

  ProjectCardV2(this.project, {super.key});

  Widget tagCard(context, {required String labelText, required Color color}) {
    return CustomCard(
      borderRadius: 11,
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      hasShadow: false,
      color: color.withValues(alpha: .05),
      child: Text(
        labelText,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final textButtonStyle = Theme.of(context).textButtonTheme.style!.copyWith(
      foregroundColor: WidgetStatePropertyAll(Colors.black),
      overlayColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: .04)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: WidgetStatePropertyAll(Size.zero),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );

    // Project Details
    final title = project.name;
    final status =
        "${project.status[0].toUpperCase()}${project.status.substring(1)}";
    // final priority = project.pro;
    final dueDate = project.dueDate?.formatDisplay;

    double indicatorValue;
    try {
      indicatorValue =
          _statusIndicatorValues[Status.values.byName(status.toLowerCase())]!;
    } catch (e) {
      indicatorValue = 0;
    }

    return BorderButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddProjectScreen.view(projectId: project.id),
          ),
        );
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: textTheme.titleMedium!.copyWith(color: Colors.black),
              ),
              // Project status
              tagCard(context, labelText: status, color: Color(0xFF3b72e3)),
            ],
          ),
          SizedBox(height: 13),
          Row(
            children: [
              CircleAvatar(radius: 15, child: Icon(Icons.person_rounded)),
              SizedBox(width: 15),
              // Text(assigneeCount, style: textTheme.bodyLarge),
              Expanded(child: SizedBox()),
              // Project Priority
              tagCard(
                context,
                labelText: ["Low", "Medium", "High"][project.priority],
                color:
                    [
                      colorPositiveStatus,
                      colorPending,
                      Colors.red.shade900,
                    ][project.priority],
              ),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: indicatorValue,
            borderRadius: BorderRadius.circular(20),
            minHeight: 10,
            backgroundColor: colorPrimary.withValues(alpha: 0.07),
          ),
          SizedBox(height: 13),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Deadline: $dueDate"),
          ),
          SizedBox(height: 5),
          TextButtonTheme(
            data: TextButtonThemeData(style: textButtonStyle),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  CreateTaskScreen(projectId: project.id),
                        ),
                      );
                    },
                    icon: Icon(Icons.add_rounded),
                    label: Text("Add Task"),
                  ),
                ),
                // Vertical Divider
                Container(color: Color(0xFFeef5fc), width: 2, height: 18),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.bar_chart_rounded),
                    label: Text("View Summary"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getProgressDisplay(double taskProgress) {
    try {
      return "${(taskProgress * 100).toInt()}%";
    } catch (e) {
      return "0%";
    }
  }

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
}
