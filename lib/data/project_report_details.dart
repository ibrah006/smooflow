import 'package:smooflow/enums/period.dart';

class ProjectReportDetails {
  final Period period;
  Map<String, int> projectGroups;
  Map<String, int> statusDistribution;
  Map<String, int> issues;

  ProjectReportDetails({
    required this.period,
    this.projectGroups = const {},
    this.statusDistribution = const {},
    this.issues = const {},
  });

  factory ProjectReportDetails.fromJson(Map<String, dynamic> json) {
    return ProjectReportDetails(
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