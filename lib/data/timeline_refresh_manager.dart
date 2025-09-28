import 'package:smooflow/constants.dart';

// Add this to project model so the reset functionality can be implemented with interval more efficiently
class TimelineRefreshManager {
  DateTime lastRefresh;

  String? _projectId;

  TimelineRefreshManager() : lastRefresh = DateTime.now();

  // returns t if reset, f if not reset
  bool reset(String projectId) {
    if ((projectId != _projectId) ||
        lastRefresh
            .add(Duration(seconds: timelineRefreshIntervalSecs))
            .isAfter(DateTime.now())) {
      lastRefresh = DateTime.now();
      _projectId = projectId;

      return true;
    }

    return false;
  }
}
