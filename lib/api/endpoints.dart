class ApiEndpoints {
  static const login = "/login";

  static const getCurrentUserInfo = "/users/me";

  // Tasks
  static const getTasks = "/tasks";

  static String createTask(int projectId) => "/projects/$projectId";

  // Endpoint for getting tasks assigned for current user
  static String getUserTasks = "/tasks/me";

  // start and end Task: Work Activity Logs
  static String startTask(int taskId) => "/tasks/$taskId/start";
  static String endUserTask = "/tasks/end";

  // Endpoint for getting active task for current user
  static const getUserActiveTask = "/tasks/me/active";

  // Attendance logs
  static const getAttendanceLogs = "activity/attendance";

  static const getUserAttendanceLogAnalysis = "/activity/attendance/analysis";

  static const getUserActiveAttendanceLog = "/activity/me/attendance/active";

  static const clockInUser = "/activity/users/me/clock-in";
  static const clockOut = "/activity/users/me/clock-out";

  static const attendanceAnalysis = "/activity/attendance/analysis";

  // WorkActivity logs

  static const getUserActiveWorkActivityLog =
      "/activity/me/workActivity/active";

  // Layoff logs
  static const getLayoffLogs = "/activity/layoff";

  static const startLayoff = "/activity/me/layoff/start";
  static const endLayoff = "/activity/me/layoff/end";

  // Self Productivity Summary
  static const getUserPerformance = "/analytics/me/staff-productivity-summary";
  static const getUsersPerformance = "/analytics/staff-productivity-summary";

  // Material log endpoints
  static const materialLogs = "/materialLogs";
  static String getMaterialLogById(int logId) => "/materialLogs/$logId";

  // Projects endpoints
  static const projects = "/projects";
  static String updateProjectStatus(String projectId) => "/projects/$projectId";

  // POST this endpoint for log creation and GET for getting logs by project id
  static String projectProgressLogs(String projectId) =>
      "/projects/$projectId/progressLogs";

  // Company endpoints
  static const companies = "/companies";
}
