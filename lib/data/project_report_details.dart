import 'package:smooflow/enums/period.dart';

class ProjectReportDetails {
  int activeProjects;
  int completedProjects;
  int delayedProjects;
  final Period period;
  Map<String, int> projectGroups;
  Map<String, int> statusDistribution;
  Map<String, int> issues;

  ProjectReportDetails({
    required this.period,
    this.projectGroups = const {},
    this.statusDistribution = const {},
    this.issues = const {},
    this.activeProjects = 0,
    this.completedProjects = 0,
    this.delayedProjects = 0,
  });

  int get getTotalProjects =>
      activeProjects + completedProjects + delayedProjects;

  ProjectReportDetails.sample({Period? period})
      : period = period ?? Period.thisWeek,
        projectGroups = {
          "activeProjects": 0,
          "completedProjects": 0,
          "delayedProjects": 0,
        },
        statusDistribution = {
          "planned": 0,
          "printing": 0,
          "finishing": 0,
          "installing": 0
        },
        issues = {
          "Bugs": 4,
          "Feature Requests": 3,
          "Documentation": 1,
        },
        activeProjects = 0,
        completedProjects = 0,
        delayedProjects = 0;

  factory ProjectReportDetails.fromJson(Map<String, dynamic> json) {
    return ProjectReportDetails(
      activeProjects: (json['activeProjects'] as num?)?.toInt() ?? 0,
      completedProjects: (json['completedProjects'] as num?)?.toInt() ?? 0,
      delayedProjects: (json['delayedProjects'] as num?)?.toInt() ?? 0,
      period: Period.values.byName(json['period']),
      projectGroups: (json['projectGroups'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          value,
        ),
      ),
      statusDistribution:
          Map<String, int>.from(json['statusDistribution'] as Map),
      issues: Map<String, int>.from(json['issues'] as Map),
    );
  }
}