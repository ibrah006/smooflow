import 'package:smooflow/core/models/task.dart';

class TaskState {

  List<Task> _tasks;

  List<Task> get tasks => _tasks;

  set tasks(List<Task> value) {
    _tasks = value;
  }
  bool _isLoading;

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
  }
  String? _error;

  String? get error => _error;

  set error(String? value) {
    _error = value;
  }

  TaskState({
      List<Task> tasks = const [],
      bool isLoading = false,
      String? error,
  }) : _error = error, _isLoading = isLoading, _tasks = tasks;
  
  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    Task? newTask
  }) {

    late final List<Task> ts;
    if (tasks != null) {
      // Adds the tasks to the existing list of tasks memory without any dusplicates

      final temp = _tasks.toSet();
      temp.addAll(tasks);
      
      ts = temp.toList();
    } else {
      ts = _tasks;
    }

    if (newTask != null) ts.add(newTask);

    return TaskState(
      tasks: ts,
      isLoading: isLoading ?? _isLoading,
      error: error
    );
  }

  Task? taskById(int taskId) {
    try {
      return _tasks.firstWhere((task)=> task.id == taskId);
    } catch(e) {
      return null;
    }
  }
}