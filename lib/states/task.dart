import 'package:smooflow/core/models/task.dart';
import 'package:smooflow/change_events/task_change_event.dart';

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

  Task? _selectedTask;

  Task? get selectedTask => _selectedTask;

  set selectedTask(Task? value) {
    _selectedTask = value;
  }

  ConnectionStatus _connectionStatus;

  ConnectionStatus get connectionStatus => _connectionStatus;

  set connectionStatus(ConnectionStatus value) {
    _connectionStatus = value;
  }

  TaskState({
      List<Task> tasks = const [],
      bool isLoading = false,
      String? error,
      Task? selectedTask,
      ConnectionStatus connectionStatus = ConnectionStatus.disconnected
  }) : _error = error, _isLoading = isLoading, _tasks = tasks, _selectedTask = selectedTask, _connectionStatus = connectionStatus;

  TaskState insert(int index, Task task) {

    _tasks.insert(index, task);

    return copyWith(
      tasks: _tasks
    );
  }

  TaskState add(Task task) {
    _tasks.add(task);

    return copyWith(
      tasks: _tasks
    );
  }

  TaskState updateTask(Task task) {
    
    _tasks.add(task);

    return copyWith(
      tasks: _tasks
    );
  }
  
  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    Task? newTask,
    Task? selectedTask,
    ConnectionStatus? connectionStatus
  }) {

    final List<Task> ts = tasks?? _tasks;
    // if (tasks != null) {
    //   // Adds the tasks to the existing list of tasks memory without any dusplicates

    //   final temp = _tasks.toSet();
    //   temp.addAll(tasks);
      
    //   ts = temp.toList();
    // } else {
    //   ts = _tasks;
    // }

    if (newTask != null) ts.add(newTask);

    return TaskState(
      tasks: ts,
      isLoading: isLoading ?? _isLoading,
      error: error,
      selectedTask: selectedTask,
      connectionStatus: connectionStatus ?? _connectionStatus
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