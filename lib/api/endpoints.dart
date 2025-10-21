class ApiEndpoints {
  static const login = "/login";
  static const relogin = "/users/me/re-login";
  static const register = "/register";
  static const logout = "/logout";

  static const getCurrentUserInfo = "/users/me";
  static const getUsers = "/users";

  // Tasks

  static String createTask(String projectId) => "/projects/$projectId";

  static String getTaskById(int taskId) => "/tasks/$taskId";

  // Endpoint for getting tasks assigned for current user
  static String getUserTasks = "/tasks/me";

  // start and end Task: Work Activity Logs
  static String startTask(int taskId) => "/tasks/$taskId/start";
  static String endUserTask = "/tasks/end";

  // Endpoint for getting active task for current user
  static const getUserActiveTask = "/tasks/me/active";

  // Endpoint for marking task as completed
  static String markTaskAsComplete(int taskId) =>
      "/tasks/$taskId/markCompleted";

  // Attendance logs
  static const getAttendanceLogs = "activity/attendance";

  static const getUserAttendanceLogAnalysis = "/activity/attendance/analysis";

  static const getUserActiveAttendanceLog = "/activity/me/attendance/active";

  static const clockInUser = "/activity/users/me/clock-in";
  static const clockOut = "/activity/users/me/clock-out";

  static const attendanceAnalysis = "/activity/attendance/analysis";

  // WorkActivity logs

  static const getUserActiveWorkActivityLog =
      "/activity/me/work-activity/active";

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
  static const getRecentProjects = "/projects/get-recent";

  // POST this endpoint for log creation and GET for getting logs by project id
  static String projectProgressLogs(String projectId) =>
      "/projects/$projectId/progressLogs";

  static String updateProgressLog(String logId) => "/progressLogs/$logId";

  // Company endpoints
  static const companies = "/companies";

  // Progress log endpoints
  static String getProgressLogById(String logId) => '/progressLogs/$logId';
  static String getProgressLogByProject(String projectId, {DateTime? since}) =>
      '/projects/$projectId/progressLogs${since != null ? '?since=$since' : ''}';

  static String getProjectProgressLogLastModified(String projectId) =>
      '/projects/$projectId/progressLogs/last-modified';

  // Get project finish rate
  static String getProjectProgressRate(String id) =>
      "/projects/$id/progress-rate";

  // Get avg projects finish rate
  static const String getProjectsProgressRate = "/projects/progress-rate";

  static const String createOrg = "/organizations";

  // joining org details passed in body
  static const String joinOrg = createOrg;

  static const String getCurrentOrg = "${createOrg}/current";

  static const String getCurrentOrgMembers = "${createOrg}/members";

  static const String getProjectsLastAdded = "${createOrg}/projects-last-added";

  // invitations
  static const String invitations = "/invitations";
}
