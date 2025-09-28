import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooflow/enums/status.dart';
import 'package:smooflow/models/progress_log.dart';
import 'package:smooflow/models/project.dart';
import 'package:smooflow/models/task.dart';
import 'package:smooflow/repositories/project_repo.dart';

class ProjectNotifier extends StateNotifier<List<Project>> {
  ProjectNotifier(this._repo) : super([]);

  final ProjectRepo _repo;

  // update on this data won't really notify
  double projectsProgressRate = 0;

  // load projects
  Future<void> load() async {
    // Don't need to worry about calling this before loading projects
    // As the progress rate calculation and everything is done in server and returned
    await _getProjectsProgressRate();
    final projects = await _repo.fetchProjects();
    state = projects;
  }

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
    await _repo.createProject(newProject);
    state = [...state, newProject];
  }

  // create progress log
  Future<void> createProgressLog({
    required String projectId,
    required ProgressLog log,
  }) async {
    await _repo.createProgressLog(projectId, log);

    state =
        state.map((project) {
          if (project.id == projectId) {
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
            return project..tasks.add(task);
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
              ..tasks.map((t) {
                if (t.id == updatedTask.id) {
                  return updatedTask
                    ..status = "completed"
                    ..dateCompleted = dateCompleted;
                } else {
                  return t;
                }
              });
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
}
