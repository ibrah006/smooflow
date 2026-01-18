import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/data/project_report_details.dart';
import 'package:smooflow/data/project_overall_status.dart';
import 'package:smooflow/enums/period.dart';
import 'package:smooflow/enums/status.dart';
import 'package:smooflow/enums/task_status.dart';
import 'package:smooflow/core/models/progress_log.dart';
import 'package:smooflow/core/models/project.dart';
import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/repositories/organization_repo.dart';
import 'package:smooflow/repositories/project_repo.dart';

class ProjectNotifier extends StateNotifier<List<Project>> {
  ProjectNotifier(this._repo) : super([]) {
    _orgRepo = OrganizationRepo();
  }

  final ProjectRepo _repo;

  // update on this data won't really notify
  double projectsProgressRate = 0;

  // 0 depicts most recent
  Map<int, String> recent = {};

  Project? _selectedProject;

  Project? get selectedProject => _selectedProject;

  set selectedProject(Project? newVal) => _selectedProject = newVal;

  // Active projects cache and count
  List<Project> activeProjects = [];

  final ProjectOverallStatus projectsOverallStatus = ProjectOverallStatus();

  late final OrganizationRepo _orgRepo;

   /// Default empty state containers
  ProjectReportDetails _projectReportDetailsThisWeek =
      ProjectReportDetails(period: Period.thisWeek);

  ProjectReportDetails _projectReportDetailsThisMonth =
      ProjectReportDetails(period: Period.thisMonth);

  ProjectReportDetails _projectReportDetailsThisYear =
      ProjectReportDetails(period: Period.thisYear);

  // load projects
  Future<void> load({
    // Can be found in [OrganizationState].projectsLastAdded
    required DateTime? projectsLastAddedLocal,
  }) async {
    final projectsLastAddedServer = await _orgRepo.getProjectsLastAdded;

    if (projectsLastAddedLocal == null ||
        (projectsLastAddedServer?.isAfter(projectsLastAddedLocal) ?? false)) {
      // Don't need to worry about calling this before loading projects
      // As the progress rate calculation and everything is done in server and returned
      await _getProjectsProgressRate();
      recent = Map<int, String>.from(await _repo.getRecentProjects());

      final projects = await _repo.fetchProjects();
      state = projects;
    }
  }

  @Deprecated("When there are too many projects to be loaded into the memory, this method won't be efficient. As we may or may not have all the active projects in memory. Use [activeProjectsLengthValue] instead")
  int get activeProjectsLength {
    return state
        .where(
          (project) =>
              !(project.status == Status.finished.name ||
                  project.status == Status.cancelled.name),
        )
        .length;
  }

  // create project
  Future<void> create(Project newProject) async {
    final createdProjectId = await _repo.createProject(newProject);

    newProject.initializeId(createdProjectId);
    _pushRecentProjectToTop(createdProjectId);

    // Add to active projects if start date is >= now
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (newProject.estimatedProductionStart?.isAfter(today)?? true) {
      // If not start date, then by default, it is an active project
      activeProjects = [...activeProjects, newProject];
    }

    state = [...state, newProject];
  }

  // This function is a must call, when creating the progresslog along with the progress log notifier
  void createProgressLog({required ProgressLog log}) {
    _pushRecentProjectToTop(log.projectId);

    state =
        state.map((project) {
          if (project.id == log.projectId) {
            return project
              ..status = log.status.name
              ..progressLogs.add(log.id);
          } else {
            return project;
          }
        }).toList();
  }

  Future<void> updateProject(Project updatedProject) async {
    throw UnimplementedError();
  }

  Future<void> updateStatus({
    required String projectId,
    required String newStatus,
  }) async {
    await _repo.updateStatus(projectId, newStatus);
    state =
        state.map((project) {
          if (project.id == projectId) {
            return project..status = newStatus;
          } else {
            return project;
          }
        }).toList();
  }

  // Create Task
  Future<void> createTask({required Task task}) async {
    final taskId = await _repo.createTask(task.projectId, task);

    state =
        state.map((project) {
          if (project.id == task.projectId) {
            task.initializeId(taskId);
            return project..tasks.add(taskId);
          } else {
            return project;
          }
        }).toList();
  }

  // Update task status
  Future<void> markTaskAsComplete({required Task updatedTask}) async {
    final dateCompleted = await _repo.markTaskAsComplete(updatedTask.id);

    // Local changes
    state =
        state.map((project) {
          if (project.id == updatedTask.projectId) {
            return project
              ..tasks.map((tId) {
                if (tId == updatedTask.id) {
                  return updatedTask
                    ..status = TaskStatus.completed
                    ..dateCompleted = dateCompleted;
                } else {
                  return tId;
                }
              })
              ..taskLastModifiedAt = DateTime.now();
          } else {
            return project;
          }
        }).toList();
  }

  Future<void> getProjectProgressRate(String projectId) async {
    final progressRate = await _repo.getProjectProgressRate(projectId);

    state =
        state.map((project) {
          if (project.id == projectId) {
            return project..progressRate = progressRate;
          } else {
            return project;
          }
        }).toList();
  }

  Future<void> _getProjectsProgressRate() async {
    projectsProgressRate = await _repo.getProjectsProgressRate();
  }

  // Fetch projects overall status from server and store locally on this notifier
  Future<void> fetchProjectsOverallStatus() async {
    try {
      final result = await _repo.getProjectsOverallStatus();
      activeProjects = (result['activeProjects'] as List<Project>);
      projectsOverallStatus.activeLength = result['activeLength'] as int;
      projectsOverallStatus.pendingLength = result['pendingLength'] as int;
      projectsOverallStatus.finishedLength = result['finishedLength'] as int;

      state = {...state, ...activeProjects}.toList();
    } catch (e) {
      // ignore errors for now; caller can handle
      print("Error fetching projects overall status: $e");
      rethrow;
    }
  }

  void _pushRecentProjectToTop(String projectId) {
    // If it's already at the top, do nothing
    if (recent.isNotEmpty && recent[0] == projectId) return;

    // Remove from its current position (if it exists)
    recent.removeWhere((i, pId) => pId == projectId);

    // Add it to the top
    final temp = recent.values.toList()..insert(0, projectId);
    recent = Map<int, String>.from(temp.asMap());
  }

  // Project reports section

  /// Fetch report for a given period & update notifier
  Future<void> fetchReport(Period period) async {

    try {
      final report = await _repo.fetchProductionReport(period);

      switch (period) {
        case Period.thisWeek:
          _projectReportDetailsThisWeek = report;
          break;

        case Period.thisMonth:
          _projectReportDetailsThisMonth = report;
          break;

        case Period.thisYear:
          _projectReportDetailsThisYear = report;
          break;
      }
    } finally {
      // loading state = false
    }
  }

  /// Helper accessor used by UI
  ProjectReportDetails _getReportForPeriod(Period period) {
    switch (period) {
      case Period.thisWeek:
        return _projectReportDetailsThisWeek;
      case Period.thisMonth:
        return _projectReportDetailsThisMonth;
      case Period.thisYear:
        return _projectReportDetailsThisYear;
    }
  }

  /// Lazy loading (only reload if empty)
  Future<ProjectReportDetails> ensureReportLoaded(Period period) async {
    final report = _getReportForPeriod(period);

    if (report.projectGroups.isEmpty &&
        report.statusDistribution.isEmpty &&
        report.issues.isEmpty) {
      await fetchReport(period);
    }
    return _getReportForPeriod(period);
  }
}
